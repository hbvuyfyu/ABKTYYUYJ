import { Request, Response } from 'express';
import axios from 'axios';
import prisma from '../utils/prisma';
import { detectGameByPackage, AfGame, SingularGame, AdjGame } from '../data/games_data';
import { AuthRequest } from '../middleware/auth.middleware';

// ── Daily limit helper ────────────────────────────────────────────────────────

async function checkAndIncrementDailyUsage(
  userId: string
): Promise<{ allowed: boolean; used: number; limit: number; remaining: number; subscriptionId?: string }> {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const sub = await prisma.subscription.findFirst({
    where: { userId, status: 'ACTIVE', endDate: { gt: now } },
    include: { plan: true },
    orderBy: { createdAt: 'desc' },
  });

  if (!sub) return { allowed: false, used: 0, limit: 0, remaining: 0 };

  const limit = sub.plan.dailyOperations;

  const usage = await prisma.dailyUsage.upsert({
    where: { userId_subscriptionId_date: { userId, subscriptionId: sub.id, date: today } },
    create: { userId, subscriptionId: sub.id, date: today, operationsUsed: 0 },
    update: {},
  });

  if (usage.operationsUsed >= limit) {
    return { allowed: false, used: usage.operationsUsed, limit, remaining: 0, subscriptionId: sub.id };
  }

  await prisma.dailyUsage.update({
    where: { id: usage.id },
    data: { operationsUsed: { increment: 1 } },
  });

  return {
    allowed: true,
    used: usage.operationsUsed + 1,
    limit,
    remaining: limit - usage.operationsUsed - 1,
    subscriptionId: sub.id,
  };
}

// ── Detect Game ───────────────────────────────────────────────────────────────

export async function detectGame(req: Request, res: Response): Promise<void> {
  const pkg = (req.query.package as string || '').trim();
  if (!pkg) {
    res.status(400).json({ success: false, message: 'package is required' });
    return;
  }

  // 1. Check static data
  const staticResult = detectGameByPackage(pkg);
  if (staticResult.found) {
    const { platform, game } = staticResult;
    let events: any[] = [];
    let firstEvent: any = null;
    let gameData: any = {};

    if (platform === 'af') {
      const g = game as AfGame;
      gameData = { name: g.name, displayName: g.displayName, package: g.package, devKey: g.devKey, emoji: g.emoji };
      events = g.events;
      firstEvent = g.events.find(e => !e.isPurchase) || g.events[0] || null;
    } else if (platform === 'singular') {
      const g = game as SingularGame;
      gameData = { name: g.name, displayName: g.displayName, package: g.package, appKey: g.appKey, emoji: g.emoji };
      events = g.events;
      firstEvent = g.events[0] || null;
    } else {
      const g = game as AdjGame;
      gameData = { name: g.name, displayName: g.displayName, appToken: g.appToken, emoji: g.emoji };
      events = g.events;
      firstEvent = g.events[0] || null;
    }

    res.json({ success: true, found: true, platform, game: { ...gameData, events }, firstEvent, source: 'static' });
    return;
  }

  // 2. Check DB (admin-added games)
  try {
    const dbGame = await prisma.game.findFirst({
      where: { package: pkg, isActive: true },
      include: { events: true },
    });

    if (dbGame) {
      const events = dbGame.events.map(e => ({
        eventName: e.eventName,
        displayName: e.displayName,
        eventToken: e.eventToken,
        isPurchase: e.isPurchase,
      }));
      const firstEvent = events.find(e => !e.isPurchase) || events[0] || null;

      const gameData: any = {
        name: dbGame.name,
        displayName: dbGame.displayName,
        package: dbGame.package,
        emoji: dbGame.emoji,
        events,
      };
      if (dbGame.platform === 'af') gameData.devKey = dbGame.devKey;
      else if (dbGame.platform === 'singular') gameData.appKey = dbGame.appKey;
      else if (dbGame.platform === 'adj') gameData.appToken = dbGame.appToken;

      res.json({ success: true, found: true, platform: dbGame.platform, game: gameData, firstEvent, source: 'db' });
      return;
    }
  } catch (_) {}

  res.json({ success: true, found: false, message: 'Game not in supported list' });
}

// ── HTTP send helpers ────────────────────────────────────────────────────────

