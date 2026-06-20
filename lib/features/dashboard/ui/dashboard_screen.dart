import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../wallet/ui/wallet_card.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../lottery/ui/lottery_result_card.dart';

import 'package:kash/data/services/referral_service.dart';
import '../../../data/models/profile.dart';
import '../../../data/services/monthly_lottery_service.dart';

import '../../../widget/app_scaffold.dart';
import '../../../widget/xp_progress_bar.dart';
import '../../../widget/level_up_dialog.dart';
import '../../../widget/reward_popup.dart';

import '../../../router.dart';
import '../../../widget/refreshing_consumer_state.dart';
import '../../../providers/app_providers.dart';

import '../../../widget/luxury_box.dart';
import '../../../widget/dashboard_action_tile.dart';
import '../../../theme/app_theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends RefreshingConsumerState<DashboardScreen> {
  bool _checkedReferral = false;
  ProviderSubscription<AsyncValue<Profile?>>? _profileSub;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _profileSub = ref.listenManual<AsyncValue<Profile?>>(
      profileProvider,
      (prev, next) async {
        final profile = next.valueOrNull;
        if (profile == null || !mounted) return;

        final prefs = await SharedPreferences.getInstance();
        final currentLevel = profile.level;

        final hasSeenLevel = prefs.containsKey('last_seen_level');

        if (!hasSeenLevel) {
          await prefs.setInt('last_seen_level', currentLevel);
          return;
        }

        final lastLevel = prefs.getInt('last_seen_level') ?? currentLevel;

        if (currentLevel > lastLevel) {
          await prefs.setInt('last_seen_level', currentLevel);
          if (!mounted) return;

          showDialog(
            context: context,
            builder: (ctx) => LevelUpDialog(level: currentLevel),
          );
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _profileSub?.close();
    super.dispose();
  }

  @override
  void onRouteVisible() {
    ref.invalidate(profileProvider);
    ref.invalidate(todayWinnersProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(monthlyLotteryProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkReferralBonus();
  }

  Future<void> _checkReferralBonus() async {
    if (_checkedReferral) return;
    _checkedReferral = true;

    final redeemed = await ReferralService().tryRedeemBonus();
    if (redeemed && mounted) {
      await Future.delayed(const Duration(milliseconds: 400));
      showDialog(
        context: context,
        builder: (ctx) => const RewardPopup(
          title: 'Bonus ricevuto!',
          message: 'Hai guadagnato 1€ e 100 XP per aver invitato un amico 🎉',
        ),
      );
    }
  }

  DateTime? _monthlyDrawTime(Map<String, dynamic> draw) {
    const keys = [
      'draw_at',
      'draw_date',
      'ends_at',
      'end_at',
      'scheduled_at',
      'close_at',
      'closes_at',
    ];

    for (final k in keys) {
      final raw = draw[k];

      if (raw is String && raw.isNotEmpty) {
        final dt = DateTime.tryParse(raw)?.toLocal();

        if (dt != null) {
          return dt;
        }
      }

      if (raw is DateTime) {
        return raw.toLocal();
      }
    }

    return null;
  }

  Duration _monthlyRemaining() {
    final now = DateTime.now();

    // primo giorno del mese successivo
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final diff = nextMonth.difference(now);

    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${days}g ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final winnersAsync = ref.watch(todayWinnersProvider);
    final monthlyAsync = ref.watch(monthlyLotteryProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return AppScaffold(
      title: '',
      body: Stack(
        children: [
          Positioned.fill(
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
          ),
          Positioned(
            top: -60,
            left: -40,
            child: _GlowOrb(
              size: 180,
              color: AppTheme.goldLuxury.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 130,
            right: -50,
            child: _GlowOrb(
              size: 220,
              color: AppTheme.goldLuxury.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  profileAsync.when(
                    loading: () => const _DashboardHeroSkeleton(),
                    error: (_, __) => _profileHero(context, null),
                    data: (profile) => _profileHero(context, profile),
                  ),
                  const SizedBox(height: 18),
                  monthlyAsync.when(
                    loading: () => const _MonthlyLotterySkeleton(),
                    error: (e, _) => LuxuryBox(
                      child: _DashboardErrorText(
                          message: 'Errore lotteria mensile: $e'),
                    ),
                    data: (state) {
                      final draw = state.draw;

                      if (draw == null) {
                        return LuxuryBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: const [
                                  _TinyPill(
                                    icon: Icons.calendar_month_rounded,
                                    text: 'Evento mensile',
                                    color: AppTheme.goldSoft,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _sectionTitleStatic(context, 'Lotteria Mensile'),
                              const SizedBox(height: 8),
                              Text(
                                'La lotteria mensile non è ancora disponibile.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.mutedText,
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _SecondaryActionButton(
                                onPressed: () =>
                                    ref.invalidate(monthlyLotteryProvider),
                                text: 'Aggiorna',
                                icon: Icons.refresh_rounded,
                              ),
                            ],
                          ),
                        );
                      }

                      final closed = (draw['closed'] as bool?) ?? false;
                      final totalEntries =
                          draw['total_entries']?.toString() ?? '0';
                      final remaining = _monthlyRemaining();

                      return LuxuryBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                const _TinyPill(
                                  icon: Icons.workspace_premium_rounded,
                                  text: 'Evento mensile',
                                  color: AppTheme.goldSoft,
                                ),
                                _TinyPill(
                                  icon: closed
                                      ? Icons.lock_outline_rounded
                                      : Icons.flash_on_rounded,
                                  text: closed ? 'Chiusa' : 'Aperta',
                                  color: closed
                                      ? AppTheme.mutedText
                                      : AppTheme.primaryGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _sectionTitleStatic(context, 'Lotteria Mensile'),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.goldLuxury.withValues(alpha: 0.14),
                                    Colors.transparent,
                                  ],
                                ),
                                border: Border.all(
                                  color:
                                      AppTheme.goldSoft.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Countdown estrazione',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.mutedText,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    remaining != null
                                        ? _formatDuration(remaining)
                                        : 'Data non disponibile',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.goldSoft,
                                          height: 1.0,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    closed
                                        ? 'L’estrazione di questo mese è terminata.'
                                        : 'Entra gratis e prova a conquistare il premio mensile.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.mutedText,
                                          height: 1.35,
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
                                    icon: Icons.groups_rounded,
                                    label: 'Partecipazioni',
                                    value: totalEntries,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MiniStat(
                                    icon: Icons.emoji_events_outlined,
                                    label: 'Stato',
                                    value: closed
                                        ? 'Chiusa'
                                        : (state.alreadyJoined
                                            ? 'Registrato'
                                            : 'Disponibile'),
                                    valueColor: closed
                                        ? AppTheme.mutedText
                                        : AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (closed) ...[
                              _StatusBanner(
                                icon: Icons.verified_outlined,
                                text: '✅ Estrazione chiusa.',
                                color: AppTheme.mutedText,
                              ),
                            ] else if (state.alreadyJoined) ...[
                              const _StatusBanner(
                                icon: Icons.check_circle_outline,
                                text: '✅ Hai già partecipato questo mese.',
                                color: AppTheme.primaryGreen,
                              ),
                            ] else ...[
                              _GradientActionButton(
                                onPressed: () async {
                                  try {
                                    await MonthlyLotteryService().joinMonthly();

                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✅ Partecipazione mensile registrata!',
                                        ),
                                      ),
                                    );

                                    ref.invalidate(monthlyLotteryProvider);
                                  } on PostgrestException catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('❌ ${e.message}')),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('❌ Errore: $e')),
                                    );
                                  }
                                },
                                loading: false,
                                text: 'Entra nell’estrazione',
                                icon: Icons.rocket_launch_rounded,
                              ),
                            ],
                            const SizedBox(height: 14),
                            if (state.results.isNotEmpty) ...[
                              Text(
                                'Vincitori del mese',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.goldSoft,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              ...state.results.map((r) {
                                final pos = r['position'];
                                final prize = r['prize_amount'] ?? r['prize'];

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color:
                                          Colors.white.withValues(alpha: 0.02),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.07),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.emoji_events_outlined,
                                          size: 16,
                                          color: AppTheme.goldSoft,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '#$pos',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '€$prize',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.goldSoft,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ] else if (closed) ...[
                              const SizedBox(height: 4),
                              const Text('Nessun vincitore disponibile.'),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  LuxuryBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _TinyPill(
                              icon: Icons.bolt_rounded,
                              text: 'Daily draw',
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _sectionTitleStatic(context, 'Vincitori di oggi'),
                        const SizedBox(height: 6),
                        Text(
                          'Controlla se oggi sei tra i vincitori della lotteria giornaliera.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.mutedText,
                                    height: 1.35,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        winnersAsync.when(
                          loading: () => const LotteryResultCardShimmer(),
                          error: (e, _) => _DashboardErrorText(
                              message: 'Errore risultati: $e'),
                          data: (results) => LotteryResultCard(
                            results: results,
                            currentUserId: currentUserId,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 20,
            child: _ProfileQuickMenu(
              onAccount: () => context.goNamed(AppRoutes.account),
              /*onInvite: () => context.pushNamed('invite'),*/
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHero(BuildContext context, Profile? profile) {
    final name = profile?.fullName ?? 'Utente';
    final avatar = profile?.avatarUrl;
    final level = profile?.level ?? 1;
    final xp = profile?.xp ?? 0;

    return LuxuryBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _TinyPill(
                icon: Icons.auto_awesome_rounded,
                text: 'Dashboard premium',
                color: AppTheme.goldSoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.goldSoft.withValues(alpha: 0.28),
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  child: avatar == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bentornato',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ciao, $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                    ),
                  ],
                ),
              ),
              /*Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.goldLuxury.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppTheme.goldSoft.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'LV $level',
                  style: const TextStyle(
                    color: AppTheme.goldSoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),*/
            ],
          ),
          const SizedBox(height: 12),
          if (profile != null) XPProgressBar(xp: xp, level: level),
          const SizedBox(height: 12),
          /*Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.star_rounded,
                  label: 'Livello',
                  value: 'LV $level',
                  valueColor: AppTheme.goldSoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.auto_graph_rounded,
                  label: 'XP',
                  value: '$xp',
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _MiniStat(
                  icon: Icons.verified_outlined,
                  label: 'Status',
                  value: 'Active',
                  valueColor: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),*/
          const SizedBox(height: 14),
          const WalletCard(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _SecondaryActionButton(
              onPressed: () => context.pushNamed(AppRoutes.subscription),
              text: 'Gestisci abbonamento',
              icon: Icons.workspace_premium_rounded,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              /*Expanded(
                child: DashboardActionTile(
                  title: 'Ricarica conto',
                  subtitle: 'Top up veloce',
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: () => context.pushNamed(AppRoutes.topup),
                ),
              ),
              const SizedBox(width: 10),*/
              Expanded(
                child: DashboardActionTile(
                  title: 'Lotteria giornaliera',
                  subtitle: 'Gioca ora',
                  icon: Icons.emoji_events_rounded,
                  goldAccent: true,
                  onTap: () => context.goNamed(AppRoutes.lottery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitleStatic(BuildContext context, String text) {
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

class _ProfileQuickMenu extends StatelessWidget {
  final VoidCallback onAccount;
  /*final VoidCallback onInvite; disabilitamo invita un amico*/

  const _ProfileQuickMenu({
    required this.onAccount,
    /*required this.onInvite,*/
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF14151A).withValues(alpha: 0.95),
        border: Border.all(color: AppTheme.goldSoft.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldLuxury.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingDockButton(
            icon: Icons.person_outline_rounded,
            onTap: onAccount,
          ),
          /*const SizedBox(width: 6),
          _FloatingDockButton(
            icon: Icons.group_add_outlined,
            onTap: onInvite,
            gold: true,
          ),*/
        ],
      ),
    );
  }
}

class _FloatingDockButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool gold;

  const _FloatingDockButton({
    required this.icon,
    required this.onTap,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = gold ? AppTheme.goldSoft : AppTheme.softWhite;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF26272D), Color(0xFF17181D)],
            ),
            border: Border.all(
              color: gold
                  ? AppTheme.goldSoft.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
      ),
    );
  }
}

class _DashboardHeroSkeleton extends StatelessWidget {
  const _DashboardHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const LuxuryBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SkeletonBox(width: 130, height: 28, radius: 999),
          SizedBox(height: 12),
          Row(
            children: [
              _SkeletonCircle(size: 56),
              SizedBox(width: 12),
              Expanded(
                child: _SkeletonLine(widthFactor: 0.55, height: 22),
              ),
              SizedBox(width: 12),
              _SkeletonBox(width: 54, height: 30),
            ],
          ),
          SizedBox(height: 14),
          _SkeletonBox(width: double.infinity, height: 14),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonBox(width: double.infinity, height: 58)),
              SizedBox(width: 8),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 58)),
              SizedBox(width: 8),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 58)),
            ],
          ),
          SizedBox(height: 14),
          _SkeletonBox(width: double.infinity, height: 56),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 44),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _SkeletonBox(width: double.infinity, height: 112)),
              SizedBox(width: 10),
              Expanded(
                  child: _SkeletonBox(width: double.infinity, height: 112)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyLotterySkeleton extends StatelessWidget {
  const _MonthlyLotterySkeleton();

  @override
  Widget build(BuildContext context) {
    return const LuxuryBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SkeletonBox(width: 120, height: 28, radius: 999),
          SizedBox(height: 12),
          _SkeletonLine(widthFactor: 0.42, height: 20),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 120),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonBox(width: double.infinity, height: 58)),
              SizedBox(width: 8),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 58)),
            ],
          ),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 46),
          SizedBox(height: 12),
          _SkeletonLine(widthFactor: 0.45),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 42),
        ],
      ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color == AppTheme.mutedText ? Colors.white70 : color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: c.withValues(alpha: 0.08),
        border: Border.all(color: c.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: c,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
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

  const _SecondaryActionButton({
    required this.onPressed,
    required this.text,
    this.icon,
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
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
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

class _DashboardErrorText extends StatelessWidget {
  final String message;

  const _DashboardErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.redAccent.withValues(alpha: 0.95),
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

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
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

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
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
