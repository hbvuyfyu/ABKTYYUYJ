import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});
  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  List<dynamic> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadPlans(); }

  Future<void> _loadPlans() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/plans');
      if (res['success'] == true) {
        setState(() => _plans = (res['data'] as List?) ?? []);
      } else {
        setState(() => _error = res['message']?.toString() ?? 'فشل تحميل الباقات');
      }
    } catch (_) {
      setState(() => _error = 'خطأ في الاتصال بالسيرفر');
    }
    setState(() => _loading = false);
  }

  void _showPlanDialog({Map<String, dynamic>? plan}) {
    final isEdit = plan != null;
    final nameCtrl = TextEditingController(text: plan?['name'] ?? '');
    final nameArCtrl = TextEditingController(text: plan?['nameAr'] ?? '');
    final priceCtrl = TextEditingController(text: plan != null ? '${plan['price']}' : '');
    final daysCtrl = TextEditingController(text: plan != null ? '${plan['durationDays']}' : '');
    final opsCtrl = TextEditingController(text: plan != null ? '${plan['dailyOperations']}' : '');
    bool isActive = plan?['isActive'] != false;

    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: Text(isEdit ? 'تعديل: ${plan!['name']}' : 'إضافة باقة جديدة', style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary)),
      content: StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم (English)')),
        const SizedBox(height: 12),
        TextField(controller: nameArCtrl, decoration: const InputDecoration(labelText: 'الاسم (عربي)')),
        const SizedBox(height: 12),
        TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر (\$)')),
        const SizedBox(height: 12),
        TextField(controller: daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المدة (أيام)')),
        const SizedBox(height: 12),
        TextField(controller: opsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العمليات اليومية')),
        const SizedBox(height: 12),
        SwitchListTile(
          value: isActive,
          onChanged: (v) => setS(() => isActive = v),
          title: const Text('مفعّل', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary)),
          activeColor: AppTheme.success,
          tileColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
        ),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final body = {
              'name': nameCtrl.text,
              'nameAr': nameArCtrl.text,
              'price': double.tryParse(priceCtrl.text) ?? 0,
              'durationDays': int.tryParse(daysCtrl.text) ?? 30,
              'dailyOperations': int.tryParse(opsCtrl.text) ?? 10,
              'isActive': isActive,
            };
            try {
              final res = isEdit
                  ? await ApiService.put('/admin/plans/${plan!['id']}', body)
                  : await ApiService.post('/admin/plans', body);
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'تم تحديث الباقة' : 'تم إضافة الباقة', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success));
                _loadPlans();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'فشل', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
              }
            } catch (_) {}
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
          child: Text(isEdit ? 'حفظ' : 'إضافة', style: const TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الباقات'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.accent), onPressed: () => _showPlanDialog()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadPlans, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
                ]))
              : _plans.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.card_membership_outlined, color: AppTheme.textHint, size: 64),
                      const SizedBox(height: 16),
                      const Text('لا توجد باقات بعد', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: () => _showPlanDialog(), icon: const Icon(Icons.add), label: const Text('إضافة باقة', style: TextStyle(fontFamily: 'Cairo'))),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadPlans,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _plans.length,
                        itemBuilder: (_, i) {
                          final p = _plans[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(p['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo'))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: p['isActive'] == true ? AppTheme.success.withOpacity(0.15) : AppTheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Text(p['isActive'] == true ? 'مفعّل' : 'معطّل', style: TextStyle(color: p['isActive'] == true ? AppTheme.success : AppTheme.error, fontFamily: 'Cairo', fontSize: 12)),
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [
                                  _chip(Icons.attach_money, '\$${p['price']}', AppTheme.accent),
                                  const SizedBox(width: 8),
                                  _chip(Icons.calendar_today_outlined, '${p['durationDays']} يوم', AppTheme.primary),
                                  const SizedBox(width: 8),
                                  _chip(Icons.bolt_outlined, '${p['dailyOperations']} عملية', AppTheme.success),
                                ]),
                                const SizedBox(height: 16),
                                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                                  onPressed: () => _showPlanDialog(plan: p),
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                                  label: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary)),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primary), minimumSize: const Size(0, 44)),
                                )),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}
