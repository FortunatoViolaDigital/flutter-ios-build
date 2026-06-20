import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widget/app_scaffold.dart';

class TutorialSuccessScreen extends StatelessWidget {
  const TutorialSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tutorial completato',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.emoji_events, size: 72),
              const SizedBox(height: 16),
              Text('You won €1!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                  'We’ve added €1 to your wallet as a locked tutorial credit.'),
              const SizedBox(height: 12),
              const Text(
                  'It can be used to join daily draws once you subscribe.'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/subscription'),
                  child: const Text('Go to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
