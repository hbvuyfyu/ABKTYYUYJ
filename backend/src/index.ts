import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import rateLimit from 'express-rate-limit';

import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import planRoutes from './routes/plan.routes';
import paymentRoutes from './routes/payment.routes';
import subscriptionRoutes from './routes/subscription.routes';
import adminRoutes from './routes/admin.routes';
import settingsRoutes from './routes/settings.routes';
import gamesRoutes from './routes/games.routes';
import prisma from './utils/prisma';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// ── Security & parsing ────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('dev'));

// ── Rate limiters ─────────────────────────────────────────────────────────────
// Auth routes: more lenient — mobile apps retry and users may mistype passwords
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 60,                   // 60 attempts per IP per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'طلبات كثيرة جداً، حاول بعد قليل.' },
  skip: (_req) => process.env.NODE_ENV === 'development',
});

// General API limiter
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'طلبات كثيرة جداً، حاول بعد قليل.' },
  skip: (_req) => process.env.NODE_ENV === 'development',
});

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/users', apiLimiter, userRoutes);
app.use('/api/plans', apiLimiter, planRoutes);
app.use('/api/payments', apiLimiter, paymentRoutes);
app.use('/api/subscriptions', apiLimiter, subscriptionRoutes);
app.use('/api/admin', apiLimiter, adminRoutes);
app.use('/api/settings', apiLimiter, settingsRoutes);
app.use('/api/games', apiLimiter, gamesRoutes);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/api/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({
      success: true,
      message: 'VIP API is running',
      db: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[health] DB check failed:', err);
    // Attempt reconnect
    try { await prisma.$connect(); } catch { /* ignore */ }
    res.status(503).json({
      success: false,
      message: 'Database connection failed',
      db: 'reconnecting',
    });
  }
});

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, message: 'المسار غير موجود' });
});

// ── Global error handler ──────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[Unhandled Error]', err.message, err.stack);
  res.status(500).json({ success: false, message: 'خطأ داخلي في السيرفر' });
});

// ── Bootstrap ─────────────────────────────────────────────────────────────────
async function bootstrap(): Promise<void> {
  let retries = 5;
  while (retries > 0) {
    try {
      await prisma.$connect();
      console.log('✅ Database connected successfully');
      break;
    } catch (error) {
      retries--;
      if (retries === 0) {
        console.error('❌ Failed to connect to database after 5 attempts:', error);
        process.exit(1);
      }
      console.warn(`⚠️  DB connect failed, retrying in 3s… (${retries} attempts left)`);
      await new Promise(r => setTimeout(r, 3000));
    }
  }

  app.listen(PORT, () => {
    console.log(`🚀 VIP Backend running on port ${PORT}`);
  });
}

process.on('SIGINT',  async () => { await prisma.$disconnect(); process.exit(0); });
process.on('SIGTERM', async () => { await prisma.$disconnect(); process.exit(0); });
process.on('uncaughtException', (err) => { console.error('[uncaughtException]', err); });
process.on('unhandledRejection', (reason) => { console.error('[unhandledRejection]', reason); });

bootstrap();

export default app;
