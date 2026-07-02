import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/subscription_card.dart';
import '../../widgets/vip_3d_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _scale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111111), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => sub.loadProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(auth),
                    const SizedBox(height: 24),
                    _buildSubscriptionSection(sub),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(auth),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Row(
      children: [
        Vip3DLogo(size: 48, rotate: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('VIP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: 4)),
              Text(auth.user?.name ?? auth.user?.email ?? 'مستخدم',
                style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (auth.isAdmin)
          GestureDetector(
            onTap: () => context.push('/admin'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primary, size: 20),
            ),
          ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection(SubscriptionProvider sub) {
    if (sub.isLoading) {
      return Container(
        height: 180,
        decoration: GlassCard.gradientDecoration(),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('حالة الاشتراك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
        const SizedBox(height: 12),
        if (!sub.hasActive) _buildNoSubscription() else SubscriptionCard(subscription: sub.activeSubscription!, dailyUsed: sub.dailyUsed, dailyLimit: sub.dailyLimit),
      ],
    );
  }

  Widget _buildNoSubscription() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: GlassCard.gradientDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceVariant,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.card_membership_outlined, color: AppTheme.textHint, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('لا يوجد اشتراك نشط', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('اشترك الآن للحصول على وصول كامل', style: TextStyle(color: AppTheme.textHint, fontFamily: 'Cairo', fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/plans'),
            child: const Text('اشترك الآن'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.rocket_launch_outlined, 'label': 'Engine', 'route': '/engine'},
      {'icon': Icons.card_membership_outlined, 'label': 'الباقات', 'route': '/plans'},
      {'icon': Icons.history_outlined, 'label': 'سجل الدفع', 'route': '/profile'},
      {'icon': Icons.person_outline, 'label': 'حسابي', 'route': '/profile'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الوصول السريع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final a = actions[i];
            return GestureDetector(
              onTap: () => context.push(a['route'] as String),
              child: Container(
                decoration: GlassCard.decoration(radius: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a['icon'] as IconData, color: AppTheme.primary, size: 30),
                    const SizedBox(height: 8),
                    Text(a['label'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav(AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0: context.go('/'); break;
            case 1: context.push('/plans'); break;
            case 2: context.push('/engine'); break;
            case 3: context.push('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.card_membership_outlined), label: 'الباقات'),
          BottomNavigationBarItem(icon: Icon(Icons.rocket_launch_outlined), label: 'Engine'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}
