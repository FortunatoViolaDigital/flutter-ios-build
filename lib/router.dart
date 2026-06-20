import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importa il routeObserver definito in refreshing_consumer_state.dart
import 'package:kash/widget/refreshing_consumer_state.dart';

// Screens
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/signup_screen.dart';
import 'features/auth/ui/reset_password_screen.dart';
import 'features/auth/ui/new_password_screen.dart';
import 'features/auth/ui/otp_recovery_screen.dart';

import 'features/onboarding/ui/onboarding_welcome_screen.dart';
import 'features/onboarding/ui/profile_setup_screen.dart';
import 'features/onboarding/ui/tutorial_draw_screen.dart';
import 'features/onboarding/ui/tutorial_success_screen.dart';

import 'features/dashboard/ui/dashboard_screen.dart';
import 'features/splash/splash_redirector.dart';
import 'features/subscription/ui/subscription_screen.dart';
import 'features/lottery/ui/daily_lottery_screen.dart';
import 'features/account/ui/account_screen.dart';
import 'features/account/ui/edit_profile_screen.dart';
import 'features/referral/ui/invite_screen.dart';

// ✅ TopUp screen
import 'features/wallet/ui/top_up_screen.dart';

// ✅ NUOVO: storico movimenti
import 'features/wallet/ui/wallet_history_screen.dart';

/// ✅ Centralized route names
class AppRoutes {
  static const splash = 'splash';
  static const login = 'login';
  static const signup = 'signup';
  static const resetPassword = 'resetPassword';
  static const newPassword = 'newPassword';
  static const otpRecovery = 'otpRecovery';

  static const onboarding = 'onboarding';
  static const onboardingProfile = 'onboardingProfile';
  static const onboardingTutorial = 'onboardingTutorial';
  static const onboardingSuccess = 'onboardingSuccess';
  static const onboardingTutorialSuccess = 'onboarding-tutorial-success';

  static const dashboard = 'dashboard';
  static const subscription = 'subscription';
  static const lottery = 'lottery';
  static const account = 'account';
  static const editProfile = 'editProfile';

  static const topup = 'topup';
  static const transactions = 'transactions';
  static const invite = 'invite';
}

/// 🔄 Stream listener per aggiornare router su eventi di login/logout
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;
  _GoRouterRefreshStream(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// 🧭 Router globale dell'app
final router = GoRouter(
  initialLocation: '/',
  overridePlatformDefaultLocation: true,
  refreshListenable: _GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  observers: [routeObserver],
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final here = state.matchedLocation;
    final uri = Uri.base;
    final isRecovery = uri.fragment.contains('type=recovery');
    final isOnNewPassword = here == '/new-password';

    if (isRecovery && !isOnNewPassword) return '/new-password';
    if (isRecovery && isOnNewPassword) return null;

    const publicRoutes = <String>{
      '/login',
      '/signup',
      '/reset-password',
      '/new-password',
      '/otp-recovery',
    };
    final isPublic = publicRoutes.contains(here);

    if (session == null) {
      return isPublic ? null : '/login';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: AppRoutes.splash,
      builder: (_, __) => const SplashRedirector(),
    ),
    GoRoute(
      path: '/login',
      name: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: AppRoutes.signup,
      builder: (_, __) => const SignupScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      name: AppRoutes.resetPassword,
      builder: (_, __) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/new-password',
      name: AppRoutes.newPassword,
      builder: (_, __) => const SetNewPasswordScreen(),
    ),
    GoRoute(
      path: '/otp-recovery',
      name: AppRoutes.otpRecovery,
      builder: (context, state) {
        final email = state.extra as String;
        return OtpRecoveryScreen(email: email);
      },
    ),
    GoRoute(
      path: '/onboarding',
      name: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingWelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding/profile',
      name: AppRoutes.onboardingProfile,
      builder: (_, __) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/onboarding/tutorial',
      name: AppRoutes.onboardingTutorial,
      builder: (_, __) => const TutorialDrawScreen(),
    ),
    GoRoute(
      path: '/onboarding/tutorial/success',
      name: AppRoutes.onboardingSuccess,
      builder: (_, __) => const TutorialSuccessScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: AppRoutes.dashboard,
      builder: (_, __) => const DashboardScreen(),
      routes: [
        GoRoute(
          path: 'subscription',
          name: AppRoutes.subscription,
          builder: (_, __) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: 'lottery',
          name: AppRoutes.lottery,
          builder: (_, __) => const DailyLotteryScreen(),
        ),
        GoRoute(
          path: 'account',
          name: AppRoutes.account,
          builder: (_, __) => const AccountScreen(),
        ),
        GoRoute(
          path: 'edit-profile',
          name: AppRoutes.editProfile,
          builder: (_, __) => const EditProfileScreen(),
        ),
        GoRoute(
          path: 'invite',
          name: AppRoutes.invite,
          builder: (_, __) => const InviteScreen(),
        ),
        GoRoute(
          path: 'topup',
          name: AppRoutes.topup,
          builder: (_, __) => const TopUpScreen(),
        ),
        GoRoute(
          path: 'transactions',
          name: AppRoutes.transactions,
          builder: (_, __) => const WalletHistoryScreen(),
        ),
      ],
    ),
  ],
);
