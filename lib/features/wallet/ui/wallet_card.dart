import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/wallet_controller.dart';
import '../../../theme/app_theme.dart';

class WalletCard extends ConsumerWidget {
  const WalletCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return wallet.when(
      loading: () => _WalletShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WalletHeader(),
            const SizedBox(height: 14),
            Container(
              height: 28,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 6),
            ),
          ],
        ),
      ),
      error: (err, _) => _WalletShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WalletHeader(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Errore caricamento wallet: $err',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      data: (w) => _WalletShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WalletHeader(),
            const SizedBox(height: 14),

            // Saldo principale
            Text(
              'Saldo disponibile',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '€${w.balance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppTheme.primaryGreen.withValues(alpha: 0.14),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    'Attivo',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Riga info secondaria
            /*Row(
              children: [
                Expanded(
                  child: _InfoPill(
                    icon: Icons.school_rounded,
                    label: 'Credito tutorial',
                    value: '€${w.tutorialLocked.toStringAsFixed(2)}',
                    gold: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoPill(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Totale',
                    value:
                        '€${(w.balance + w.tutorialLocked).toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }
}

class _WalletShell extends StatelessWidget {
  final Widget child;

  const _WalletShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF191A1F),
            Color(0xFF131418),
          ],
        ),
        border: Border.all(
          color: AppTheme.goldSoft.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldLuxury.withValues(alpha: 0.06),
            blurRadius: 14,
            spreadRadius: 0.5,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // glow in alto
          /*Positioned(
            top: 0,
            left: 0,
            right: 20,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldSoft.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),*/

          // glow decorativo a destra
          /*Positioned(
            top: -20,
            right: -20,
            child: Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),*/

          child,
        ],
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            gradient: LinearGradient(
              colors: [
                AppTheme.goldLuxury.withValues(alpha: 0.22),
                AppTheme.goldSoft.withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(
              color: AppTheme.goldSoft.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 18,
            color: AppTheme.goldSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Wallet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
          ),
        ),
        /*Text(
          'KASH',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: AppTheme.goldSoft,
                fontWeight: FontWeight.w800,
              ),
        ),*/
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool gold;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = gold ? AppTheme.goldSoft : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
              border: Border.all(
                color: accent.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(
              icon,
              size: 14,
              color: gold ? AppTheme.goldSoft : Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
