import { Response } from 'express';
import prisma from '../utils/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const getProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: { id: true, email: true, name: true, role: true, createdAt: true },
    });
    const activeSubscription = await prisma.subscription.findFirst({
      where: { userId: req.user!.id, status: 'ACTIVE', endDate: { gt: new Date() } },
      include: { plan: true },
    });
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    let dailyUsage = null;
    if (activeSubscription) {
      dailyUsage = await prisma.dailyUsage.findFirst({
        where: { userId: req.user!.id, subscriptionId: activeSubscription.id, date: today },
      });
    }
    res.json({
      success: true,
      data: {
        user,
        subscription: activeSubscription,
        dailyOperationsUsed: dailyUsage?.operationsUsed || 0,
        dailyOperationsLimit: activeSubscription?.plan.dailyOperations || 0,
      },
    });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

export const getPaymentHistory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const payments = await prisma.payment.findMany({
      where: { userId: req.user!.id },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: payments });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

export const getSubscriptionHistory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const subs = await prisma.subscription.findMany({
      where: { userId: req.user!.id },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: subs });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

export const useOperation = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const activeSubscription = await prisma.subscription.findFirst({
      where: { userId: req.user!.id, status: 'ACTIVE', endDate: { gt: new Date() } },
      include: { plan: true },
    });
    if (!activeSubscription) {
      res.status(403).json({ success: false, message: 'No active subscription' });
      return;
    }
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayEnd = new Date(today);
    todayEnd.setDate(todayEnd.getDate() + 1);

    let usage = await prisma.dailyUsage.findFirst({
      where: { userId: req.user!.id, subscriptionId: activeSubscription.id, date: today },
    });

    if (!usage) {
      usage = await prisma.dailyUsage.create({
        data: { userId: req.user!.id, subscriptionId: activeSubscription.id, date: today, operationsUsed: 0 },
      });
    }

    if (usage.operationsUsed >= activeSubscription.plan.dailyOperations) {
      res.status(429).json({ success: false, message: 'Daily operation limit reached' });
      return;
    }

    const updated = await prisma.dailyUsage.update({
      where: { id: usage.id },
      data: { operationsUsed: { increment: 1 } },
    });

    res.json({
      success: true,
      data: {
        operationsUsed: updated.operationsUsed,
        operationsLimit: activeSubscription.plan.dailyOperations,
        remaining: activeSubscription.plan.dailyOperations - updated.operationsUsed,
      },
    });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
