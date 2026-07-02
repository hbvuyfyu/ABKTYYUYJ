import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});
  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pending = [];
  List<dynamic> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); _loadData(); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.get('/admin/payments/pending'),
        ApiService.get('/admin/payments'),
      ]);
      if (results[0]['success'] == true) _pending = (results[0]['data'] as List?) ?? [];
      if (results[1]['success'] == true) _all = (results[1]['data'] as List?) ?? [];
      if (results[0]['success'] != true) _error = results[0]['message']?.toString();
    } catch (_) {
      _error = 'خطأ في الاتصال بالسيرفر';
    }
    setState(() => _loading = false);
  }

  Future<void> _approve(String paymentId) async {
    try {
      final res = await ApiService.post('/admin/payments/$paymentId/approve', {});
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم قبول الدفع وتفعيل الاشتراك', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success));
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'فشل', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _reject(String paymentId) async {
    final notesCtrl = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Text('رفض الدفع', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary)),
      content: TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              final res = await ApiService.post('/admin/payments/$paymentId/reject', {'adminNotes': notesCtrl.text});
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض الدفع', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.warning));
                _loadData();
              }
            } catch (_) {}
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, minimumSize: const Size(0, 40)),
          child: const Text('رفض', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المدفوعات${_pending.isNotEmpty ? " (${_pending.length} معلق)" : ""}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontFamily: 'Cairo'),
          tabs: [Tab(text: 'معلقة (${_pending.length})'), const Tab(text: 'الكل')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildList(_pending, showActions: true), _buildList(_all, showActions: false)],
                  ),
                ),
    );
  }

  Widget _buildList(List<dynamic> items, {required bool showActions}) {
    if (items.isEmpty) return const Center(child: Text('لا توجد بيانات', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildCard(items[i] as Map<String, dynamic>, showActions: showActions),
    );
  }

  Widget _buildCard(Map<String, dynamic> p, {required bool showActions}) {
    final status = p['status'] as String;
    final statusColor = status == 'APPROVED' ? AppTheme.success : status == 'REJECTED' ? AppTheme.error : AppTheme.warning;
    final statusLabel = status == 'APPROVED' ? 'مقبول' : status == 'REJECTED' ? 'مرفوض' : 'معلق';
    final user = p['user'] as Map<String, dynamic>?;
    final plan = p['plan'] as Map<String, dynamic>?;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?['email'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo', fontSize: 13)),
              Text('${plan?['name'] ?? ''} - ${_fmtMethod(p['method'] as String? ?? '')}', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$${p['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text(statusLabel, style: TextStyle(color: statusColor, fontFamily: 'Cairo', fontSize: 11))),
            ]),
          ]),
          if (showActions && status == 'PENDING') ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: () => _approve(p['id'] as String), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size(0, 40)), child: const Text('قبول', style: TextStyle(fontFamily: 'Cairo')))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => _reject(p['id'] as String), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error), minimumSize: const Size(0, 40)), child: const Text('رفض', style: TextStyle(color: AppTheme.error, fontFamily: 'Cairo')))),
            ]),
          ],
        ]),
      ),
    );
  }

  String _fmtMethod(String m) => m == 'SHAM_CASH' ? 'Sham Cash' : m == 'SYRIATEL_CASH' ? 'Syriatel Cash' : 'USDT BEP20';
}
