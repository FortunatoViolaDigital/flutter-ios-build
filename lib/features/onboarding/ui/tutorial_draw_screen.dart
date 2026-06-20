import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/wallet_service.dart';
import '../../../widget/app_scaffold.dart';
import '../../../router.dart'; // 👈 Importa AppRoutes

class TutorialDrawScreen extends StatefulWidget {
  const TutorialDrawScreen({super.key});

  @override
  State<TutorialDrawScreen> createState() => _TutorialDrawScreenState();
}

class _TutorialDrawScreenState extends State<TutorialDrawScreen> {
  bool _running = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // fake suspense
    await Future.delayed(const Duration(seconds: 2));
    try {
      await WalletService().awardTutorialCredit();

      if (mounted) {
        setState(() => _running = false);
        await Future.delayed(const Duration(milliseconds: 600));

        // ✅ Usa GoRouter con nome
        if (mounted) context.pushNamed(AppRoutes.onboardingTutorialSuccess);
      }
    } catch (e) {
      setState(() => _error = 'Tutorial already completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tutorial',
      body: Center(
        child: _running
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Drawing your tutorial prize...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
            : _error != null
                ? Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