async function sendAF(
  pkg: string, devKey: string, gaid: string, afUid: string,
  eventName: string, revenue?: number
): Promise<{ status: number; body: string }> {
  const url = `https://api2.appsflyer.com/inappevent/${pkg}`;
  const now = Date.now();

  const eventValue: Record<string, string> = {};
  if (revenue) {
    eventValue.af_content_id = `combo_${Math.floor(Math.random() * 50) + 1}`;
    eventValue.af_content_type = 'purchase';
    eventValue.af_currency = 'USD';
    eventValue.af_price = String(revenue);
  } else {
    const levelNum = eventName.replace(/[^0-9]/g, '');
    if (levelNum) {
      eventValue.af_level = levelNum;
      eventValue.af_score = String(Math.floor(Math.random() * 49000) + 1000);
      eventValue.af_duration = String(Math.floor(Math.random() * 270) + 30);
    }
  }

  const payload: Record<string, any> = {
    appsflyer_id: afUid,
    advertising_id: gaid,
    eventName,
    eventTime: now,
    eventValue,
    device_model: 'SM-S911B',
    os_version: 'Android 14',
    sdk_version: '6.15.0',
    app_version_name: '2.3.0',
    network: 'WiFi',
    language: 'en-US',
    timezone: 'Asia/Riyadh',
  };
  if (revenue) { payload.eventRevenue = String(revenue); payload.eventCurrency = 'USD'; }

  try {
    const r = await axios.post(url, payload, {
      headers: {
        Authentication: devKey,
        'User-Agent': 'AppsFlyer-Android-SDK/6.15.0 (Linux; Android 14; SM-S911B)',
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    });
    return { status: r.status, body: typeof r.data === 'string' ? r.data : JSON.stringify(r.data) };
  } catch (err: any) {
    return { status: err?.response?.status ?? 500, body: JSON.stringify(err?.response?.data ?? err.message) };
  }
}

async function sendADJ(
  appToken: string, eventToken: string, gpsAdid: string
): Promise<{ status: number; body: string }> {
  try {
    const r = await axios.get('https://s2s.adjust.com/event', {
      params: { app_token: appToken, event_token: eventToken, gps_adid: gpsAdid, s2s: '1', created_at: String(Math.floor(Date.now() / 1000)) },
      timeout: 30000,
    });
    return { status: r.status, body: typeof r.data === 'string' ? r.data : JSON.stringify(r.data) };
  } catch (err: any) {
    return { status: err?.response?.status ?? 500, body: JSON.stringify(err?.response?.data ?? err.message) };
  }
}

async function sendSingular(
  eventName: string, aifa: string, uid: string,
  pkg: string, appKey: string, level?: number
): Promise<{ status: number; body: string }> {
  const payload: Record<string, any> = {
    a: appKey, p: pkg, i: aifa, e: eventName, t: Date.now(),
  };
  if (uid) payload.cu = uid;
  if (level) payload.lvl = level;

  try {
    const r = await axios.post('https://s2s.singular.net/api/v1/evt', payload, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 30000,
    });
    return { status: r.status, body: typeof r.data === 'string' ? r.data : JSON.stringify(r.data) };
  } catch (err: any) {
    return { status: err?.response?.status ?? 500, body: JSON.stringify(err?.response?.data ?? err.message) };
  }
}

// ── Send Event (requires auth) ────────────────────────────────────────────────

export async function sendEvent(req: AuthRequest, res: Response): Promise<void> {
  const userId = req.user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Authentication required' });
    return;
  }

  // Check daily limit
  const usageCheck = await checkAndIncrementDailyUsage(userId);
  if (!usageCheck.allowed) {
    if (usageCheck.limit === 0) {
      res.status(403).json({
        success: false,
        message: 'لا يوجد اشتراك نشط. يرجى الاشتراك في إحدى الباقات.',
        code: 'NO_SUBSCRIPTION',
      });
    } else {
      res.status(429).json({
        success: false,
        message: `وصلت للحد اليومي (${usageCheck.limit} عملية). حاول غداً.`,
        code: 'DAILY_LIMIT_EXCEEDED',
        used: usageCheck.used,
        limit: usageCheck.limit,
      });
    }
    return;
  }

  const { platform, package: pkg, gaid, afUid, appKey, appToken,
          eventName, eventToken, devKey, level, revenue } = req.body;

  if (!platform) {
    res.status(400).json({ success: false, message: 'platform is required' });
    return;
  }

  try {
    let result: { status: number; body: string };

    if (platform === 'af') {
      if (!pkg || !devKey || !gaid || !afUid || !eventName) {
        res.status(400).json({ success: false, message: 'AF requires: package, devKey, gaid, afUid, eventName' });
        return;
      }
      result = await sendAF(pkg, devKey, gaid, afUid, eventName, revenue);
    } else if (platform === 'adj') {
      if (!appToken || !eventToken || !gaid) {
        res.status(400).json({ success: false, message: 'ADJ requires: appToken, eventToken, gaid' });
        return;
      }
      result = await sendADJ(appToken, eventToken, gaid);
    } else if (platform === 'singular') {
      if (!pkg || !appKey || !gaid || !eventName) {
        res.status(400).json({ success: false, message: 'Singular requires: package, appKey, gaid, eventName' });
        return;
      }
      result = await sendSingular(eventName, gaid, afUid || '', pkg, appKey, level);
    } else {
      res.status(400).json({ success: false, message: 'Unknown platform. Use: af, adj, singular' });
      return;
    }

    const ok = result.status >= 200 && result.status < 300;
    res.json({
      success: ok,
      statusCode: result.status,
      response: result.body,
      platform,
      eventName: eventName || eventToken,
      dailyUsage: { used: usageCheck.used, limit: usageCheck.limit, remaining: usageCheck.remaining },
    });
  } catch (err: any) {
    res.status(500).json({ success: false, message: String(err.message) });
  }
}

