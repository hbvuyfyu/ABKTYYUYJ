import { Response } from 'express';
import prisma, { withDb } from '../utils/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

function errMsg(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

export const getDashboard = async (_req: AuthRequest, res: Response): Promise<void> => {
  try {
    const now = new Date();
    // Run queries individually so one failure doesn't kill the whole dashboard
    const totalUsers = await withDb(() => prisma.user.count({ where: { role: 'USER' } })).catch(() => 0);
    const activeSubscriptions = await withDb(() =>
      prisma.subscription.count({ where: { status: 'ACTIVE', endDate: { gt: now } } })
    ).catch(() => 0);
    const pendingPayments = await withDb(() =>
      prisma.payment.count({ where: { status: 'PENDING' } })
    ).catch(() => 0);
    const revenueResult = await withDb(() =>
      prisma.payment.aggregate({ where: { status: 'APPROVED' }, _sum: { amount: true } })
    ).catch(() => ({ _sum: { amount: 0 } }));

    res.json({
      success: true,
      data: {
        totalUsers,
        activeSubscriptions,
        pendingPayments,
        totalRevenue: revenueResult._sum.amount ?? 0,
      },
    });
  } catch (err) {
    console.error('[getDashboard]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

export const getUsers = async (_req: AuthRequest, res: Response): Promise<void> => {
  try {
    const now = new Date();
    const users = await withDb(() =>
      prisma.user.findMany({
        where: { role: 'USER' },
        select: {
          id: true, email: true, name: true, isActive: true, createdAt: true,
          subscriptions: {
            where: { status: 'ACTIVE', endDate: { gt: now } },
            include: { plan: true },
            take: 1,
          },
        },
        orderBy: { createdAt: 'desc' },
      })
    );
    res.json({ success: true, data: users });
  } catch (err) {
    console.error('[getUsers]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

export const getAllSubscriptions = async (_req: AuthRequest, res: Response): Promise<void> => {
  try {
    const subscriptions = await withDb(() =>
      prisma.subscription.findMany({
        include: {
          user: { select: { id: true, email: true, name: true } },
          plan: true,
        },
        orderBy: { createdAt: 'desc' },
      })
    );
    res.json({ success: true, data: subscriptions });
  } catch (err) {
    console.error('[getAllSubscriptions]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

export const getPendingPayments = async (_req: AuthRequest, res: Response): Promise<void> => {
  try {
    // Only show payments where user has confirmed (userConfirmedAt is not null)
    // This ensures admin only sees payments that are ready for review
    const payments = await withDb(() =>
      prisma.payment.findMany({
        where: {
          status: 'PENDING',
          userConfirmedAt: { not: null }, // Only show confirmed payments
        },
        include: { user: { select: { id: true, email: true, name: true } }, plan: true },
        orderBy: { userConfirmedAt: 'desc' },
      })
    );
    // Strip heavy base64 field from list responses
    const cleaned = payments.map((p) => {
      const { proofImageBase64, ...rest } = p as any;
      return rest;
    });
    res.json({ success: true, data: cleaned });
  } catch (err) {
    console.error('[getPendingPayments]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

export const getAllPayments = async (_req: AuthRequest, res: Response): Promise<void> => {
  try {
    const payments = await withDb(() =>
      prisma.payment.findMany({
        include: { user: { select: { id: true, email: true, name: true } }, plan: true },
        orderBy: { createdAt: 'desc' },
      })
    );
    // Strip heavy base64 field from list responses
    const cleaned = payments.map((p) => {
      const { proofImageBase64, ...rest } = p as any;
      return rest;
    });
    res.json({ success: true, data: cleaned });
  } catch (err) {
    console.error('[getAllPayments]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Admin approves a payment → creates subscription ───────────────────────────
export const approvePayment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { paymentId } = req.params;
    const payment = await withDb(() =>
      prisma.payment.findUnique({ where: { id: paymentId }, include: { plan: true } })
    );
    if (!payment || payment.status !== 'PENDING') {
      res.status(404).json({ success: false, message: 'الدفع غير موجود أو تمت معالجته مسبقاً' });
      return;
    }

    // Cancel any existing active subscription for this user
    await withDb(() =>
      prisma.subscription.updateMany({
        where: { userId: payment.userId, status: 'ACTIVE' },
        data: { status: 'CANCELLED' },
      })
    );

    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + payment.plan.durationDays);

    const subscription = await withDb(() =>
      prisma.subscription.create({
        data: { userId: payment.userId, planId: payment.planId, status: 'ACTIVE', startDate, endDate },
      })
    );

    await withDb(() =>
      prisma.payment.update({
        where: { id: paymentId },
        data: {
          status: 'APPROVED',
          subscriptionId: subscription.id,
          reviewedBy: req.user!.id,
          reviewedAt: new Date(),
        },
      })
    );

    await withDb(() =>
      prisma.adminLog.create({
        data: {
          adminId: req.user!.id,
          targetId: payment.userId,
          action: 'PAYMENT_APPROVED',
          details: `Payment ${paymentId} approved — subscription activated`,
        },
      })
    );

    res.json({ success: true, message: 'تم قبول الدفع وتفعيل الاشتراك' });
  } catch (err) {
    console.error('[approvePayment]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Admin rejects a payment ───────────────────────────────────────────────────
export const rejectPayment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { paymentId } = req.params;
    const { adminNotes } = req.body;
    const payment = await withDb(() => prisma.payment.findUnique({ where: { id: paymentId } }));
    if (!payment || payment.status !== 'PENDING') {
      res.status(404).json({ success: false, message: 'الدفع غير موجود أو تمت معالجته مسبقاً' });
      return;
    }
    await withDb(() =>
      prisma.payment.update({
        where: { id: paymentId },
        data: { status: 'REJECTED', adminNotes, reviewedBy: req.user!.id, reviewedAt: new Date() },
      })
    );
    await withDb(() =>
      prisma.adminLog.create({
        data: {
          adminId: req.user!.id,
          targetId: payment.userId,
          action: 'PAYMENT_REJECTED',
          details: `Payment ${paymentId} rejected`,
        },
      })
    );
    res.json({ success: true, message: 'تم رفض الدفع' });
  } catch (err) {
    console.error('[rejectPayment]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Admin manually activates a subscription (admin-only shortcut) ─────────────
export const activateSubscription = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { userId, planId } = req.body;
    if (!userId || !planId) {
      res.status(400).json({ success: false, message: 'userId و planId مطلوبان' });
      return;
    }
    const plan = await withDb(() => prisma.plan.findUnique({ where: { id: planId } }));
    if (!plan) {
      res.status(404).json({ success: false, message: 'الباقة غير موجودة' });
      return;
    }

    // Cancel existing active subscriptions
    await withDb(() =>
      prisma.subscription.updateMany({
        where: { userId, status: 'ACTIVE' },
        data: { status: 'CANCELLED' },
      })
    );

    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + plan.durationDays);

    const subscription = await withDb(() =>
      prisma.subscription.create({
        data: { userId, planId, status: 'ACTIVE', startDate, endDate },
      })
    );

    await withDb(() =>
      prisma.adminLog.create({
        data: {
          adminId: req.user!.id,
          targetId: userId,
          action: 'SUBSCRIPTION_ACTIVATED',
          details: `Plan ${plan.name} activated manually by admin`,
        },
      })
    );

    res.json({ success: true, data: subscription });
  } catch (err) {
    console.error('[activateSubscription]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

export const toggleUser = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { userId } = req.params;
    const user = await withDb(() => prisma.user.findUnique({ where: { id: userId } }));
    if (!user) {
      res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
      return;
    }
    const updated = await withDb(() =>
      prisma.user.update({ where: { id: userId }, data: { isActive: !user.isActive } })
    );
    res.json({ success: true, data: { isActive: updated.isActive } });
  } catch (err) {
    console.error('[toggleUser]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

export const getAdminLogs = async (_req: AuthRequest, res: Response): Promise<void> => {
  try {
    const logs = await withDb(() =>
      prisma.adminLog.findMany({
        include: {
          admin: { select: { email: true, name: true } },
          target: { select: { email: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: 200,
      })
    );
    res.json({ success: true, data: logs });
  } catch (err) {
    console.error('[getAdminLogs]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── Get payment proof image (URL or base64) ───────────────────────────────────
export const getPaymentProof = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { paymentId } = req.params;
    const payment = await withDb(() =>
      prisma.payment.findUnique({
        where: { id: paymentId },
        select: { proofImageUrl: true, proofImageBase64: true },
      })
    );
    if (!payment) {
      res.status(404).json({ success: false, message: 'الدفع غير موجود' });
      return;
    }
    res.json({
      success: true,
      data: {
        proofImageUrl: payment.proofImageUrl,
        hasBase64: !!payment.proofImageBase64,
        proofImageBase64: payment.proofImageBase64,
      },
    });
  } catch (err) {
    console.error('[getPaymentProof]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};
