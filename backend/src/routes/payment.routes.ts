import { Router } from 'express';
import { createPayment, uploadProof, verifyTxid, getPaymentSettings } from '../controllers/payment.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();
router.get('/settings', getPaymentSettings);
router.use(authenticate);
router.post('/', createPayment);
router.post('/:paymentId/proof', uploadProof);
router.post('/:paymentId/verify-txid', verifyTxid);
export default router;
