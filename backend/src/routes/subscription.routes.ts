import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import prisma from '../utils/prisma';
import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';

const router = Router();
router.use(authenticate);

router.get('/active', async (req: AuthRequest, res: Response) => {
  try {
    const sub = await prisma.subscription.findFirst({
      where: { userId: req.user!.id, status: 'ACTIVE', endDate: { gt: new Date() } },
      include: { plan: true },
    });
    res.json({ success: true, data: sub });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

export default router;
