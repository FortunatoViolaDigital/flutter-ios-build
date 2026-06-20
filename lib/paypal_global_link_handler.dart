import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/services/paypal_service.dart';
import 'router.dart';

class PayPalGlobalLinkHandler {
  final _paypal = PayPalService();
  final _appLinks = AppLinks();

  StreamSubscription<Uri>? _sub;

  // ✅ anti doppio evento (stesso token gestito una sola volta)
  final Set<String> _handledTokens = {};

  // ✅ evita race conditions se arrivano eventi in sequenza
  bool _handling = false;

  void start() async {
    // 1) cold start (app aperta da spenta con link)
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        unawaited(_handle(initial));
      }
    } catch (e) {
      debugPrint('PayPalGlobalLinkHandler initial link error: $e');
    }

    // 2) runtime links
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handle(uri)),
      onError: (e) => debugPrint('PayPalGlobalLinkHandler stream error: $e'),
    );
  }

  Future<void> _handle(Uri uri) async {
    // gestiamo solo kash://paypal/return e cancel
    final isPayPal = uri.scheme == 'kash' && uri.host == 'paypal';
    if (!isPayPal) return;

    if (uri.path == '/cancel') {
      router.go('/dashboard');
      return;
    }

    if (uri.path != '/return') return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    // anti doppio token
    if (_handledTokens.contains(token)) return;
    _handledTokens.add(token);

    // evita che 2 capture partano assieme
    if (_handling) return;
    _handling = true;

    try {
      // ✅ aspetta che la session auth sia pronta (soprattutto su cold start)
      await _waitForSessionReady();

      // ✅ prova capture con un paio di retry (utile se network ballerino)
      await _captureWithRetry(token);

      // Vai in dashboard (DashboardScreen farà invalidate walletProvider in onRouteVisible)
      router.go('/dashboard');
    } catch (e) {
      debugPrint('PayPalGlobalLinkHandler capture error: $e');

      // Se fallisce, togliamo il token dalla cache così puoi ritentare (opzionale)
      _handledTokens.remove(token);

      // Ritorna comunque alla dashboard (o potresti portare a topup con un messaggio)
      router.go('/dashboard');
    } finally {
      _handling = false;
    }
  }

  Future<void> _waitForSessionReady() async {
    // Se sei già loggato, ok
    if (Supabase.instance.client.auth.currentSession != null) return;

    // Aspetta un po' (fino a ~2s) per lasciare a Supabase il tempo di ripristinare la session
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (Supabase.instance.client.auth.currentSession != null) return;
    }

    // Se dopo 2s non c’è session, non ha senso fare capture (invoke richiede JWT)
    throw Exception('No active session (user not logged in)');
  }

  Future<void> _captureWithRetry(String token) async {
    // 2 tentativi: immediate + retry breve
    try {
      await _paypal.captureOrder(token);
      return;
    } catch (e) {
      debugPrint('Capture attempt 1 failed: $e');
      await Future.delayed(const Duration(milliseconds: 600));
      await _paypal.captureOrder(token);
    }
  }

  void dispose() => _sub?.cancel();
}
