import prisma from './prisma';
import { sendAF, sendADJ, sendSingular } from '../controllers/games.controller';

type SchedEntry =
  | { level: number; interval: number; wait_delta?: number }
  | { token: string; interval: number; wait_delta?: number }
  | [string, string]; // legacy: [id, name]

interface SchedGroupRow {
  id: string;
  userId: string;
  platform: string;
  gameId: string | null;
  gameName: string;
  gamePkg: string | null;
  gameKey: string | null;
  eventsOrder: string;
  intervalMinutes: number;
  gaid: string;
  afUid: string | null;
  status: string;
}

const activeTasks = new Map<string, NodeJS.Timeout>();

function sleep(ms: number, groupId: string): Promise<boolean> {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      activeTasks.delete(groupId);
      resolve(true);
    }, ms);
    activeTasks.set(groupId, timer);
  });
}

function cancelTask(groupId: string) {
  const timer = activeTasks.get(groupId);
  if (timer) {
    clearTimeout(timer);
    activeTasks.delete(groupId);
  }
}

export function stopSchedTask(groupId: string) {
  cancelTask(groupId);
}

async function isGroupActive(groupId: string): Promise<boolean> {
  const g = await prisma.schedGroup.findUnique({
    where: { id: groupId },
    select: { status: true },
  });
  return g?.status === 'active';
}

async function sendOneEvent(
  platform: string,
  gameKey: string | null,
  gamePkg: string | null,
  gaid: string,
  afUid: string,
  entry: SchedEntry,
  isCustom: boolean
): Promise<{ status: number; body: string }> {
  try {
    if (isCustom) {
      if ('token' in entry) {
        const tok = entry.token;
        if (platform === 'adj' && gameKey) {
          return await sendADJ(gameKey, tok, gaid);
        }
        return { status: 0, body: 'token mode requires adj platform' };
      }
      // level mode
      const levelNum = (entry as { level: number }).level;
      if (platform === 'adj' && gameKey) {
        const ev = await prisma.gameEvent.findFirst({
          where: { game: { appToken: gameKey } },
          orderBy: { eventName: 'asc' },
          select: { eventToken: true },
        });
        if (ev?.eventToken) {
          return await sendADJ(gameKey, ev.eventToken, gaid);
        }
        return { status: 0, body: 'no event token found' };
      }
      if (platform === 'singular' && gamePkg && gameKey) {
        const ev = await prisma.gameEvent.findFirst({
          where: { game: { appKey: gameKey } },
          select: { eventName: true },
        });
        const baseName = ev?.eventName ?? 'level_1';
        const customName = baseName.replace(/\d+/, String(levelNum)) || `level_${levelNum}`;
        return await sendSingular(customName, gaid, afUid, gamePkg, gameKey);
      }
      // af
      if (platform === 'af' && gamePkg && gameKey) {
        const ev = await prisma.gameEvent.findFirst({
          where: { game: { devKey: gameKey }, OR: [{ eventName: { contains: 'level' } }, { eventName: { contains: 'kingdom' } }] },
          select: { eventName: true },
        });
        const baseName = ev?.eventName ?? 'af_level_1_achieved';
        const customName = /\d/.test(baseName)
          ? baseName.replace(/\d+/, String(levelNum))
          : `${baseName}_${levelNum}`;
        return await sendAF(gamePkg, gameKey, gaid, afUid, customName);
      }
      return { status: 0, body: 'missing game config' };
    }

    // legacy mode: entry = [id, name]
    const [, eventName] = entry as [string, string];
    if (platform === 'af' && gamePkg && gameKey) {
      return await sendAF(gamePkg, gameKey, gaid, afUid, eventName);
    }
    if (platform === 'singular' && gamePkg && gameKey) {
      return await sendSingular(eventName, gaid, afUid, gamePkg, gameKey);
    }
    if (platform === 'adj' && gameKey) {
      const ev = await prisma.gameEvent.findFirst({
        where: { eventName },
        select: { eventToken: true },
      });
      if (ev?.eventToken) return await sendADJ(gameKey, ev.eventToken, gaid);
    }
    return { status: 0, body: 'unsupported platform' };
  } catch (err: any) {
    return { status: 0, body: String(err?.message ?? err) };
  }
}

export async function runSchedGroupLoop(groupId: string): Promise<void> {
  const g = await prisma.schedGroup.findUnique({ where: { id: groupId } });
  if (!g || g.status !== 'active') {
    cancelTask(groupId);
    return;
  }

  let events: SchedEntry[];
  try {
    events = JSON.parse(g.eventsOrder) as SchedEntry[];
  } catch {
    cancelTask(groupId);
    return;
  }

  const isCustom =
    events.length > 0 &&
    typeof events[0] === 'object' &&
    !Array.isArray(events[0]) &&
    ('level' in (events[0] as object) || 'token' in (events[0] as object));

  if (isCustom) {
    events.sort((a, b) => {
      const ia = (a as { interval: number }).interval;
      const ib = (b as { interval: number }).interval;
      return ia - ib;
    });
    let prev = 0;
    for (const e of events as (typeof events[number] & { wait_delta?: number })[]) {
      const cur = (e as { interval: number }).interval;
      (e as { wait_delta: number }).wait_delta = cur - prev;
      prev = cur;
    }
  }

  const intervalSec = g.intervalMinutes * 60;

  for (let i = 0; i < events.length; i++) {
    if (!(await isGroupActive(groupId))) {
      cancelTask(groupId);
      return;
    }

    let waitMin = 0;
    if (isCustom) {
      const e = events[i] as { wait_delta?: number; interval: number };
      waitMin = e.wait_delta ?? e.interval;
    } else if (i > 0 && intervalSec > 0) {
      waitMin = g.intervalMinutes;
    }

    if (waitMin > 0) {
      const ok = await sleep(waitMin * 60 * 1000, groupId);
      if (!ok || !(await isGroupActive(groupId))) {
        cancelTask(groupId);
        return;
      }
    } else if (i > 0 && !isCustom) {
      await sleep(500, groupId);
    }

    const entry = events[i];
    const label = isCustom
      ? ('token' in (entry as object)
          ? `TOKEN:${(entry as { token: string }).token}`
          : `LV${(entry as { level: number }).level}`)
      : (entry as [string, string])[1];

    const { status } = await sendOneEvent(
      g.platform,
      g.gameKey,
      g.gamePkg,
      g.gaid,
      g.afUid ?? '',
      entry,
      isCustom
    );

    await prisma.schedGroup.update({
      where: { id: groupId },
      data: { nextRun: new Date() },
    }).catch(() => {});

    console.log(`[sched:${groupId}] ${g.gameName} | ${label} | HTTP ${status}`);
  }

  await prisma.schedGroup.update({
    where: { id: groupId },
    data: { status: 'completed' },
  }).catch(() => {});
  cancelTask(groupId);
}

export function startSchedTask(groupId: string): void {
  if (activeTasks.has(groupId)) return;
  runSchedGroupLoop(groupId).catch((err) => {
    console.error(`[sched] group ${groupId} failed:`, err);
    activeTasks.delete(groupId);
  });
}

export async function resumeActiveGroups(): Promise<void> {
  try {
    const groups = await prisma.schedGroup.findMany({
      where: { status: 'active' },
      select: { id: true },
    });
    for (const g of groups) {
      startSchedTask(g.id);
    }
    if (groups.length > 0) {
      console.log(`✅ Resumed ${groups.length} active scheduling group(s)`);
    }
  } catch (err) {
    console.error('[sched] resume error:', err);
  }
}
