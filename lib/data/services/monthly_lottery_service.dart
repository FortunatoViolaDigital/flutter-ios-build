import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyLotteryService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> joinMonthly() async {
    await _client.rpc('enter_monthly_lottery');
  }

  Future<Map<String, dynamic>?> getCurrentMonthlyDraw() async {
    final monthStart = _monthStartIso();

    final draw = await _client
        .from('lottery_draws')
        .select()
        .eq('draw_type', 'monthly')
        .eq('date', monthStart)
        .maybeSingle();

    // maybeSingle() può tornare dynamic, quindi castiamo in modo sicuro
    if (draw == null) return null;
    return Map<String, dynamic>.from(draw as Map);
  }

  Future<bool> hasJoined(String drawId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;

    final entry = await _client
        .from('lottery_entries')
        .select('id')
        .eq('draw_id', drawId)
        .eq('user_id', uid)
        .maybeSingle();

    return entry != null;
  }

  Future<List<Map<String, dynamic>>> getResults(String drawId) async {
    final res = await _client
        .from('lottery_results')
        .select()
        .eq('draw_id', drawId)
        .order('position');

    return List<Map<String, dynamic>>.from(res as List);
  }
}

String _monthStartIso() {
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month, 1);
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
