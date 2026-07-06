import { Router } from 'express';
import { createPayment, uploadProof, verifyTxid, getPaymentSettings, submitPaymentProof } from '../controllers/payment.controller';
import { createOxapayPayment, oxapayCallback, checkOxapayStatus } from '../controllers/oxapay.controller';
import { verifyShamCashTransaction, getSyriatelHistory, getShamCashLogs } from '../controllers/apisyria.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Public routes
router.get('/settings', getPaymentSettings);

// OxaPay callback (no auth - called by OxaPay servers)
router.post('/oxapay/callback', oxapayCallback);

// Authenticated routes
router.use(authenticate);
router.post('/', createPayment);
router.post('/:paymentId/proof', uploadProof);
router.post('/:paymentId/submit-proof', submitPaymentProof);
router.post('/:paymentId/verify-txid', verifyTxid);

// OxaPay routes (USDT)
router.post('/:paymentId/oxapay/create', createOxapayPayment);
router.get('/:paymentId/oxapay/status', checkOxapayStatus);

// API Syria routes (ShamCash & Syriatel Cash)
router.post('/:paymentId/apisyria/verify', verifyShamCashTransaction);
router.get('/apisyria/syriatel-history', getSyriatelHistory);
router.get('/apisyria/shamcash-logs', getShamCashLogs);

export default router;
