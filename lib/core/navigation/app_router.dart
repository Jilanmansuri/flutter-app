import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/hive_service.dart';

// Import Screens (Stubs / Implementations to be created)
import '../../features/authentication/splash_screen.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/authentication/register_screen.dart';
import '../../features/authentication/pin_lock_screen.dart';
import '../../features/authentication/forgot_password_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../features/budget/budget_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/savings/savings_screen.dart';
import '../../features/loans/loans_screen.dart';
import '../../features/bills/bills_screen.dart';
import '../../features/ai/ai_screen.dart';
import '../../features/profile_settings/settings_screen.dart';

final HiveService _hiveService = HiveService();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    final user = _hiveService.getUser();
    final bool isLoggedIn = user != null;

    // Check if user is trying to access auth screens
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot_password' ||
        state.matchedLocation == '/';

    if (!isLoggedIn) {
      // If not logged in and not on auth screen, go to login
      if (!isAuthRoute) return '/login';
      return null;
    }

    // If logged in and on auth screen, forward to PIN lock or dashboard
    if (isAuthRoute) {
      if (user.pinHash != null) {
        return '/pin_lock';
      }
      return '/dashboard';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot_password',
      builder: (BuildContext context, GoRouterState state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/pin_lock',
      builder: (BuildContext context, GoRouterState state) => const PinLockScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/transactions',
      builder: (BuildContext context, GoRouterState state) => const TransactionsScreen(),
    ),
    GoRoute(
      path: '/budget',
      builder: (BuildContext context, GoRouterState state) => const BudgetScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (BuildContext context, GoRouterState state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/savings',
      builder: (BuildContext context, GoRouterState state) => const SavingsScreen(),
    ),
    GoRoute(
      path: '/loans',
      builder: (BuildContext context, GoRouterState state) => const LoansScreen(),
    ),
    GoRoute(
      path: '/bills',
      builder: (BuildContext context, GoRouterState state) => const BillsScreen(),
    ),
    GoRoute(
      path: '/ai',
      builder: (BuildContext context, GoRouterState state) => const AiScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
    ),
  ],
);
