import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

class PaymentScreen extends StatefulWidget {
  final String planId;
  const PaymentScreen({super.key, required this.planId});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Map<String, dynamic>? _plan;
  bool _loading = true;
  String? _selectedMethod;
  bool _processing = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final res = await ApiService.get('/plans', auth: false);
      if (res['success'] == true) {
        final plans = (res['data'] as List?) ?? [];
        final plan = plans.firstWhere(
          (p) => (p as Map)['id'] == widget.planId,
          orElse: () => null,
        );
        setState(() => _plan = plan as Map<String, dynamic>?);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _proceed() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اختر طريقة الدفع أولاً', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    setState(() => _processing = true);
    try {
      final res = await ApiService.post('/payments', {
        'planId': widget.planId,
        'method': _selectedMethod,
      });
      if (!mounted) return;
      if (res['success'] == true) {
        final paymentId = (res['data'] as Map<String, dynamic>)['id'] as String;
        if (_selectedMethod == 'USDT_BEP20') {
          context.push('/payment/$paymentId/usdt');
        } else {
          context.push('/payment/$paymentId/proof');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message']?.toString() ?? 'خطأ في إنشاء طلب الدفع', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('خطأ في الاتصال بالسيرفر', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
      ));
    }
    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الدفع'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSummary(), const SizedBox(height: 24), _buildMethods(), const SizedBox(height: 24),
              GradientButton(onPressed: _processing ? null : _proceed, isLoading: _processing, text: 'متابعة'),
            ])),
    );
  }

  Widget _buildSummary() {
    if (_plan == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_plan!['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
          Text('${_plan!['durationDays']} يوم | ${_plan!['dailyOperations']} عملية/يوم', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
        ])),
        Text('\$${_plan!['price']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.accent, fontFamily: 'Cairo')),
      ]),
    );
  }

  Widget _buildMethods() {
    final methods = [
      {'value': 'SHAM_CASH', 'label': 'Sham Cash', 'icon': Icons.account_balance_wallet_outlined, 'color': AppTheme.primary},
      {'value': 'SYRIATEL_CASH', 'label': 'Syriatel Cash', 'icon': Icons.phone_android_outlined, 'color': AppTheme.success},
      {'value': 'USDT_BEP20', 'label': 'USDT BEP20', 'icon': Icons.currency_bitcoin, 'color': AppTheme.accent},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('طريقة الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
      const SizedBox(height: 12),
      ...methods.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => setState(() => _selectedMethod = m['value'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedMethod == m['value'] ? (m['color'] as Color).withOpacity(0.15) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _selectedMethod == m['value'] ? m['color'] as Color : AppTheme.border, width: _selectedMethod == m['value'] ? 2 : 1),
            ),
            child: Row(children: [
              Icon(m['icon'] as IconData, color: m['color'] as Color, size: 28), const SizedBox(width: 16),
              Text(m['label'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _selectedMethod == m['value'] ? AppTheme.textPrimary : AppTheme.textSecondary, fontFamily: 'Cairo')),
              const Spacer(),
              if (_selectedMethod == m['value']) Icon(Icons.check_circle, color: m['color'] as Color, size: 24),
            ]),
          ),
        ),
      )),
    ]);
  }
}
