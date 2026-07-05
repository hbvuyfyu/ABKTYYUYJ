import { Response } from 'express';
import axios from 'axios';
import { SocksProxyAgent } from 'socks-proxy-agent';
import { HttpsProxyAgent } from 'https-proxy-agent';
import prisma, { withDb } from '../utils/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

function errMsg(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

type ProxyType = 'socks5' | 'http';

interface ProxyRow {
  id: string;
  userId: string;
  name: string;
  type: string;
  host: string;
  port: number;
  username: string | null;
  password: string | null;
  isActive: boolean;
  isWorking: boolean;
  lastCheck: Date | null;
  lastError: string | null;
}

function buildAgent(proxy: { type: string; host: string; port: number; username: string | null; password: string | null }): SocksProxyAgent | HttpsProxyAgent<string> | null {
  const auth = proxy.username && proxy.password
    ? `${encodeURIComponent(proxy.username)}:${encodeURIComponent(proxy.password)}@`
    : proxy.username
      ? `${encodeURIComponent(proxy.username)}@`
      : '';
  if (proxy.type === 'socks5') {
    const url = `socks5://${auth}${proxy.host}:${proxy.port}`;
    return new SocksProxyAgent(url);
  }
  if (proxy.type === 'http') {
    const url = `http://${auth}${proxy.host}:${proxy.port}`;
    return new HttpsProxyAgent(url);
  }
  return null;
}

// ── List user's proxies ───────────────────────────────────────────────────────
export const listProxies = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const proxies = await withDb(() =>
      prisma.proxy.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      })
    );
    const selection = await withDb(() =>
      prisma.userProxySelection.findUnique({ where: { userId } })
    );
    res.json({
      success: true,
      data: proxies,
      selectedProxyId: selection?.proxyId ?? null,
    });
  } catch (err) {
    console.error('[listProxies]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Create proxy ──────────────────────────────────────────────────────────────
export const createProxy = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { name, type, host, port, username, password } = req.body as {
      name: string;
      type: ProxyType;
      host: string;
      port: number;
      username?: string;
      password?: string;
    };

    if (!name || !type || !host || !port) {
      res.status(400).json({ success: false, message: 'الاسم، النوع، المضيف، والمنفذ مطلوبة' });
      return;
    }
    if (type !== 'socks5' && type !== 'http') {
      res.status(400).json({ success: false, message: 'النوع يجب أن يكون socks5 أو http' });
      return;
    }

    const proxy = await withDb(() =>
      prisma.proxy.create({
        data: {
          userId,
          name: name.trim(),
          type,
          host: host.trim(),
          port: Number(port),
          username: username?.trim() || null,
          password: password || null,
        },
      })
    );
    res.status(201).json({ success: true, data: proxy });
  } catch (err) {
    console.error('[createProxy]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Update proxy ──────────────────────────────────────────────────────────────
export const updateProxy = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { id } = req.params;
    const { name, type, host, port, username, password, isActive } = req.body as {
      name?: string;
      type?: ProxyType;
      host?: string;
      port?: number;
      username?: string;
      password?: string;
      isActive?: boolean;
    };

    const existing = await withDb(() =>
      prisma.proxy.findFirst({ where: { id, userId } })
    );
    if (!existing) {
      res.status(404).json({ success: false, message: 'البروكسي غير موجود' });
      return;
    }

    const data: any = {};
    if (name !== undefined) data.name = name.trim();
    if (type !== undefined) {
      if (type !== 'socks5' && type !== 'http') {
        res.status(400).json({ success: false, message: 'النوع يجب أن يكون socks5 أو http' });
        return;
      }
      data.type = type;
    }
    if (host !== undefined) data.host = host.trim();
    if (port !== undefined) data.port = Number(port);
    if (username !== undefined) data.username = username.trim() || null;
    if (password !== undefined) data.password = password || null;
    if (isActive !== undefined) data.isActive = isActive;

    const updated = await withDb(() =>
      prisma.proxy.update({ where: { id }, data })
    );
    res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[updateProxy]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Delete proxy ──────────────────────────────────────────────────────────────
export const deleteProxy = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { id } = req.params;

    const existing = await withDb(() =>
      prisma.proxy.findFirst({ where: { id, userId } })
    );
    if (!existing) {
      res.status(404).json({ success: false, message: 'البروكسي غير موجود' });
      return;
    }

    // If this proxy is currently selected, clear the selection
    await withDb(() =>
      prisma.userProxySelection.updateMany({
        where: { userId, proxyId: id },
        data: { proxyId: null },
      })
    ).catch(() => {});

    await withDb(() => prisma.proxy.delete({ where: { id } }));
    res.json({ success: true, message: 'تم حذف البروكسي' });
  } catch (err) {
    console.error('[deleteProxy]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Test proxy connectivity ────────────────────────────────────────────────────
export const testProxy = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { id } = req.params;

    const proxy = await withDb(() =>
      prisma.proxy.findFirst({ where: { id, userId } })
    );
    if (!proxy) {
      res.status(404).json({ success: false, message: 'البروكسي غير موجود' });
      return;
    }

    const agent = buildAgent(proxy);
    if (!agent) {
      await withDb(() =>
        prisma.proxy.update({
          where: { id },
          data: { isWorking: false, lastCheck: new Date(), lastError: 'نوع بروكسي غير مدعوم' },
        })
      );
      res.status(400).json({ success: false, message: 'نوع بروكسي غير مدعوم' });
      return;
    }

    const start = Date.now();
    try {
      const r = await axios.get('https://api.ipify.org?format=json', {
        httpsAgent: agent,
        timeout: 20000,
        proxy: false,
      });
      const elapsed = Date.now() - start;
      const ip = r.data?.ip ?? '';

      await withDb(() =>
        prisma.proxy.update({
          where: { id },
          data: { isWorking: true, lastCheck: new Date(), lastError: null },
        })
      );

      res.json({
        success: true,
        message: 'البروكسي يعمل بنجاح',
        ip,
        latencyMs: elapsed,
      });
    } catch (err: any) {
      const errorMsg = err?.message ?? 'فشل الاتصال بالبروكسي';
      await withDb(() =>
        prisma.proxy.update({
          where: { id },
          data: { isWorking: false, lastCheck: new Date(), lastError: errorMsg },
        })
      );
      res.status(502).json({ success: false, message: `البروكسي لا يعمل: ${errorMsg}` });
    }
  } catch (err) {
    console.error('[testProxy]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Select a proxy (only one active at a time) ────────────────────────────────
export const selectProxy = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    const { id } = req.params;

    const proxy = await withDb(() =>
      prisma.proxy.findFirst({ where: { id, userId } })
    );
    if (!proxy) {
      res.status(404).json({ success: false, message: 'البروكسي غير موجود' });
      return;
    }

    await withDb(() =>
      prisma.userProxySelection.upsert({
        where: { userId },
        create: { userId, proxyId: id },
        update: { proxyId: id },
      })
    );
    res.json({ success: true, message: 'تم اختيار البروكسي' });
  } catch (err) {
    console.error('[selectProxy]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Clear selection (use direct connection) ────────────────────────────────────
export const clearProxySelection = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user!.id;
    await withDb(() =>
      prisma.userProxySelection.upsert({
        where: { userId },
        create: { userId, proxyId: null },
        update: { proxyId: null },
      })
    );
    res.json({ success: true, message: 'تم إلغاء اختيار البروكسي' });
  } catch (err) {
    console.error('[clearProxySelection]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Get the user's selected proxy (internal helper, exported for other modules) ─
export async function getUserProxy(userId: string): Promise<ProxyRow | null> {
  const selection = await prisma.userProxySelection.findUnique({
    where: { userId },
    include: { proxy: true },
  });
  if (!selection?.proxy || !selection.proxy.isActive) return null;
  return selection.proxy as ProxyRow;
}

// ── Build an axios agent for a given user (null = direct) ──────────────────────
export async function getAxiosAgentForUser(userId: string): Promise<SocksProxyAgent | HttpsProxyAgent<string> | null> {
  const proxy = await getUserProxy(userId);
  if (!proxy) return null;
  return buildAgent(proxy);
}

// ── Test a proxy by attempting to use it for a real request (used by scheduler/jumper) ─
export async function verifyProxyWorking(userId: string): Promise<{ working: boolean; error?: string }> {
  const proxy = await getUserProxy(userId);
  if (!proxy) return { working: true }; // no proxy selected = direct = ok
  const agent = buildAgent(proxy);
  if (!agent) return { working: false, error: 'نوع بروكسي غير مدعوم' };
  try {
    await axios.get('https://api.ipify.org?format=json', {
      httpsAgent: agent,
      timeout: 15000,
      proxy: false,
    });
    await prisma.proxy.update({
      where: { id: proxy.id },
      data: { isWorking: true, lastCheck: new Date(), lastError: null },
    });
    return { working: true };
  } catch (err: any) {
    const errorMsg = err?.message ?? 'فشل الاتصال';
    await prisma.proxy.update({
      where: { id: proxy.id },
      data: { isWorking: false, lastCheck: new Date(), lastError: errorMsg },
    }).catch(() => {});
    return { working: false, error: errorMsg };
  }
}
