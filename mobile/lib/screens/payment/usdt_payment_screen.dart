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
        _payment = payments.firstWhere(
          (p) => (p as Map)['id'] == widget.paymentId,
          orElse: () => null,
        ) as Map<String, dynamic>?;
      }
      if (results[1]['success'] == true) {
        _settings = results[1]['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_txidCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل TXID أولاً', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.warning));
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiService.post('/payments/${widget.paymentId}/verify-txid', {'txid': _txidCtrl.text.trim()});
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحقق وتفعيل الاشتراك', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success));
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'فشل التحقق', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الإرسال', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final address = _settings?['usdt_address'] ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('دفع USDT BEP20'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop())),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('عنوان المحفظة (BEP20)', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(address.toString(), style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'Courier'), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.copy, color: AppTheme.primary, size: 20), onPressed: () {
                    Clipboard.setData(ClipboardData(text: address.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ', style: TextStyle(fontFamily: 'Cairo')), duration: Duration(seconds: 1)));
                  }),
                ]),
                const Divider(color: AppTheme.border),
                Text('المبلغ: \$${_payment?['amount'] ?? ''}', style: const TextStyle(color: AppTheme.accent, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18)),
              ])),
              const SizedBox(height: 24),
              const Text('أدخل TXID بعد إتمام التحويل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
              const SizedBox(height: 12),
              TextField(controller: _txidCtrl, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'Transaction ID (TXID)', prefixIcon: Icon(Icons.tag, color: AppTheme.primary))),
              const SizedBox(height: 32),
              GradientButton(onPressed: _submitting ? null : _submit, isLoading: _submitting, text: 'إرسال TXID'),
            ])),
    );
  }
}
