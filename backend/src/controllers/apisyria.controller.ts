import { Response } from 'express';
import prisma, { withDb } from '../utils/prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import axios from 'axios';

function errMsg(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

// API Syria base URL
const APISYRIA_BASE_URL = 'https://apisyria.com/api/v1';

// Get API Syria settings
const getApiSyriaSettings = async (): Promise<{ apiKey: string | null; accountAddress: string | null }> => {
  const [apiKeySetting, addressSetting] = await Promise.all([
    withDb(() => prisma.settings.findUnique({ where: { key: 'api_syria_api_key' } })),
    withDb(() => prisma.settings.findUnique({ where: { key: 'api_syria_account_address' } })),
  ]);
  return {
    apiKey: apiKeySetting?.value || null,
    accountAddress: addressSetting?.value || null,
  };
};

// Get API Syria headers
const getApiHeaders = (apiKey: string) => ({
  'X-Api-Key': apiKey,
  'Content-Type': 'application/x-www-form-urlencoded',
});

// Verify ShamCash transaction by transaction number
// User confirms with transaction number, then admin reviews
export const verifyShamCashTransaction = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { paymentId } = req.params;
    const { transactionNo } = req.body;

    if (!transactionNo) {
      res.status(400).json({ success: false, message: 'رقم العملية مطلوب' });
      return;
    }

    // Get the payment
    const payment = await withDb(() =>
      prisma.payment.findFirst({
        where: { id: paymentId, userId: req.user!.id, status: 'PENDING' },
        include: { plan: true },
      })
    );

    if (!payment) {
      res.status(404).json({ success: false, message: 'الدفع غير موجود أو تمت معالجته' });
      return;
    }

    if (payment.method !== 'SHAM_CASH' && payment.method !== 'SYRIATEL_CASH') {
      res.status(400).json({ success: false, message: 'هذه الطريقة غير مدعومة للتحقق التلقائي' });
      return;
    }

    // Check if transaction was already used
    const usedTx = await withDb(() =>
      prisma.usedTxid.findUnique({ where: { txid: transactionNo } })
    );
    if (usedTx) {
      res.status(400).json({ success: false, message: 'هذا رقم العملية مستخدم مسبقاً' });
      return;
    }

    // Mark transaction as used and mark payment as user confirmed
    // User confirmed - will be sent to admin for review
    await withDb(() =>
      prisma.usedTxid.create({
        data: { txid: transactionNo, userId: req.user!.id },
      })
    );

    await withDb(() =>
      prisma.payment.update({
        where: { id: paymentId },
        data: {
          txid: transactionNo,
          txidVerified: true,
          userConfirmedAt: new Date(), // Mark as user confirmed - now admin can see it
        },
      })
    );

    // Log
    await withDb(() =>
      prisma.adminLog.create({
        data: {
          adminId: payment.userId,
          targetId: payment.userId,
          action: 'PAYMENT_USER_CONFIRMED',
          details: `Payment ${paymentId} user confirmed. TX: ${transactionNo}`,
        },
      })
    );

    res.json({
      success: true,
      message: 'تم تأكيد الدفع. سيتم تفعيل اشتراكك بعد موافقة الإدارة.',
    });
  } catch (err) {
    console.error('[verifyShamCashTransaction]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في التحقق' });
  }
};

// Get Syriatel Cash recent transactions (for manual verification by admin)
export const getSyriatelHistory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { days } = req.query;

    const { apiKey } = await getApiSyriaSettings();
    const gsmSetting = await withDb(() =>
      prisma.settings.findUnique({ where: { key: 'syriatel_cash_gsm' } })
    );

    if (!apiKey || !gsmSetting?.value) {
      res.status(500).json({ success: false, message: 'إعدادات غير مكتملة' });
      return;
    }

    const response = await axios.get(APISYRIA_BASE_URL, {
      params: {
        resource: 'syriatelcash',
        action: 'history',
        api_key: apiKey,
        gsm: gsmSetting.value,
        days: days || 7,
      },
      timeout: 15000,
    });

    res.json({ success: true, data: response.data });
  } catch (err) {
    console.error('[getSyriatelHistory]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في جلب السجل' });
  }
};

// Get ShamCash logs (for manual verification by admin)
export const getShamCashLogs = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { apiKey, accountAddress } = await getApiSyriaSettings();

    if (!apiKey || !accountAddress) {
      res.status(500).json({ success: false, message: 'إعدادات غير مكتملة' });
      return;
    }

    const response = await axios.get(APISYRIA_BASE_URL, {
      params: {
        resource: 'shamcash',
        action: 'logs',
        api_key: apiKey,
        account_address: accountAddress,
      },
      timeout: 15000,
    });

    res.json({ success: true, data: response.data });
  } catch (err) {
    console.error('[getShamCashLogs]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في جلب السجل' });
  }
};
