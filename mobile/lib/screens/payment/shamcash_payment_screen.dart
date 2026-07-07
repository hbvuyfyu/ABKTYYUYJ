import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

class ShamCashPaymentScreen extends StatefulWidget {
  final String paymentId;
  const ShamCashPaymentScreen({super.key, required this.paymentId});

  @override
  State<ShamCashPaymentScreen> createState() => _ShamCashPaymentScreenState();
}

class _ShamCashPaymentScreenState extends State<ShamCashPaymentScreen> {
  Map<String, dynamic>? _payment;
  Map<String, dynamic>? _settings;
  bool _loading = true;
  final _txNoCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _txNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load payment directly by fetching from payment-history and finding the correct one
      final results = await Future.wait([
        ApiService.get('/users/payment-history'),
        ApiService.get('/settings/payment', auth: false),
      ]);

      if (results[0]['success'] == true) {
        final payments = (results[0]['data'] as List?) ?? [];
        // Find the payment by ID
        for (final p in payments) {
          if ((p as Map)['id'] == widget.paymentId) {
            _payment = p as Map<String, dynamic>;
            break;
          }
        }
        // If not found in history, create a minimal payment object with the ID
        _payment ??= {
          'id': widget.paymentId,
          'method': 'SHAM_CASH',
          'amount': 0,
        };
      }
      if (results[1]['success'] == true) {
        _settings = results[1]['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // Create default payment object on error
      _payment = {
        'id': widget.paymentId,
        'method': 'SHAM_CASH',
        'amount': 0,
      };
    }
    setState(() => _loading = false);
  }

  Future<void> _verifyAndPay() async {
    if (_txNoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أدخل رقم العملية من التطبيق', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    setState(() => _submitting = true);

    try {
      final res = await ApiService.post('/payments/${widget.paymentId}/apisyria/verify', {
        'transactionNo': _txNoCtrl.text.trim(),
      });

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تأكيد الدفع. سيتم تفعيل اشتراكك بعد موافقة الإدارة.', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 3),
        ));
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message']?.toString() ?? 'فشل التحقق', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('خطأ في الاتصال', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
      ));
    }

    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final method = _payment?['method'] as String?;
    final isShamCash = method == 'SHAM_CASH';
    final address = isShamCash
        ? (_settings?['sham_cash_account_address'] ?? _settings?['sham_cash_number'] ?? '')
        : (_settings?['syriatel_cash_number'] ?? '');
    final usdToSpRate = double.tryParse(_settings?['syria_usd_to_sp_rate'] ?? '15000') ?? 15000;
    final amountUsd = _payment?['amount'] as double? ?? 0;
    final amountSp = (amountUsd * usdToSpRate).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(isShamCash ? 'دفع عبر ShamCash' : 'دفع عبر Syriatel Cash'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isShamCash ? Icons.account_balance_wallet_outlined : Icons.phone_android_outlined,
                              color: AppTheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isShamCash ? 'ShamCash' : 'Syriatel Cash',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (address.toString().isNotEmpty) ...[
                          Text(
                            isShamCash ? 'العنوان:' : 'الرقم:',
                            style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    address.toString(),
                                    style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Courier', fontSize: 14),
                                    textDirection: TextDirection.ltr,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: AppTheme.primary, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: address.toString()));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('تم نسخ العنوان', style: TextStyle(fontFamily: 'Cairo')),
                                      backgroundColor: AppTheme.success,
                                      duration: Duration(seconds: 2),
                                    ));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(color: AppTheme.border, height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('المبلغ المطلوب:', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                                Text('\$${amountUsd.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accent, fontFamily: 'Cairo')),
                              ],
                            ),
                            if (!isShamCash)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('بالليرة السورية:', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                                  Text('$amountSp S.P', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.warning, fontFamily: 'Cairo')),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                            const SizedBox(width: 8),
                            const Text('خطوات الدفع:', style: TextStyle(color: AppTheme.warning, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '1. افتح تطبيق ${isShamCash ? "ShamCash" : "Syriatel Cash"}\n'
                          '2. قم بتحويل المبلغ المطلوب للعنوان أعلاه\n'
                          '3. بعد التحويل، انسخ رقم العملية من التطبيق\n'
                          '4. أدخل رقم العملية أدناه واضغط "تأكيد"\n'
                          '5. سيتم تفعيل اشتراكك بعد موافقة الإدارة',
                          style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13, height: 1.8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Transaction number input
                  const Text('رقم العملية (Transaction No):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _txNoCtrl,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'رقم العملية',
                      hintText: 'أدخل رقم العملية من التطبيق',
                      prefixIcon: Icon(Icons.tag, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    onPressed: _submitting ? null : _verifyAndPay,
                    isLoading: _submitting,
                    text: 'تأكيد الدفع',
                  ),
                ],
              ),
            ),
    );
  }
}
