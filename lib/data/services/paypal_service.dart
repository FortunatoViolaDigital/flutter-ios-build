import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PayPalService {
  final SupabaseClient _sb = Supabase.instance.client;

  Future<Map<String, dynamic>> createOrder({
    required String kind, // 'topup' | 'subscription'
    required int amountCents,
    String currency = 'EUR',
  }) async {
    final res = await _sb.functions.invoke(
      'paypal_create_order',
      body: {
        'kind': kind,
        'amount_cents': amountCents,
        'currency': currency,
      },
    );

    if (res.status != 200) {
      throw Exception('paypal_create_order failed: ${res.data}');
    }

    final data = Map<String, dynamic>.from(res.data as Map);
    return data; // contiene approval_url, paypal_order_id, payment_order_id
  }

  Future<void> openApprovalUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('Impossibile aprire PayPal');
  }

  Future<void> captureOrder(String paypalOrderId) async {
    final res = await _sb.functions.invoke(
      'paypal_capture_order',
      body: {'paypal_order_id': paypalOrderId},
    );

    if (res.status != 200) {
      throw Exception('paypal_capture_order failed: ${res.data}');
    }
  }
}
