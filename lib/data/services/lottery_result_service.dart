import 'supabase_client.dart';

class LotteryResultService {
  Future<List<Map<String, dynamic>>> getTodayResults() async {
    final res = await supa.from('v_today_lottery_results').select().order(
        'position',
        ascending: true); // usa “position” se è quella la colonna

    if (res == null || res is! List) return [];

    return List<Map<String, dynamic>>.from(res);
  }
}
