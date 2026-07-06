import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/subscription/plans_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/payment/payment_proof_screen.dart';
import '../screens/payment/manual_payment_screen.dart';
import '../screens/payment/oxapay_payment_screen.dart';
import '../screens/engine/engine_guard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_payments_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/admin_plans_screen.dart';
import '../screens/admin/admin_games_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: '/',
      redirect: (context, state) {
        if (auth.isLoading) return null;
        final isAuth = auth.isAuthenticated;
        final isAuthRoute = state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register');
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/',       builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/plans',  builder: (_, __) => const PlansScreen()),
            GoRoute(
              path: '/payment/:planId',
              builder: (_, state) => PaymentScreen(planId: state.pathParameters['planId']!),
            ),
            GoRoute(
              path: '/payment/:paymentId/proof',
              builder: (_, state) => PaymentProofScreen(paymentId: state.pathParameters['paymentId']!),
            ),
            // USDT via OxaPay - WebView-based checkout with auto-activation
            GoRoute(
              path: '/payment/:paymentId/oxapay',
              builder: (_, state) => OxapayPaymentScreen(paymentId: state.pathParameters['paymentId']!),
            ),
            // ShamCash / Syriatel Cash - Manual payment with admin approval
            GoRoute(
              path: '/payment/:paymentId/manual',
              builder: (_, state) => ManualPaymentScreen(paymentId: state.pathParameters['paymentId']!),
            ),
            GoRoute(path: '/engine',  builder: (_, __) => const EngineGuardScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            GoRoute(path: '/admin',            builder: (_, __) => const AdminDashboardScreen()),
            GoRoute(path: '/admin/users',      builder: (_, __) => const AdminUsersScreen()),
            GoRoute(path: '/admin/payments',   builder: (_, __) => const AdminPaymentsScreen()),
            GoRoute(path: '/admin/settings',   builder: (_, __) => const AdminSettingsScreen()),
            GoRoute(path: '/admin/plans',      builder: (_, __) => const AdminPlansScreen()),
            GoRoute(path: '/admin/games',      builder: (_, __) => const AdminGamesScreen()),
          ],
        ),
      ],
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) => widget.child;
}
