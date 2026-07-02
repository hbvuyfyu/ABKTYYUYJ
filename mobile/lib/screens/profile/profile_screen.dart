import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _payments = [];
  List<dynamic> _subscriptions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); _loadData(); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/users/payment-history'),
        ApiService.get('/users/subscription-history'),
      ]);
      if (results[0]['success'] == true) _payments = (results[0]['data'] as List?) ?? [];
      if (results[1]['success'] == true) _subscriptions = (results[1]['data'] as List?) ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sub = context.watch<SubscriptionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/')),
        actions: [
          TextButton(
            onPressed: () async { await auth.logout(); if (mounted) context.go('/login'); },
            child: const Text('تسجيل الخروج', style: TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(children: [
              _buildHeader(auth, sub),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                tabs: const [Tab(text: 'المدفوعات'), Tab(text: 'الاشتراكات')],
              ),
              Expanded(child: TabBarView(controller: _tabController, children: [_buildPayments(), _buildSubscriptions()])),
            ]),
    );
  }

  Widget _buildHeader(AuthProvider auth, SubscriptionProvider sub) {
    return Container(padding: const EdgeInsets.all(20), color: AppTheme.surface, child: Row(children: [
      CircleAvatar(radius: 30, backgroundColor: AppTheme.primary.withOpacity(0.2), child: const Icon(Icons.person, color: AppTheme.primary, size: 32)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(auth.user?.name ?? 'مستخدم', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
        Text(auth.user?.email ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13)),
        if (sub.hasActive)
          Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Text('مشترك نشط', style: TextStyle(color: AppTheme.success, fontFamily: 'Cairo', fontSize: 12))),
      ])),
    ]));
  }

  Widget _buildPayments() {
    if (_payments.isEmpty) return const Center(child: Text('لا توجد مدفوعات', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _payments.length, itemBuilder: (_, i) {
      final p = _payments[i] as Map<String, dynamic>;
      final status = p['status'] as String;
      final color = status == 'APPROVED' ? AppTheme.success : status == 'REJECTED' ? AppTheme.error : AppTheme.warning;
      final label = status == 'APPROVED' ? 'مقبول' : status == 'REJECTED' ? 'مرفوض' : 'معلق';
      return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
        title: Text((p['plan'] as Map?)?['name'] ?? '', style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary)),
        subtitle: Text('\$${p['amount']} • ${p['method']}', style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 11))),
      ));
    });
  }

  Widget _buildSubscriptions() {
    if (_subscriptions.isEmpty) return const Center(child: Text('لا توجد اشتراكات', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _subscriptions.length, itemBuilder: (_, i) {
      final s = _subscriptions[i] as Map<String, dynamic>;
      final isActive = s['status'] == 'ACTIVE';
      final endDate = s['endDate'] as String?;
      return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
        title: Text((s['plan'] as Map?)?['name'] ?? '', style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary)),
        subtitle: Text(endDate != null ? 'حتى: ${endDate.substring(0, 10)}' : '', style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isActive ? AppTheme.success.withOpacity(0.15) : AppTheme.border, borderRadius: BorderRadius.circular(8)), child: Text(isActive ? 'نشط' : 'منتهي', style: TextStyle(color: isActive ? AppTheme.success : AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 11))),
      ));
    });
  }
}
