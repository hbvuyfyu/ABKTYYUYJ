import { Response } from 'express';
import prisma, { withDb } from '../utils/prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import axios from 'axios';
import { v2 as cloudinary } from 'cloudinary';

function errMsg(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

const configureCloudinary = async () => {
  const [cloudName, apiKey, apiSecret] = await Promise.all([
    prisma.settings.findUnique({ where: { key: 'cloudinary_cloud_name' } }),
    prisma.settings.findUnique({ where: { key: 'cloudinary_api_key' } }),
    prisma.settings.findUnique({ where: { key: 'cloudinary_api_secret' } }),
  ]);
  cloudinary.config({
    cloud_name: cloudName?.value || process.env.CLOUDINARY_CLOUD_NAME,
    api_key: apiKey?.value || process.env.CLOUDINARY_API_KEY,
    api_secret: apiSecret?.value || process.env.CLOUDINARY_API_SECRET,
  });
};

export const getPaymentSettings = async (_req: any, res: Response): Promise<void> => {
  try {
    const settings = await withDb(() => prisma.settings.findMany({ where: { group: 'payment' } }));
    const result: Record<string, string> = {};
    settings.forEach(s => { result[s.key] = s.value; });
    res.json({ success: true, data: result });
  } catch (err) {
    console.error('[getPaymentSettings]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

export const createPayment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { planId, method } = req.body;
    if (!planId || !method) {
      res.status(400).json({ success: false, message: 'planId و method مطلوبان' });
      return;
    }
    const plan = await withDb(() => prisma.plan.findUnique({ where: { id: planId } }));
    if (!plan || !plan.isActive) {
      res.status(404).json({ success: false, message: 'الباقة غير موجودة' });
      return;
    }

    const existingActive = await withDb(() =>
      prisma.subscription.findFirst({
        where: { userId: req.user!.id, status: 'ACTIVE', endDate: { gt: new Date() } },
      })
    );
    if (existingActive) {
      res.status(409).json({ success: false, message: 'لديك اشتراك نشط بالفعل' });
      return;
    }

    // Check for already-pending payment for same plan
    const existingPending = await withDb(() =>
      prisma.payment.findFirst({
        where: { userId: req.user!.id, planId, status: 'PENDING' },
      })
    );
    if (existingPending) {
      res.status(409).json({
        success: false,
        message: 'لديك طلب دفع معلّق لهذه الباقة بالفعل، انتظر موافقة الأدمن',
        data: existingPending,
      });
      return;
    }

    const payment = await withDb(() =>
      prisma.payment.create({
        data: { userId: req.user!.id, planId, method, amount: plan.price, status: 'PENDING' },
        include: { plan: true },
      })
    );
    res.status(201).json({ success: true, data: payment });
  } catch (err) {
    console.error('[createPayment]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

export const uploadProof = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { paymentId } = req.params;
    const payment = await withDb(() =>
      prisma.payment.findFirst({
        where: { id: paymentId, userId: req.user!.id, status: 'PENDING' },
      })
    );
    if (!payment) {
      res.status(404).json({ success: false, message: 'الدفع غير موجود' });
      return;
    }
    if (!req.body.imageBase64) {
      res.status(400).json({ success: false, message: 'الصورة مطلوبة' });
      return;
    }

    const imageBase64: string = req.body.imageBase64;

    // Try Cloudinary first; fall back to storing base64 in DB if not configured or upload fails
    let proofImageUrl: string | null = null;
    let proofImageBase64: string | null = null;
    let cloudinaryOk = false;

    try {
      await configureCloudinary();
      const config = cloudinary.config();
      if (config.cloud_name && config.api_key && config.api_secret) {
        const result = await cloudinary.uploader.upload(imageBase64, {
          folder: 'game-event/payment-proofs',
          resource_type: 'image',
        });
        proofImageUrl = result.secure_url;
        cloudinaryOk = true;
      }
    } catch (cloudErr) {
      console.error('[uploadProof] Cloudinary upload failed, falling back to base64:', errMsg(cloudErr));
    }

    if (!cloudinaryOk) {
      // Store base64 directly in DB as fallback so admin can still see the proof
      proofImageBase64 = imageBase64;
    }

    const updated = await withDb(() =>
      prisma.payment.update({
        where: { id: paymentId },
        data: {
          proofImageUrl,
          proofImageBase64,
        },
      })
    );

    res.json({
      success: true,
      data: {
        ...updated,
        proofImageBase64: undefined, // don't send the heavy base64 back to client
      },
    });
  } catch (err) {
    console.error('[uploadProof]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// ── TXID Verify: validates blockchain tx but DOES NOT auto-activate subscription
// Subscription is only activated after admin explicitly approves the payment.
export const verifyTxid = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { paymentId } = req.params;
    const { txid } = req.body;
    if (!txid) {
      res.status(400).json({ success: false, message: 'TXID مطلوب' });
      return;
    }

    const payment = await withDb(() =>
      prisma.payment.findFirst({
        where: { id: paymentId, userId: req.user!.id, method: 'USDT_BEP20', status: 'PENDING' },
        include: { plan: true },
      })
    );
    if (!payment) {
      res.status(404).json({ success: false, message: 'الدفع غير موجود' });
      return;
    }

    // Check TXID not already used
    const usedTxid = await withDb(() => prisma.usedTxid.findUnique({ where: { txid } }));
    if (usedTxid) {
      res.status(409).json({ success: false, message: 'هذا TXID مستخدم مسبقاً' });
      return;
    }

    // Verify on blockchain
    const apiKeyRow = await withDb(() => prisma.settings.findUnique({ where: { key: 'bscscan_api_key' } }));
    const contractRow = await withDb(() => prisma.settings.findUnique({ where: { key: 'usdt_contract_address' } }));
    const apiKey = apiKeyRow?.value || process.env.BSCSCAN_API_KEY || '';
    const contract = contractRow?.value || '0x55d398326f99059fF775485246999027B3197955';

    let txValid = false;
    try {
      const response = await axios.get('https://api.bscscan.com/api', {
        params: {
          module: 'proxy',
          action: 'eth_getTransactionByHash',
          txhash: txid,
          apikey: apiKey,
        },
        timeout: 15000,
      });
      const tx = response.data?.result;
      if (tx && tx.to && tx.to.toLowerCase() === contract.toLowerCase()) {
        txValid = true;
      }
    } catch {
      res.status(502).json({ success: false, message: 'فشل التحقق من البلوكشين، حاول مرة أخرى' });
      return;
    }

    if (!txValid) {
      res.status(400).json({ success: false, message: 'TXID غير صالح أو المعاملة غير موجودة' });
      return;
    }

    // Mark TXID as used and update payment (still PENDING — admin must approve)
    await withDb(() => prisma.usedTxid.create({ data: { txid, userId: req.user!.id } }));
    await withDb(() =>
      prisma.payment.update({
        where: { id: paymentId },
        data: { txid, txidVerified: true },
        // status remains PENDING — admin approval required
      })
    );

    res.json({
      success: true,
      message: 'تم التحقق من TXID بنجاح. سيتم تفعيل اشتراكك بعد مراجعة الأدمن.',
    });
  } catch (err) {
    console.error('[verifyTxid]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};
