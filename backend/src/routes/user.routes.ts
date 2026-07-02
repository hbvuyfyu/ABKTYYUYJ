import { Router } from 'express';
import { getProfile, getPaymentHistory, getSubscriptionHistory, useOperation } from '../controllers/user.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();
router.use(authenticate);
router.get('/profile', getProfile);
router.get('/payment-history', getPaymentHistory);
router.get('/subscription-history', getSubscriptionHistory);
router.post('/use-operation', useOperation);
export default router;
