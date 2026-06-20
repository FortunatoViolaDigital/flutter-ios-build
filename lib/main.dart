import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paypal_global_link_handler.dart';

import 'router.dart';
import 'theme/app_theme.dart';

StreamSubscription<AuthState>? _authSub;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wncfqnozxiiqxamsjrdl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InduY2Zxbm96eGlpcXhhbXNqcmRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NjUyMjgsImV4cCI6MjA3NDA0MTIyOH0.9glc1s4rRhu2uwoKfd2W-0W6UynoYPKfcpIUH9Qj698',
  );

  final payPalHandler = PayPalGlobalLinkHandler();
  payPalHandler.start();

  // ✔️ migliora gli URL web (no #) — ok tenerlo
  setPathUrlStrategy();

  // ✅ Listener globale: quando l'utente diventa autenticato,
  // inizializza profilo/wallet/subscription una sola volta (idempotente).
  _authSub =
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final session = data.session;
    if (session == null) return;

    try {
      await Supabase.instance.client.rpc('ensure_user_initialized');
      debugPrint('✅ ensure_user_initialized OK for ${session.user.id}');
    } on PostgrestException catch (e) {
      // Qui vedi errori veri: RLS, vincoli, tipi colonna, ecc.
      debugPrint('❌ ensure_user_initialized PostgrestException: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
    } catch (e) {
      debugPrint('❌ ensure_user_initialized error: $e');
    }
  });

  runApp(
    const ProviderScope(
      child: KashApp(),
    ),
  );
}

class KashApp extends StatefulWidget {
  const KashApp({super.key});

  @override
  State<KashApp> createState() => _KashAppState();
}

class _KashAppState extends State<KashApp> {
  @override
  void dispose() {
    // ✅ chiudi subscription quando l'app viene chiusa
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kash',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
