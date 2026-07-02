import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.get('/admin/users'),
        ApiService.get('/admin/plans'),
      ]);
      if (results[0]['success'] == true) {
        _users = (results[0]['data'] as List?) ?? [];
      } else {
        _error = results[0]['message']?.toString() ?? 'فشل تحميل المستخدمين';
      }
      if (results[1]['success'] == true) {
        _plans = (results[1]['data'] as List?) ?? [];
      }
    } catch (_) {
      _error = 'خطأ في الاتصال بالسيرفر';
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleUser(String userId, bool current) async {
    try {
      await ApiService.patch('/admin/users/$userId/toggle', {});
      _loadData();
    } catch (_) {}
  }

  Future<void> _activateSubscription(String userId) async {
    if (_plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد باقات متاحة', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.warning));
      return;
    }
    String? selectedPlanId = _plans[0]['id'] as String?;
    await showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: const Text('تفعيل اشتراك', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary)),
      content: StatefulBuilder(builder: (ctx, setS) => DropdownButton<String>(
        value: selectedPlanId,
        dropdownColor: AppTheme.cardBg,
        style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary),
        items: _plans.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(
          value: p['id'] as String,
          child: Text(p['name'] as String),
        )).toList(),
        onChanged: (v) => setS(() => selectedPlanId = v),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              final res = await ApiService.post('/admin/subscriptions/activate', {
                'userId': userId,
                'planId': selectedPlanId,
              });
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل الاشتراك', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success));
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'فشل', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
              }
            } catch (_) {}
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
          child: const Text('تفعيل', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
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
                  child: _users.isEmpty
                      ? const Center(child: Text('لا يوجد مستخدمون', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (_, i) {
                            final u = _users[i] as Map<String, dynamic>;
                            final subs = u['subscriptions'] as List?;
                            final hasSub = subs != null && subs.isNotEmpty;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    CircleAvatar(backgroundColor: AppTheme.primary.withOpacity(0.2), child: const Icon(Icons.person, color: AppTheme.primary, size: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(u['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
                                      Text(u['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12), overflow: TextOverflow.ellipsis),
                                    ])),
                                    Switch(value: u['isActive'] == true, onChanged: (_) => _toggleUser(u['id'] as String, u['isActive'] == true), activeColor: AppTheme.success),
                                  ]),
                                  if (hasSub) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                      child: Text('مشترك: ${(subs![0] as Map)['plan']?['name'] ?? ''}', style: const TextStyle(color: AppTheme.success, fontFamily: 'Cairo', fontSize: 12)),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: () => _activateSubscription(u['id'] as String),
                                    icon: const Icon(Icons.add_card, size: 16, color: AppTheme.primary),
                                    label: const Text('تفعيل اشتراك', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary, fontSize: 13)),
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
