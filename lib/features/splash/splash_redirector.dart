import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../router.dart'; // 👈 per AppRoutes (se il path è diverso, adattalo)

class SplashRedirector extends StatefulWidget {
  const SplashRedirector({super.key});

  @override
  State<SplashRedirector> createState() => _SplashRedirectorState();
}

class _SplashRedirectorState extends State<SplashRedirector> {
  bool _ran = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ran) return;
    _ran = true;
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    // lascia tempo al router / supabase di inizializzarsi
    await Future.delayed(const Duration(milliseconds: 100));

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      // ✅ provisioning server-side: crea profilo/wallet/subscription se mancano
      try {
        await supabase.rpc('ensure_user_initialized');
      } catch (_) {
        // non bloccare l’utente se fallisce: al massimo logga
      }

      if (!mounted) return;
      context.goNamed(AppRoutes.dashboard); // ✅ non lascia splash nello stack
    } else {
      context.goNamed(AppRoutes.login); // ✅ non lascia splash nello stack
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
