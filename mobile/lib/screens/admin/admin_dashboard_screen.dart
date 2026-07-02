import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/dashboard');
      final sc = res['_statusCode'] as int? ?? 0;
      if (sc == 401) {
        if (mounted) {
          await Provider.of<AuthProvider>(context, listen: false).logout();
          context.go('/login');
        }
        return;
      }
      if (sc == 403) {
        setState(() => _error = 'ليس لديك صلاحية الأدمن\nيجب ترقية حسابك أولاً');
        setState(() => _loading = false);
        return;
      }
      if (res['success'] == true) {
        setState(() => _stats = res['data'] as Map<String, dynamic>);
      } else {
        setState(() => _error = res['message']?.toString() ?? 'فشل تحميل البيانات');
      }
    } catch (_) {
      setState(() => _error = 'خطأ في الاتصال بالسيرفر');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.admin_panel_settings_outlined, color: AppTheme.accent, size: 22),
          SizedBox(width: 8),
          Text('لوحة الأدمن', style: TextStyle(fontFamily: 'Cairo')),
        ]),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadStats, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      _buildAdminMenu(context),
                    ]),
                  ),
                ),
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      {'label': 'إجمالي المستخدمين',  'value': '${_stats?['totalUsers'] ?? 0}',          'icon': Icons.people_outline,           'color': AppTheme.primary},
      {'label': 'اشتراكات نشطة',      'value': '${_stats?['activeSubscriptions'] ?? 0}',  'icon': Icons.card_membership_outlined,  'color': AppTheme.success},
      {'label': 'طلبات معلقة',        'value': '${_stats?['pendingPayments'] ?? 0}',       'icon': Icons.pending_actions_outlined,  'color': AppTheme.warning},
      {'label': 'إجمالي الأرباح',     'value': '\$${((_stats?['totalRevenue'] ?? 0.0) as num).toStringAsFixed(2)}', 'icon': Icons.attach_money_outlined, 'color': AppTheme.accent},
    ];
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final s = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: (s['color'] as Color).withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(s['icon'] as IconData, color: s['color'] as Color, size: 28),
            const Spacer(),
            Text(s['value'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: s['color'] as Color, fontFamily: 'Cairo')),
            Text(s['label'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12)),
          ]),
        );
      },
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    final items = [
      {'label': 'إدارة المستخدمين', 'icon': Icons.people_outline,           'route': '/admin/users',    'color': AppTheme.primary},
      {'label': 'إدارة المدفوعات',  'icon': Icons.payment_outlined,          'route': '/admin/payments', 'color': AppTheme.success},
      {'label': 'إدارة الباقات',    'icon': Icons.card_membership_outlined,  'route': '/admin/plans',    'color': AppTheme.accent},
      {'label': 'إدارة الألعاب',   'icon': Icons.gamepad_outlined,           'route': '/admin/games',    'color': AppTheme.primary},
      {'label': 'الإعدادات',        'icon': Icons.settings_outlined,          'route': '/admin/settings', 'color': AppTheme.textSecondary},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('الإدارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
      const SizedBox(height: 12),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => context.push(item['route'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(item['label'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: AppTheme.textHint, size: 16),
            ]),
          ),
        ),
      )),
    ]);
  }
}
