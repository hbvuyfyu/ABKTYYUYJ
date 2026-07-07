import { Response } from 'express';
import prisma, { withDb } from '../utils/prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import axios from 'axios';

function errMsg(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

// OxaPay API base URL
const OXAPAY_API_URL = 'https://api.oxapay.com';

// Get OxaPay API key from settings
const getOxapayApiKey = async (): Promise<string | null> => {
  const setting = await withDb(() =>
    prisma.settings.findUnique({ where: { key: 'oxapay_merchant_api_key' } })
  );
  return setting?.value || null;
};

// Create a White Label payment for USDT
export const createOxapayPayment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { paymentId } = req.params;

    // Get the payment
    const payment = await withDb(() =>
      prisma.payment.findFirst({
        where: { id: paymentId, userId: req.user!.id, status: 'PENDING', method: 'USDT_BEP20' },
        include: { plan: true },
      })
    );

    if (!payment) {
      res.status(404).json({ success: false, message: 'الدفع غير موجود أو تمت معالجته' });
      return;
    }

    // Get OxaPay API key
    const apiKey = await getOxapayApiKey();
    if (!apiKey) {
      res.status(500).json({ success: false, message: 'إعدادات OxaPay غير مكتملة' });
      return;
    }

    // Create white label payment with OxaPay
    const callbackUrl = `${process.env.BASE_URL || ''}/api/payments/oxapay/callback`;
    const returnUrl = `${process.env.APP_DEEP_LINK || 'vipapp://payment-callback'}?paymentId=${paymentId}`;

    const response = await axios.post(
      `${OXAPAY_API_URL}/payment/whitelabel`,
      {
        merchant_api_key: apiKey,
        amount: payment.amount.toString(),
        currency: 'USD',
        pay_currency: 'USDTTRC20', // USDT on TRON network (fast and low fees)
        order_id: payment.id,
        callback_url: callbackUrl,
        return_url: returnUrl,
        description: `VIP Subscription - ${payment.plan?.name || 'Plan'}`,
        email: req.user?.email || '',
      },
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000,
      }
    );

    const data = response.data;

    if (data.result !== 100) {
      console.error('[OxaPay] Error:', data);
      res.status(400).json({
        success: false,
        message: data.message || 'فشل إنشاء رابط الدفع'
      });
      return;
    }

    // Update payment with OxaPay track ID
    await withDb(() =>
      prisma.payment.update({
        where: { id: paymentId },
        data: {
          oxapayTrackId: data.track_id,
          oxapayPaymentUrl: data.payment_url,
        },
      })
    );

    res.json({
      success: true,
      data: {
        paymentUrl: data.payment_url,
        trackId: data.track_id,
        address: data.address,
        amount: payment.amount,
        payAmount: data.pay_amount,
        payCurrency: data.pay_currency,
      },
    });
  } catch (err) {
    console.error('[createOxapayPayment]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في الاتصال بـ OxaPay' });
  }
};

