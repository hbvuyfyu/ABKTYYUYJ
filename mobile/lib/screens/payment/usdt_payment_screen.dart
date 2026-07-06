import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

class UsdtPaymentScreen extends StatefulWidget {
  final String paymentId;
  const UsdtPaymentScreen({super.key, required this.paymentId});
  @override
  State<UsdtPaymentScreen> createState() => _UsdtPaymentScreenState();
}

class _UsdtPaymentScreenState extends State<UsdtPaymentScreen> {
  Map<String, dynamic>? _payment;
  Map<String, dynamic>? _settings;
  bool _loading = true;
  final _txidCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadData(); }
  @override
  void dispose() { _txidCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.get('/users/payment-history'),
        ApiService.get('/settings/payment', auth: false),
      ]);

      if (results[0]['success'] == true) {
        final payments = (results[0]['data'] as List?) ?? [];
        for (final p in payments) {
          if ((p as Map)['id'] == widget.paymentId) {
            _payment = p as Map<String, dynamic>;
            break;
          }
        }
        _payment ??= {
          'id': widget.paymentId,
          'method': 'USDT_BEP20',
          'amount': 0,
        };
      }
      if (results[1]['success'] == true) {
        _settings = results[1]['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      _payment = {
        'id': widget.paymentId,
        'method': 'USDT_BEP20',
        'amount': 0,
      };
    }
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_txidCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أدخل TXID أولاً', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await ApiService.post('/payments/${widget.paymentId}/verify-txid', {'txid': _txidCtrl.text.trim()});
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم التحقق من TXID بنجاح! سيتم تفعيل الاشتراك بعد مراجعة الأدمن.', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 3),
        ));
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/');
        });
      } else {
        setState(() {
          _error = res['message']?.toString() ?? 'فشل التحقق';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_error!, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'خطأ في الاتصال';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('فشل الإرسال', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
      ));
    }

    setState(() => _submitting = false);
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم نسخ العنوان', style: TextStyle(fontFamily: 'Cairo')),
      backgroundColor: AppTheme.success,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final address = _settings?['usdt_address'] ?? _settings?['usdt_bep20_address'] ?? '';
    final amount = _payment?['amount'] ?? 0;
    final amountStr = amount is double ? amount.toStringAsFixed(2) : amount.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('دفع USDT (BEP20)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment info card
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.currency_bitcoin, color: AppTheme.accent, size: 28),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'USDT (BEP20)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Wallet address section
                        const Text(
                          'عنوان المحفظة (BEP20):',
                          style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  address.toString().isNotEmpty ? address.toString() : 'لم يتم تكوين العنوان',
                                  style: TextStyle(
                                    color: address.toString().isNotEmpty ? AppTheme.textPrimary : AppTheme.textHint,
                                    fontFamily: 'Courier',
                                    fontSize: 13,
                                  ),
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                              if (address.toString().isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.copy, color: AppTheme.primary, size: 22),
                                  onPressed: () => _copyAddress(address.toString()),
                                ),
                            ],
                          ),
                        ),

                        const Divider(color: AppTheme.border, height: 32),

                        // Amount section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('المبلغ المطلوب:', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                                const SizedBox(height: 4),
                                Text(
                                  '\$$amountStr USDT',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accent, fontFamily: 'Cairo'),
                                ),
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
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.accent, size: 20),
                            const SizedBox(width: 8),
                            const Text('خطوات الدفع:', style: TextStyle(color: AppTheme.accent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. انسخ عنوان المحفظة أعلاه\n'
                          '2. افتح محفظتك (Trust Wallet, MetaMask, etc.)\n'
                          '3. أرسل المبلغ المطلوب إلى العنوان\n'
                          '4. بعد التحويل، انسخ TXID من المعاملة\n'
                          '5. أدخل TXID أدناه واضغط "تأكيد"',
                          style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13, height: 1.8),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TXID input
                  const Text(
                    'Transaction ID (TXID):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _txidCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'TXID',
                      hintText: '0x...',
                      prefixIcon: Icon(Icons.tag, color: AppTheme.primary),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  GradientButton(
                    onPressed: _submitting ? null : _submit,
                    isLoading: _submitting,
                    text: 'تأكيد الدفع',
                  ),
                ],
              ),
            ),
    );
  }
}
