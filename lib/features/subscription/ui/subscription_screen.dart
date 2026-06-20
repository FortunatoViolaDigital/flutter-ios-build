import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/subscription_service.dart';
import '../../../widget/app_scaffold.dart';
import '../../../widget/refreshing_consumer_state.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_theme.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState
    extends RefreshingConsumerState<SubscriptionScreen> {
  bool _activating = false;

  @override
  void onRouteVisible() {
    ref.invalidate(subscriptionDetailsProvider);
    ref.invalidate(subscriptionStatusProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(profileProvider);
  }

  Future<void> _activateSubscription() async {
    if (_activating) return;

    setState(() => _activating = true);

    try {
      await SubscriptionService().activateSubscription();

      ref.invalidate(subscriptionDetailsProvider);
      ref.invalidate(subscriptionStatusProvider);
      ref.invalidate(walletProvider);
      ref.invalidate(profileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sottoscrizione attivata ✅'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionDetailsProvider);

    return AppScaffold(
      title: '',
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: subscription.when(
              loading: () => const _SubscriptionLoadingView(),
              error: (e, _) => _CenteredError(message: 'Errore: $e'),
              data: (data) {
                if (data == null) {
                  return const _EmptySubscriptionView();
                }

                final isActive = data['is_active'] == true;
                final start = data['start_date'] != null
                    ? DateTime.tryParse(data['start_date'].toString())
                    : null;
                final end = data['end_date'] != null
                    ? DateTime.tryParse(data['end_date'].toString())
                    : null;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _SubscriptionHeader(
                        isActive: isActive,
                        end: end,
                      ),
                      const SizedBox(height: 14),
                      _SubscriptionHeroCard(
                        isActive: isActive,
                        start: start,
                        end: end,
                      ),
                      const SizedBox(height: 14),
                      _BenefitsCard(isActive: isActive),
                      const SizedBox(height: 14),
                      _BillingCard(
                        isActive: isActive,
                        onActivate: _activateSubscription,
                        loading: _activating,
                      ),
                      const SizedBox(height: 14),
                      const _SupportInfoCard(),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Premium Access • Kash Membership',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:
                                    AppTheme.mutedText.withValues(alpha: 0.85),
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D0F),
              Color(0xFF15161A),
              Color(0xFF0D0D0F),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionHeader extends StatelessWidget {
  final bool isActive;
  final DateTime? end;

  const _SubscriptionHeader({
    required this.isActive,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = isActive
        ? (end != null
            ? 'Il tuo accesso premium è attivo fino al ${_formatDate(end!)}.'
            : 'Il tuo accesso premium è attualmente attivo.')
        : 'Attiva il premium per sbloccare le funzionalità esclusive.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: AppTheme.goldLuxury.withValues(alpha: 0.07),
                border: Border.all(
                  color: AppTheme.goldSoft.withValues(alpha: 0.24),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.goldSoft,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Abbonamento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.25,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TinyPill(
              icon: isActive
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_outlined,
              text: isActive ? 'Premium attivo' : 'Premium inattivo',
              color: isActive ? AppTheme.primaryGreen : AppTheme.goldSoft,
            ),
            const _TinyPill(
              icon: Icons.account_balance_wallet_outlined,
              text: 'Rinnovo €10',
              color: AppTheme.goldSoft,
            ),
          ],
        ),
      ],
    );
  }
}

class _SubscriptionHeroCard extends StatelessWidget {
  final bool isActive;
  final DateTime? start;
  final DateTime? end;

  const _SubscriptionHeroCard({
    required this.isActive,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isActive ? AppTheme.primaryGreen : AppTheme.goldSoft;

    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Stato membership'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.13),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive
                            ? 'Abbonamento attivo'
                            : 'Abbonamento non attivo',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? 'Hai accesso alle funzionalità premium di Kash.'
                            : 'Attiva ora il premium per sbloccare l’esperienza completa.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedText,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.calendar_month_outlined,
                  label: 'Inizio',
                  value: start != null ? _formatDate(start!) : 'N/D',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.event_available_outlined,
                  label: 'Scadenza',
                  value: end != null ? _formatDate(end!) : 'N/D',
                  valueColor:
                      isActive ? AppTheme.primaryGreen : AppTheme.goldSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [AppTheme.goldSoft, AppTheme.goldLuxury],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  final bool isActive;

  const _BenefitsCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Vantaggi premium'),
          const SizedBox(height: 12),
          const _BenefitRow(
            icon: Icons.casino_outlined,
            title: 'Accesso lotteria giornaliera',
            subtitle:
                'Partecipa agli eventi daily riservati agli utenti premium.',
          ),
          const SizedBox(height: 10),
          const _BenefitRow(
            icon: Icons.star_outline_rounded,
            title: 'Esperienza avanzata',
            subtitle:
                'Sblocchi funzioni e vantaggi riservati nell’ecosistema Kash.',
          ),
          const SizedBox(height: 10),
          _BenefitRow(
            icon:
                isActive ? Icons.verified_outlined : Icons.lock_outline_rounded,
            title: isActive ? 'Status premium attivo' : 'Premium da attivare',
            subtitle: isActive
                ? 'Il tuo account è già abilitato alle funzionalità premium.'
                : 'Attiva la membership per passare al livello premium.',
            accent: isActive ? AppTheme.primaryGreen : AppTheme.goldSoft,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [AppTheme.goldSoft, AppTheme.goldLuxury],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _BillingCard extends StatelessWidget {
  final bool isActive;
  final bool loading;
  final VoidCallback onActivate;

  const _BillingCard({
    required this.isActive,
    required this.loading,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Rinnovo e pagamento'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Column(
              children: [
                const _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Costo abbonamento',
                  value: '€10',
                  valueColor: AppTheme.goldSoft,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Metodo',
                  value: 'Wallet Kash',
                  valueColor: isActive ? AppTheme.primaryGreen : Colors.white,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.sync_rounded,
                  label: 'Stato',
                  value: isActive ? 'Attivo' : 'Da rinnovare',
                  valueColor:
                      isActive ? AppTheme.primaryGreen : AppTheme.goldSoft,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (isActive ? AppTheme.primaryGreen : AppTheme.goldSoft)
                  .withValues(alpha: 0.08),
              border: Border.all(
                color: (isActive ? AppTheme.primaryGreen : AppTheme.goldSoft)
                    .withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle_outline : Icons.info_outline,
                  size: 16,
                  color: isActive ? AppTheme.primaryGreen : AppTheme.goldSoft,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isActive
                        ? 'La tua membership è già attiva.'
                        : 'Il rinnovo verrà effettuato usando il saldo wallet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive
                              ? AppTheme.primaryGreen
                              : AppTheme.goldSoft,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _GradientActionButton(
            onPressed: isActive || loading ? null : onActivate,
            loading: loading,
            text: isActive
                ? 'Abbonamento già attivo'
                : 'Rinnova con wallet (€10)',
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [AppTheme.goldSoft, AppTheme.goldLuxury],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _SupportInfoCard extends StatelessWidget {
  const _SupportInfoCard();

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Info'),
          const SizedBox(height: 12),
          Text(
            'Il piano premium viene gestito tramite wallet interno e sblocca le funzionalità esclusive disponibili in app.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [AppTheme.goldSoft, AppTheme.goldLuxury],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accent;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppTheme.goldSoft;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: c.withValues(alpha: 0.10),
            border: Border.all(
              color: c.withValues(alpha: 0.20),
            ),
          ),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubscriptionLoadingView extends StatelessWidget {
  const _SubscriptionLoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: const [
          _SkeletonHeader(),
          SizedBox(height: 14),
          _SkeletonPanel(height: 170),
          SizedBox(height: 14),
          _SkeletonPanel(height: 180),
          SizedBox(height: 14),
          _SkeletonPanel(height: 210),
        ],
      ),
    );
  }
}

class _EmptySubscriptionView extends StatelessWidget {
  const _EmptySubscriptionView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: _LuxuryPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.goldLuxury.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppTheme.goldSoft.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppTheme.goldSoft,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Nessuna sottoscrizione trovata',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Non risultano dati di membership associati al tuo account.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryPanel extends StatelessWidget {
  final Widget child;

  const _LuxuryPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202127), Color(0xFF15161B)],
        ),
        border: Border.all(
          color: AppTheme.goldLuxury.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldLuxury.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.mutedText.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: valueColor ?? Colors.white,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.mutedText.withValues(alpha: 0.95),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? Colors.white,
              ),
        ),
      ],
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String text;

  const _GradientActionButton({
    required this.onPressed,
    required this.loading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldLuxury.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      text,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _TinyPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CenteredError extends StatelessWidget {
  final String message;

  const _CenteredError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.redAccent.withValues(alpha: 0.08),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.redAccent.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonHeader extends StatelessWidget {
  const _SkeletonHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SkeletonBox(width: 40, height: 40, radius: 12),
            SizedBox(width: 10),
            Expanded(child: _SkeletonLine(widthFactor: 0.42, height: 22)),
          ],
        ),
        SizedBox(height: 10),
        _SkeletonLine(widthFactor: 0.72, height: 14),
        SizedBox(height: 10),
        Row(
          children: [
            _SkeletonBox(width: 120, height: 28, radius: 999),
            SizedBox(width: 8),
            _SkeletonBox(width: 110, height: 28, radius: 999),
          ],
        ),
      ],
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  final double height;

  const _SkeletonPanel({required this.height});

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: _SkeletonBox(
        width: double.infinity,
        height: height,
        radius: 16,
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonLine({
    this.widthFactor = 1,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: _SkeletonBox(
        width: double.infinity,
        height: height,
        radius: 999,
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
