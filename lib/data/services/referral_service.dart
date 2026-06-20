// lib/data/services/referral_service.dart
import 'supabase_client.dart';

class ReferralService {
  Future<bool> tryRedeemBonus() async {
    try {
      final res = await supa.rpc('redeem_referral_bonus');
      return res == true || res == 1;
    } catch (e) {
      return false;
    }
  }
}
