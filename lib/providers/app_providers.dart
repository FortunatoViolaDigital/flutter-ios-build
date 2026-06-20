import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile.dart';
import '../data/services/profile_service.dart';
import '../data/services/lottery_result_service.dart';
import '../data/services/lottery_service.dart';
import '../data/services/subscription_service.dart';
import '../data/services/monthly_lottery_service.dart';
export '../features/wallet/controller/wallet_controller.dart';

/// 👤 Profile
final profileProvider = FutureProvider<Profile?>((ref) async {
  return ProfileService().getMe();
});

/// 🏆 Winners (dashboard)
final todayWinnersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return LotteryResultService().getTodayResults();
});

/// 🎟️ Draws (daily lottery)
final drawsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return LotteryService().getTodayDraws();
});

/// 💳 Subscription (details screen)
final subscriptionDetailsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  return SubscriptionService().getSubscription();
});

/// ✅ Subscription status (bool)
final subscriptionStatusProvider = FutureProvider<bool>((ref) async {
  return SubscriptionService().isActive();
});

class MonthlyLotteryState {
  final Map<String, dynamic>? draw; // lottery_draws row
  final bool alreadyJoined;
  final List<Map<String, dynamic>> results; // lottery_results

  MonthlyLotteryState({
    required this.draw,
    required this.alreadyJoined,
    required this.results,
  });
}

/// 🌙 Monthly lottery (current month)
final monthlyLotteryProvider = FutureProvider<MonthlyLotteryState>((ref) async {
  final service = MonthlyLotteryService();

  final draw = await service.getCurrentMonthlyDraw();
  if (draw == null) {
    return MonthlyLotteryState(
      draw: null,
      alreadyJoined: false,
      results: const [],
    );
  }

  final drawId = draw['id'] as String;

  final alreadyJoined = await service.hasJoined(drawId);
  final results = await service.getResults(drawId);

  return MonthlyLotteryState(
    draw: draw,
    alreadyJoined: alreadyJoined,
    results: results,
  );
});
