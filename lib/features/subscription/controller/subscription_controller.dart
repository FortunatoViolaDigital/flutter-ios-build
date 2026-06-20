import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/subscription_service.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

final subscriptionStatusProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return await service.isActive();
});
