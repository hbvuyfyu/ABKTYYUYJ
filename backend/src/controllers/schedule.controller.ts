import { Response } from 'express';
import prisma from '../utils/prisma';
import { withDb } from '../utils/prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import { startSchedTask, stopSchedTask } from '../utils/scheduler';

interface CustomEntry {
  level?: number;
  token?: string;
  interval: number; // minutes, absolute from start
}

function parseLevelTime(s: string): number {
  const v = s.trim().toLowerCase();
  if (['0', '0h', '0m', '0d', '0s'].includes(v)) return 0;
  if (v.endsWith('d')) return parseFloat(v.slice(0, -1)) * 1440;
  if (v.endsWith('h')) return parseFloat(v.slice(0, -1)) * 60;
  if (v.endsWith('m')) return parseFloat(v.slice(0, -1));
  if (v.endsWith('s')) return parseFloat(v.slice(0, -1)) / 60;
  return parseFloat(v);
}

// POST /api/schedule/create
export async function createSchedGroup(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const {
      platform, gameName, gamePkg, gameKey, gameId,
      eventsOrder, intervalMinutes, gaid, afUid,
    } = req.body as {
      platform: string;
      gameName: string;
      gamePkg?: string;
      gameKey?: string;
      gameId?: string;
      eventsOrder: CustomEntry[] | [string, string][];
      intervalMinutes: number;
      gaid: string;
      afUid?: string;
    };

    if (!platform || !gameName || !eventsOrder || !gaid) {
      res.status(400).json({ success: false, message: 'بيانات ناقصة' });
      return;
    }
    if (!Array.isArray(eventsOrder) || eventsOrder.length === 0) {
      res.status(400).json({ success: false, message: 'يجب إدخال حدث واحد على الأقل' });
      return;
    }

    const group = await withDb(() =>
      prisma.schedGroup.create({
        data: {
          userId,
          platform,
          gameId: gameId ?? null,
          gameName,
          gamePkg: gamePkg ?? null,
          gameKey: gameKey ?? null,
          eventsOrder: JSON.stringify(eventsOrder),
          intervalMinutes: Number(intervalMinutes) ?? 0,
          gaid,
          afUid: afUid ?? null,
          status: 'active',
          nextRun: new Date(),
        },
      })
    );

    startSchedTask(group.id);

    res.json({
      success: true,
      groupId: group.id,
      message: 'تم تفعيل الجدولة',
    });
  } catch (err: any) {
    console.error('[sched:create] error:', err);
    res.status(500).json({ success: false, message: 'خطأ داخلي' });
  }
}

// GET /api/schedule/list
export async function listSchedGroups(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const groups = await withDb(() =>
      prisma.schedGroup.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          platform: true,
          gameName: true,
          eventsOrder: true,
          intervalMinutes: true,
          gaid: true,
          afUid: true,
          status: true,
          nextRun: true,
          createdAt: true,
        },
      })
    );

    res.json({ success: true, groups });
  } catch (err: any) {
    console.error('[sched:list] error:', err);
    res.status(500).json({ success: false, message: 'خطأ داخلي' });
  }
}

// GET /api/schedule/:id
export async function getSchedGroup(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    const id = req.params.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const group = await withDb(() =>
      prisma.schedGroup.findFirst({
        where: { id, userId },
      })
    );

    if (!group) {
      res.status(404).json({ success: false, message: 'المجموعة غير موجودة' });
      return;
    }

    res.json({ success: true, group });
  } catch (err: any) {
    console.error('[sched:get] error:', err);
    res.status(500).json({ success: false, message: 'خطأ داخلي' });
  }
}

// POST /api/schedule/:id/stop
export async function stopSchedGroup(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    const id = req.params.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const group = await withDb(() =>
      prisma.schedGroup.updateMany({
        where: { id, userId },
        data: { status: 'stopped' },
      })
    );

    if (group.count === 0) {
      res.status(404).json({ success: false, message: 'المجموعة غير موجودة' });
      return;
    }

    stopSchedTask(id);
    res.json({ success: true, message: 'تم إيقاف الجدولة' });
  } catch (err: any) {
    console.error('[sched:stop] error:', err);
    res.status(500).json({ success: false, message: 'خطأ داخلي' });
  }
}

// POST /api/schedule/:id/activate
export async function activateSchedGroup(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    const id = req.params.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const group = await withDb(() =>
      prisma.schedGroup.updateMany({
        where: { id, userId },
        data: { status: 'active', nextRun: new Date() },
      })
    );

    if (group.count === 0) {
      res.status(404).json({ success: false, message: 'المجموعة غير موجودة' });
      return;
    }

    startSchedTask(id);
    res.json({ success: true, message: 'تم تفعيل الجدولة' });
  } catch (err: any) {
    console.error('[sched:activate] error:', err);
    res.status(500).json({ success: false, message: 'خطأ داخلي' });
  }
}

// DELETE /api/schedule/:id
export async function deleteSchedGroup(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.user?.id;
    const id = req.params.id;
    if (!userId) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    stopSchedTask(id);

    const group = await withDb(() =>
      prisma.schedGroup.deleteMany({
        where: { id, userId },
      })
    );

    if (group.count === 0) {
      res.status(404).json({ success: false, message: 'المجموعة غير موجودة' });
      return;
    }

    res.json({ success: true, message: 'تم حذف المجموعة' });
  } catch (err: any) {
    console.error('[sched:delete] error:', err);
    res.status(500).json({ success: false, message: 'خطأ داخلي' });
  }
}

// POST /api/schedule/parse-levels — validates and parses level/token+time lines
export async function parseLevels(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { platform, lines } = req.body as { platform: string; lines: string };
    const entries: CustomEntry[] = [];
    const errors: string[] = [];

    const rawLines = lines.split('\n');
    for (let i = 0; i < rawLines.length; i++) {
      const line = rawLines[i].trim();
      if (!line) continue;

      if (platform === 'adj') {
        const m = line.match(/^([A-Za-z0-9_]+)\/(.+)$/);
        if (!m) {
          errors.push(`سطر ${i + 1}: ${line} — الصيغة: token/وقت مثل gdhdhhd/2h`);
          continue;
        }
        let intervalMin: number;
        try {
          intervalMin = parseLevelTime(m[2]);
        } catch {
          errors.push(`سطر ${i + 1}: وقت غير صحيح ${m[2]}`);
          continue;
        }
        entries.push({ token: m[1], interval: intervalMin });
      } else {
        const m = line.match(/^(?:[Ll][Vv]?)?(\d+)\/(.+)$/);
        if (!m) {
          errors.push(`سطر ${i + 1}: ${line} — صيغة خاطئة`);
          continue;
        }
        let intervalMin: number;
        try {
          intervalMin = parseLevelTime(m[2]);
        } catch {
          errors.push(`سطر ${i + 1}: وقت غير صحيح ${m[2]}`);
          continue;
        }
        entries.push({ level: parseInt(m[1], 10), interval: intervalMin });
      }
    }

    if (errors.length > 0) {
      res.status(400).json({ success: false, message: 'أخطاء في الصيغة', errors });
      return;
    }
    if (entries.length === 0) {
      res.status(400).json({
        success: false,
        message: platform === 'adj' ? 'لم يتم إدخال أي توكن' : 'لم يتم إدخال أي لفل',
      });
      return;
    }

    entries.sort((a, b) => a.interval - b.interval);
    res.json({ success: true, entries });
  } catch (err: any) {
    console.error('[sched:parse] error:', err);
    res.status(500).json({ success: false, message: 'خطأ داخلي' });
  }
}
