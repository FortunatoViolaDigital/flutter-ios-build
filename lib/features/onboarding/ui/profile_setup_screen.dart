import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../widget/app_scaffold.dart';
import '../../../router.dart';

// ✅ provider centralizzati
import '../../../providers/app_providers.dart';

// (opzionale) se il setup profilo può influire sul wallet o altro
// import '../../wallet/controller/wallet_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _ref = TextEditingController();

  bool _anonymous = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _ref.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('profiles').update({
        'full_name': _name.text.trim().isEmpty ? null : _name.text.trim(),
        'anonymous_mode': _anonymous,
        'invited_by': _ref.text.trim().isEmpty ? null : _ref.text.trim(),
      }).eq('id', uid);

      // ✅ IMPORTANTISSIMO: aggiorna subito cache Riverpod
      ref.invalidate(profileProvider);

      // opzionale, se serve nel tuo dominio
      // ref.invalidate(walletProvider);
      // ref.invalidate(subscriptionStatusProvider);

      if (!mounted) return;
      context.pushNamed(AppRoutes.onboardingTutorial);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not save profile');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profilo',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Display name (optional)',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              title: const Text('Hide my identity on winners list'),
              subtitle: const Text(
                'Winners are public, but your name can be hidden.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ref,
              decoration: const InputDecoration(
                labelText: 'Referral code (optional)',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
