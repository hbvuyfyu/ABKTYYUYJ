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

    // Get API Syria settings
    const { apiKey, accountAddress } = await getApiSyriaSettings();
    if (!apiKey) {
      res.status(500).json({ success: false, message: 'إعدادات API Syria غير مكتملة' });
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

    let verified = false;
    let amount = 0;

    if (payment.method === 'SHAM_CASH') {
      // Search ShamCash transaction
      if (!accountAddress) {
        res.status(500).json({ success: false, message: 'عنوان حساب ShamCash غير محدد' });
        return;
      }

      try {
        const response = await axios.get(APISYRIA_BASE_URL, {
          params: {
            resource: 'shamcash',
            action: 'search_transaction',
            api_key: apiKey,
            account_address: accountAddress,
            transaction_no: transactionNo,
          },
          timeout: 15000,
        });

        const data = response.data;
        if (data.found === true && data.transaction) {
          // Verify amount
          const txAmount = parseFloat(data.transaction.amount || data.transaction.Amount || '0');
          const expectedAmount = payment.amount;

          // Allow small difference due to currency conversion
          if (Math.abs(txAmount - expectedAmount) < 0.5) {
            verified = true;
            amount = txAmount;
          }
        }
      } catch (apiErr) {
        console.error('[API Syria] Error:', errMsg(apiErr));
        res.status(502).json({ success: false, message: 'فشل الاتصال بـ API Syria' });
        return;
      }
    } else if (payment.method === 'SYRIATEL_CASH') {
      // Search Syriatel Cash transaction - need gsm number
      const gsmSetting = await withDb(() =>
        prisma.settings.findUnique({ where: { key: 'syriatel_cash_gsm' } })
      );
      if (!gsmSetting?.value) {
        res.status(500).json({ success: false, message: 'رقم Syriatel Cash غير محدد' });
        return;
      }

      try {
        const response = await axios.get(APISYRIA_BASE_URL, {
          params: {
            resource: 'syriatelcash',
            action: 'search_transaction',
            api_key: apiKey,
            gsm: gsmSetting.value,
            transaction_no: transactionNo,
            days: 7, // Search last 7 days
          },
          timeout: 15000,
        });

        const data = response.data;
        if (data.found === true && data.transaction) {
          const txAmount = parseFloat(data.transaction.amount || data.transaction.Amount || '0');
          const txSp = data.transaction.SP || data.transaction.sp || '';
          // Verify amount (SP to USD conversion based on settings)
          const usdSetting = await withDb(() =>
            prisma.settings.findUnique({ where: { key: 'syria_usd_to_sp_rate' } })
          );
          const rate = parseFloat(usdSetting?.value || '15000'); // Default 15000 SP per USD
          const txUsdAmount = txAmount / rate;

          if (Math.abs(txUsdAmount - payment.amount) < 0.5) {
            verified = true;
            amount = txAmount;
          }
        }
      } catch (apiErr) {
        console.error('[API Syria] Syriatel Error:', errMsg(apiErr));
        res.status(502).json({ success: false, message: 'فشل الاتصال بـ API Syria' });
        return;
      }
    }

    if (!verified) {
      res.status(400).json({
        success: false,
        message: 'لم يتم العثور على عملية مطابقة. تأكد من رقم العملية والمبلغ.'
      });
      return;
    }

    // Mark transaction as used
    await withDb(() =>
      prisma.usedTxid.create({
        data: { txid: transactionNo, userId: req.user!.id },
      })
    );

    // Cancel any existing active subscription
    await withDb(() =>
      prisma.subscription.updateMany({
        where: { userId: payment.userId, status: 'ACTIVE' },
        data: { status: 'CANCELLED' },
      })
    );

    // Create subscription
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + (payment.plan?.durationDays || 30));

    const subscription = await withDb(() =>
      prisma.subscription.create({
        data: {
          userId: payment.userId,
          planId: payment.planId,
          status: 'ACTIVE',
          startDate,
          endDate,
        },
      })
    );

    // Update payment status
    await withDb(() =>
      prisma.payment.update({
        where: { id: paymentId },
        data: {
          status: 'APPROVED',
          subscriptionId: subscription.id,
          txid: transactionNo,
          txidVerified: true,
          reviewedAt: new Date(),
          adminNotes: `Auto-approved via API Syria. Amount: ${amount}`,
        },
      })
    );

    // Log
    await withDb(() =>
      prisma.adminLog.create({
        data: {
          adminId: payment.userId,
          targetId: payment.userId,
          action: 'PAYMENT_AUTO_APPROVED_APISYRIA',
          details: `Payment ${paymentId} auto-approved via API Syria. TX: ${transactionNo}`,
        },
      })
    );

    res.json({
      success: true,
      message: 'تم تأكيد الدفع وتفعيل الاشتراك بنجاح',
      data: { subscriptionId: subscription.id, endDate },
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