// ── Get daily usage (for display in app) ─────────────────────────────────────

export async function getDailyUsage(req: AuthRequest, res: Response): Promise<void> {
  const userId = req.user?.id;
  if (!userId) { res.status(401).json({ success: false, message: 'Unauthorized' }); return; }

  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const sub = await prisma.subscription.findFirst({
    where: { userId, status: 'ACTIVE', endDate: { gt: now } },
    include: { plan: true },
    orderBy: { createdAt: 'desc' },
  });

  if (!sub) {
    res.json({ success: true, data: { hasSubscription: false, used: 0, limit: 0, remaining: 0 } });
    return;
  }

  const usage = await prisma.dailyUsage.findUnique({
    where: { userId_subscriptionId_date: { userId, subscriptionId: sub.id, date: today } },
  });

  const used = usage?.operationsUsed ?? 0;
  const limit = sub.plan.dailyOperations;
  res.json({
    success: true,
    data: {
      hasSubscription: true,
      planName: sub.plan.nameAr,
      used,
      limit,
      remaining: Math.max(0, limit - used),
      endDate: sub.endDate,
    },
  });
}

// ── List all games (static + DB) ──────────────────────────────────────────────

export async function listGames(_req: Request, res: Response): Promise<void> {
  const { AF_GAMES, SINGULAR_GAMES, ADJ_GAMES } = await import('../data/games_data');
  const dbGames = await prisma.game.findMany({ where: { isActive: true }, include: { events: true }, orderBy: { createdAt: 'desc' } });

  res.json({
    success: true,
    af: AF_GAMES.map((g: AfGame) => ({ name: g.name, displayName: g.displayName, package: g.package, emoji: g.emoji, source: 'static' })),
    singular: SINGULAR_GAMES.map((g: SingularGame) => ({ name: g.name, displayName: g.displayName, package: g.package, emoji: g.emoji, source: 'static' })),
    adj: ADJ_GAMES.map((g: AdjGame) => ({ name: g.name, displayName: g.displayName, emoji: g.emoji, source: 'static' })),
    db: dbGames,
  });
}

// ── Admin: Game CRUD ──────────────────────────────────────────────────────────

export async function adminListGames(_req: AuthRequest, res: Response): Promise<void> {
  const games = await prisma.game.findMany({ include: { events: true }, orderBy: { createdAt: 'desc' } });
  res.json({ success: true, data: games });
}

export async function adminCreateGame(req: AuthRequest, res: Response): Promise<void> {
  const { name, displayName, platform, package: pkg, devKey, appKey, appToken, emoji, events } = req.body;
  if (!name || !displayName || !platform) {
    res.status(400).json({ success: false, message: 'name, displayName, platform are required' });
    return;
  }
  const game = await prisma.game.create({
    data: {
      name, displayName, platform,
      package: pkg || null,
      devKey: devKey || null,
      appKey: appKey || null,
      appToken: appToken || null,
      emoji: emoji || '🎮',
      events: events?.length
        ? { create: (events as any[]).map((e: any) => ({ eventName: e.eventName, displayName: e.displayName, eventToken: e.eventToken || null, isPurchase: e.isPurchase || false })) }
        : undefined,
    },
    include: { events: true },
  });
  res.status(201).json({ success: true, data: game });
}

export async function adminUpdateGame(req: AuthRequest, res: Response): Promise<void> {
  const { id } = req.params;
  const { name, displayName, platform, package: pkg, devKey, appKey, appToken, emoji, isActive } = req.body;
  const game = await prisma.game.update({
    where: { id },
    data: { name, displayName, platform, package: pkg, devKey, appKey, appToken, emoji, isActive },
    include: { events: true },
  });
  res.json({ success: true, data: game });
}

export async function adminDeleteGame(req: AuthRequest, res: Response): Promise<void> {
  const { id } = req.params;
  await prisma.game.update({ where: { id }, data: { isActive: false } });
  res.json({ success: true, message: 'Game deactivated' });
}

export async function adminAddGameEvent(req: AuthRequest, res: Response): Promise<void> {
  const { id } = req.params;
  const { eventName, displayName, eventToken, isPurchase } = req.body;
  if (!eventName || !displayName) {
    res.status(400).json({ success: false, message: 'eventName and displayName are required' });
    return;
  }
  const event = await prisma.gameEvent.create({
    data: { gameId: id, eventName, displayName, eventToken: eventToken || null, isPurchase: isPurchase || false },
  });
  res.status(201).json({ success: true, data: event });
}

export async function adminDeleteGameEvent(req: AuthRequest, res: Response): Promise<void> {
  const { eventId } = req.params;
  await prisma.gameEvent.delete({ where: { id: eventId } });
  res.json({ success: true, message: 'Event deleted' });
}
