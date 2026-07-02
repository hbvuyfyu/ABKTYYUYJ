import { PrismaClient, Prisma } from '@prisma/client';

declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined;
}

const prisma: PrismaClient =
  global.__prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') {
  global.__prisma = prisma;
}

// ── Retry wrapper ─────────────────────────────────────────────────────────────
// Retries a Prisma operation up to `attempts` times on connection errors.
export async function withDb<T>(
  fn: () => Promise<T>,
  attempts = 3,
): Promise<T> {
  let lastErr: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      const code =
        err instanceof Prisma.PrismaClientKnownRequestError
          ? err.code
          : (err as any)?.code ?? '';
      const msg = String((err as any)?.message ?? '');
      const isConnErr =
        code === 'P1001' || // Connection refused
        code === 'P1002' || // Connection timed out
        code === 'P1008' || // Operations timed out
        code === 'P1017' || // Server closed the connection
        msg.includes('connection') ||
        msg.includes('socket') ||
        msg.includes('ECONNRESET') ||
        msg.includes('ETIMEDOUT');

      if (isConnErr && i < attempts - 1) {
        console.warn(`[DB] Connection error (attempt ${i + 1}/${attempts}), retrying in ${(i + 1) * 500}ms…`);
        await new Promise(r => setTimeout(r, (i + 1) * 500));
        try { await prisma.$connect(); } catch { /* ignore */ }
        continue;
      }
      throw err;
    }
  }
  throw lastErr;
}

export default prisma;
