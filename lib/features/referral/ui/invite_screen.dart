import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widget/app_scaffold.dart';
import '../../../widget/refreshing_consumer_state.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_theme.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends RefreshingConsumerState<InviteScreen> {
  bool _copied = false;

  @override
  void onRouteVisible() {
    ref.invalidate(profileProvider);
  }

  Future<void> _copyCode(String referralCode) async {
    await Clipboard.setData(ClipboardData(text: referralCode));
    if (!mounted) return;

    setState(() => _copied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Codice copiato negli appunti ✅'),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareInvite({
    required String referralCode,
    required String referralLink,
  }) async {
    await Share.share(
      'Unisciti a Kash ✨\n'
      'Questo è il mio codice invito: $referralCode\n'
      'Oppure usa direttamente questo link: $referralLink',
      subject: 'Il mio codice Kash: $referralCode',
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return AppScaffold(
      title: '',
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: profileAsync.when(
              loading: () => const _InviteLoadingView(),
              error: (e, _) => _CenteredError(message: 'Errore: $e'),
              data: (profile) {
                final referralCode = profile?.referralCode ?? '';

                if (referralCode.isEmpty) {
                  return const _EmptyInviteView();
                }

                final referralLink =
                    'https://kashapp.it/invite?ref=$referralCode';

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _InviteHeader(referralCode: referralCode),
                      const SizedBox(height: 14),
                      _InviteHeroCard(
                        referralCode: referralCode,
                        copied: _copied,
                        onCopy: () => _copyCode(referralCode),
                        onShare: () => _shareInvite(
                          referralCode: referralCode,
                          referralLink: referralLink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InviteLinkCard(
                        referralLink: referralLink,
                        onCopyLink: () async {
                          await Clipboard.setData(
                            ClipboardData(text: referralLink),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copiato negli appunti ✅'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      const _ReferralHowItWorksCard(),
                      const SizedBox(height: 14),
                      const _ReferralRewardCard(),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Referral Program • Kash Growth Mode',
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

class _InviteHeader extends StatelessWidget {
  final String referralCode;

  const _InviteHeader({
    required this.referralCode,
  });

  @override
  Widget build(BuildContext context) {
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
                Icons.group_add_rounded,
                color: AppTheme.goldSoft,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Invita un amico',
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
          'Condividi il tuo referral e sblocca bonus quando un amico si abbona a Kash.',
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
              icon: Icons.card_giftcard_rounded,
              text: 'Bonus €1 + 100 XP',
              color: AppTheme.goldSoft,
            ),
            _TinyPill(
              icon: Icons.qr_code_2_rounded,
              text: referralCode,
              color: AppTheme.primaryGreen,
            ),
          ],
        ),
      ],
    );
  }
}

class _InviteHeroCard extends StatelessWidget {
  final String referralCode;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _InviteHeroCard({
    required this.referralCode,
    required this.copied,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Il tuo codice invito'),
          const SizedBox(height: 12),
          Text(
            'Invia questo codice ai tuoi amici. Quando completano registrazione e abbonamento, ricevi il bonus referral.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldLuxury.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(
                color: copied
                    ? AppTheme.primaryGreen.withValues(alpha: 0.28)
                    : AppTheme.goldSoft.withValues(alpha: 0.22),
              ),
              boxShadow: copied
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referralCode,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.2,
                          color: AppTheme.goldSoft,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                _MiniIconButton(
                  icon: copied ? Icons.check_rounded : Icons.copy_rounded,
                  accent: copied ? AppTheme.primaryGreen : AppTheme.goldSoft,
                  onTap: onCopy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GradientActionButton(
                  onPressed: onShare,
                  loading: false,
                  text: 'Condividi invito',
                  icon: Icons.share_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryActionButton(
                  onPressed: onCopy,
                  text: 'Copia codice',
                  icon: Icons.copy_rounded,
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

class _InviteLinkCard extends StatelessWidget {
  final String referralLink;
  final VoidCallback onCopyLink;

  const _InviteLinkCard({
    required this.referralLink,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Link referral'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referralLink,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _SecondaryActionButton(
                    onPressed: onCopyLink,
                    text: 'Copia link',
                    icon: Icons.link_rounded,
                    compact: true,
                  ),
                ),
              ],
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

class _ReferralHowItWorksCard extends StatelessWidget {
  const _ReferralHowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Come funziona'),
          const SizedBox(height: 12),
          const _StepRow(
            step: '1',
            title: 'Condividi il codice',
            subtitle: 'Invia il tuo referral code o il link personale.',
          ),
          const SizedBox(height: 10),
          const _StepRow(
            step: '2',
            title: 'Il tuo amico si registra',
            subtitle:
                'Deve usare il tuo invito durante il percorso di accesso.',
          ),
          const SizedBox(height: 10),
          const _StepRow(
            step: '3',
            title: 'Completa l’abbonamento',
            subtitle: 'Il bonus si attiva quando l’utente si abbona a Kash.',
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

class _ReferralRewardCard extends StatelessWidget {
  const _ReferralRewardCard();

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Reward'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  size: 18,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Riceverai il bonus solo quando il tuo amico completa la registrazione e si abbona.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _RewardMiniStat(
                  icon: Icons.euro_rounded,
                  label: 'Wallet bonus',
                  value: '€1',
                  valueColor: AppTheme.goldSoft,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _RewardMiniStat(
                  icon: Icons.auto_awesome_rounded,
                  label: 'XP bonus',
                  value: '100 XP',
                  valueColor: AppTheme.primaryGreen,
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

class _StepRow extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _StepRow({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.goldSoft.withValues(alpha: 0.12),
            border: Border.all(
              color: AppTheme.goldSoft.withValues(alpha: 0.22),
            ),
          ),
          child: Center(
            child: Text(
              step,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.goldSoft,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
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

class _RewardMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _RewardMiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: valueColor,
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

class _GradientActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String text;
  final IconData? icon;

  const _GradientActionButton({
    required this.onPressed,
    required this.loading,
    required this.text,
    this.icon,
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
              height: 46,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool compact;

  const _SecondaryActionButton({
    required this.onPressed,
    required this.text,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: compact ? 40 : 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: accent.withValues(alpha: 0.10),
            border: Border.all(
              color: accent.withValues(alpha: 0.20),
            ),
          ),
          child: Icon(icon, size: 18, color: accent),
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

class _InviteLoadingView extends StatelessWidget {
  const _InviteLoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: const [
          _SkeletonHeader(),
          SizedBox(height: 14),
          _SkeletonPanel(height: 220),
          SizedBox(height: 14),
          _SkeletonPanel(height: 150),
          SizedBox(height: 14),
          _SkeletonPanel(height: 180),
        ],
      ),
    );
  }
}

class _EmptyInviteView extends StatelessWidget {
  const _EmptyInviteView();

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
                  Icons.group_off_rounded,
                  color: AppTheme.goldSoft,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Codice referral non disponibile',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Al momento non è stato trovato un codice invito associato al tuo profilo.',
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
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.20),
            ),
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
            Expanded(child: _SkeletonLine(widthFactor: 0.52, height: 22)),
          ],
        ),
        SizedBox(height: 10),
        _SkeletonLine(widthFactor: 0.75, height: 14),
        SizedBox(height: 10),
        Row(
          children: [
            _SkeletonBox(width: 140, height: 28, radius: 999),
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
