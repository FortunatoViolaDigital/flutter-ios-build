import 'supabase_client.dart';

class SubscriptionService {
  final double annualCost = 10.0;

  Future<Map<String, dynamic>?> getSubscription() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return null;

    final res =
        await supa.from('subscriptions').select().eq('id', uid).maybeSingle();

    return res;
  }

  Future<bool> isActive() async {
    final sub = await getSubscription();
    if (sub == null) return false;

    final end = DateTime.tryParse(sub['end_date'] ?? '');
    return sub['is_active'] == true &&
        end != null &&
        end.isAfter(DateTime.now());
  }

  Future<void> activateSubscription() async {
    await supa.rpc('activate_subscription');
  }
}