// Handle OxaPay callback (server-side verification)
// Auto-approves and activates subscription when OxaPay confirms payment
export const oxapayCallback = async (req: any, res: Response): Promise<void> => {
  try {
    const data = req.body;
    console.log('[OxaPay Callback]', JSON.stringify(data, null, 2));

    // Verify the payment status
    if (data.status !== 'Paid') {
      res.status(200).send('OK');
      return;
    }

    const orderId = data.order_id || data.track_id;
    const trackId = data.track_id;

    // Find the payment
    const payment = await withDb(() =>
      prisma.payment.findFirst({
        where: {
          OR: [
            { id: orderId },
            { oxapayTrackId: trackId },
          ],
          status: 'PENDING',
        },
        include: { plan: true },
      })
    );

    if (!payment) {
      console.error('[OxaPay Callback] Payment not found:', orderId, trackId);
      res.status(200).send('OK');
      return;
    }

    // Verify with OxaPay API (double-check)
    const apiKey = await getOxapayApiKey();
    if (apiKey) {
      try {
        const verifyRes = await axios.get(
          `${OXAPAY_API_URL}/payment/${trackId}`,
          {
            headers: { 'X-Merchant-Api-Key': apiKey },
            timeout: 15000,
          }
        );
        const verifyData = verifyRes.data;

        if (verifyData.result !== 100 || verifyData.status !== 'Paid') {
          console.error('[OxaPay Callback] Verification failed:', verifyData);
          res.status(200).send('OK');
          return;
        }
      } catch (verifyErr) {
        console.error('[OxaPay Callback] Verification error:', errMsg(verifyErr));
      }
    }

    // Cancel any existing active subscription for this user
    await withDb(() =>
      prisma.subscription.updateMany({
        where: { userId: payment.userId, status: 'ACTIVE' },
        data: { status: 'CANCELLED' },
      })
    );

    // Create subscription - AUTO-APPROVED for OxaPay
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

    // Update payment status - AUTO-APPROVED
    await withDb(() =>
      prisma.payment.update({
        where: { id: payment.id },
        data: {
          status: 'APPROVED',
          subscriptionId: subscription.id,
          oxapayTxId: data.tx_id || data.txId || data.hash,
          txidVerified: true,
          userConfirmedAt: new Date(), // Mark as confirmed since OxaPay verified
          reviewedAt: new Date(),
          adminNotes: 'Auto-approved via OxaPay callback - payment confirmed by OxaPay',
        },
      })
    );

    // Log the approval
    await withDb(() =>
      prisma.adminLog.create({
        data: {
          adminId: payment.userId, // User self-approved via payment
          targetId: payment.userId,
          action: 'PAYMENT_AUTO_APPROVED_OXAPAY',
          details: `Payment ${payment.id} auto-approved via OxaPay. Track: ${trackId}`,
        },
      })
    );

    res.status(200).send('OK');
  } catch (err) {
    console.error('[oxapayCallback]', errMsg(err));
    res.status(200).send('OK');
  }
};

// Check OxaPay payment status (for polling)
// Auto-approves when OxaPay confirms payment
export const checkOxapayStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { paymentId } = req.params;

    const payment = await withDb(() =>
      prisma.payment.findFirst({
        where: { id: paymentId, userId: req.user!.id },
      })
    );

    if (!payment) {
      res.status(404).json({ success: false, message: 'الدفع غير موجود' });
      return;
    }

    if (payment.status !== 'PENDING') {
      res.json({ success: true, data: { status: payment.status, approved: payment.status === 'APPROVED' } });
      return;
    }

    // If still pending, check with OxaPay
    if (!payment.oxapayTrackId) {
      res.json({ success: true, data: { status: 'PENDING', paymentUrl: payment.oxapayPaymentUrl } });
      return;
    }

    const apiKey = await getOxapayApiKey();
    if (!apiKey) {
      res.json({ success: true, data: { status: 'PENDING' } });
      return;
    }

    try {
      const verifyRes = await axios.get(
        `${OXAPAY_API_URL}/payment/${payment.oxapayTrackId}`,
        {
          headers: { 'X-Merchant-Api-Key': apiKey },
          timeout: 15000,
        }
      );

      const verifyData = verifyRes.data;
      const isPaid = verifyData.status === 'Paid';

      // If paid, approve the payment automatically
      if (isPaid && payment.status === 'PENDING') {
        // Cancel any existing active subscription
        await withDb(() =>
          prisma.subscription.updateMany({
            where: { userId: payment.userId, status: 'ACTIVE' },
            data: { status: 'CANCELLED' },
          })
        );

        // Create subscription - AUTO-APPROVED
        const startDate = new Date();
        const endDate = new Date();
        const plan = await withDb(() => prisma.plan.findUnique({ where: { id: payment.planId } }));
        endDate.setDate(endDate.getDate() + (plan?.durationDays || 30));

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

        // Update payment - AUTO-APPROVED
        await withDb(() =>
          prisma.payment.update({
            where: { id: paymentId },
            data: {
              status: 'APPROVED',
              subscriptionId: subscription.id,
              txidVerified: true,
              userConfirmedAt: new Date(), // Mark as confirmed since OxaPay verified
              reviewedAt: new Date(),
              adminNotes: 'Auto-approved via OxaPay status check',
            },
          })
        );

        res.json({ success: true, data: { status: 'APPROVED', approved: true } });
      } else {
        res.json({
          success: true,
          data: {
            status: payment.status,
            paid: isPaid,
            oxapayStatus: verifyData.status
          }
        });
      }
    } catch (checkErr) {
      console.error('[checkOxapayStatus] Error:', errMsg(checkErr));
      res.json({ success: true, data: { status: payment.status } });
    }
  } catch (err) {
    console.error('[checkOxapayStatus]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في التحقق' });
  }
};
