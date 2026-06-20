import 'supabase_client.dart';

class LotteryService {
  Future<void> enterLottery(String drawId) async {
    try {
      final res = await supa.rpc(
        'enter_lottery',
        params: {'draw_uuid': drawId},
      );

      if (res != null && res is Map && res['error'] != null) {
        throw Exception(res['error']);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTodayDraws() async {
    final today = DateTime.now().toUtc().toIso8601String().split('T').first;

    try {
      final res = await supa.from('lottery_draws').select('''
            id,
            date,
            tier,
            entry_cost,
            total_entries,
            total_prize_pool,
            min_level,
            closed,
            draw_type
          ''').eq('date', today).eq('closed', false);

      if (res is List) {
        return List<Map<String, dynamic>>.from(res);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
