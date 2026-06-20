import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/lottery_service.dart';
import '../../../widget/app_scaffold.dart';
import '../../../widget/refreshing_consumer_state.dart';
import '../../../providers/app_providers.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../router.dart';

class DailyLotteryScreen extends ConsumerStatefulWidget {
  const DailyLotteryScreen({super.key});

  @override
  ConsumerState<DailyLotteryScreen> createState() => _DailyLotteryScreenState();
}

class _DailyLotteryScreenState
    extends RefreshingConsumerState<DailyLotteryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  Timer? _ticker;
  final Set<dynamic> _successFxIds = {};

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    _animCtrl.forward();

    // countdown live refresh (solo UI)
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  void onRouteVisible() {
    ref.invalidate(drawsProvider);
    ref.invalidate(subscriptionStatusProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(walletProvider);
  }

  DateTime? _drawClosingTime(Map<String, dynamic> draw) {
    const keys = [
      'close_at',
      'closes_at',
      'draw_at',
      'draw_date',
      'ends_at',
      'end_at',
      'scheduled_at',
    ];

    for (final k in keys) {
      final raw = draw[k];
      if (raw is String && raw.isNotEmpty) {
        final dt = DateTime.tryParse(raw)?.toLocal();
        if (dt != null) return dt;
      }
    }

    final rawDate = draw['date'];
    if (rawDate is String && rawDate.isNotEmpty) {
      final baseDate = DateTime.tryParse(rawDate);
      if (baseDate != null) {
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          23,
          59,
          59,
        ).toLocal();
      }
    }

    return null;
  }

  Duration? _remaining(Map<String, dynamic> draw) {
    final dt = _drawClosingTime(draw);
    if (dt == null) return null;
    final diff = dt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  bool _alreadyEntered(Map<String, dynamic> draw) {
    final val = draw['already_entered'] ??
        draw['alreadyJoined'] ??
        draw['already_joined'] ??
        draw['is_joined'];
    return val == true;
  }

  double _estimatedChance(int totalEntries, {bool alreadyEntered = false}) {
    // Stima naive: 1 / partecipanti futuri (incluso te se non sei già dentro)
    final denom =
        (totalEntries <= 0 ? 1 : totalEntries) + (alreadyEntered ? 0 : 1);
    return 1 / denom;
  }

  String _chanceLabel(double p) {
    final percent = p * 100;
    if (percent >= 10) return '${percent.toStringAsFixed(1)}%';
    if (percent >= 1) return '${percent.toStringAsFixed(2)}%';
    return '${percent.toStringAsFixed(3)}%';
  }

  Future<void> _handleEnterLottery({
    required BuildContext context,
    required dynamic drawId,
    required String tier,
    required dynamic cost,
    required bool isSubscribed,
    required bool isLevelOk,
    required bool alreadyEntered,
  }) async {
    if (!isLevelOk || alreadyEntered) return;

    if (!isSubscribed) {
      await showDialog<void>(
        context: context,
        builder: (_) => const _SubscriptionRequiredDialog(),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmEntryDialog(
        tier: tier,
        costText: '€$cost',
      ),
    );

    if (confirm != true) return;

    try {
      await LotteryService().enterLottery(drawId);

      if (!context.mounted) return;

      // FX success locale
      setState(() => _successFxIds.add(drawId));
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _successFxIds.remove(drawId));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Hai partecipato con successo alla fascia $tier!'),
        ),
      );

      ref.invalidate(drawsProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(walletProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawsAsync = ref.watch(drawsProvider);
    final subAsync = ref.watch(subscriptionStatusProvider);
    final profileAsync = ref.watch(profileProvider);

    return AppScaffold(
      title: '',
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: profileAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      _CenteredError(message: 'Errore profilo: $err'),
                  data: (profile) {
                    final userLevel = profile?.level ?? 1;

                    return subAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) =>
                          _CenteredError(message: 'Errore abbonamento: $err'),
                      data: (isSubscribed) {
                        return drawsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) =>
                              _CenteredError(message: 'Errore: $err'),
                          data: (draws) {
                            final earliest = draws
                                .map((d) => _remaining(d))
                                .whereType<Duration>()
                                .toList()
                              ..sort((a, b) => a.compareTo(b));

                            final nextClose =
                                earliest.isNotEmpty ? earliest.first : null;

                            return Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 16),
                              child: ListView(
                                children: [
                                  _Header(
                                    isSubscribed: isSubscribed,
                                    userLevel: userLevel,
                                    userName: profile?.fullName,
                                  ),
                                  const SizedBox(height: 14),
                                  _HeroLotteryInfo(
                                    drawsCount: draws.length,
                                    isSubscribed: isSubscribed,
                                    nextClose: nextClose == null
                                        ? 'N/D'
                                        : _fmtDur(nextClose),
                                  ),
                                  const SizedBox(height: 14),
                                  if (draws.isEmpty)
                                    const _EmptyStateCard()
                                  else
                                    ...draws.map((draw) {
                                      final tier = (draw['tier'] ?? 'Standard')
                                          .toString();
                                      final cost = draw['entry_cost'] ?? 0;
                                      final id = draw['id'];
                                      final totalEntries =
                                          (draw['total_entries'] ?? 0) as int;
                                      final prizePool =
                                          ((draw['total_prize_pool'] ?? 0)
                                                  as num)
                                              .toDouble();
                                      final minLevel =
                                          (draw['min_level'] ?? 1) as int;
                                      final isLevelOk = userLevel >= minLevel;
                                      final alreadyEntered =
                                          _alreadyEntered(draw);
                                      final chance = _estimatedChance(
                                        totalEntries,
                                        alreadyEntered: alreadyEntered,
                                      );
                                      final remaining = _remaining(draw);

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: _LotteryTierCard(
                                          tier: tier,
                                          cost: cost,
                                          totalEntries: totalEntries,
                                          prizePool: prizePool,
                                          minLevel: minLevel,
                                          userLevel: userLevel,
                                          isLevelOk: isLevelOk,
                                          isSubscribed: isSubscribed,
                                          alreadyEntered: alreadyEntered,
                                          chanceLabel: _chanceLabel(chance),
                                          countdownText: remaining == null
                                              ? 'N/D'
                                              : _fmtDur(remaining),
                                          successFx: _successFxIds.contains(id),
                                          onEnter: () => _handleEnterLottery(
                                            context: context,
                                            drawId: id,
                                            tier: tier,
                                            cost: cost,
                                            isSubscribed: isSubscribed,
                                            isLevelOk: isLevelOk,
                                            alreadyEntered: alreadyEntered,
                                          ),
                                        ),
                                      );
                                    }),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      'Daily Lottery • Casino Premium Mode',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.mutedText
                                                .withValues(alpha: 0.85),
                                            letterSpacing: 0.2,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
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
            colors: [Color(0xFF0D0D0F), Color(0xFF15161A), Color(0xFF0D0D0F)],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isSubscribed;
  final int userLevel;
  final String? userName;

  const _Header({
    required this.isSubscribed,
    required this.userLevel,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (userName != null && userName!.trim().isNotEmpty)
        ? userName!.trim()
        : 'Giocatore';

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
                Icons.casino_rounded,
                color: AppTheme.goldSoft,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lotteria Giornaliera',
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
          'Ciao $displayName, scegli la fascia e tenta la fortuna.',
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
              icon: isSubscribed
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_outlined,
              text: isSubscribed ? 'Abbonato' : 'No sub',
              color: isSubscribed ? AppTheme.primaryGreen : AppTheme.goldSoft,
            ),
            _TinyPill(
              icon: Icons.star_rounded,
              text: 'LV $userLevel',
              color: AppTheme.goldSoft,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroLotteryInfo extends StatelessWidget {
  final int drawsCount;
  final bool isSubscribed;
  final String nextClose;

  const _HeroLotteryInfo({
    required this.drawsCount,
    required this.isSubscribed,
    required this.nextClose,
  });

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Panoramica eventi'),
          const SizedBox(height: 10),
          Text(
            drawsCount > 0
                ? 'Hai $drawsCount fasce attive. La prossima chiusura è tra $nextClose.'
                : 'Al momento non ci sono fasce disponibili.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.casino_outlined,
                  label: 'Fasce',
                  value: '$drawsCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.timer_outlined,
                  label: 'Prossima chiusura',
                  value: nextClose,
                  valueColor: AppTheme.goldSoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Accesso',
                  value: isSubscribed ? 'Premium' : 'Bloccato',
                  valueColor:
                      isSubscribed ? AppTheme.primaryGreen : AppTheme.goldSoft,
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

class _LotteryTierCard extends StatelessWidget {
  final String tier;
  final dynamic cost;
  final int totalEntries;
  final double prizePool;
  final int minLevel;
  final int userLevel;
  final bool isLevelOk;
  final bool isSubscribed;
  final bool alreadyEntered;
  final String chanceLabel;
  final String countdownText;
  final bool successFx;
  final VoidCallback onEnter;

  const _LotteryTierCard({
    required this.tier,
    required this.cost,
    required this.totalEntries,
    required this.prizePool,
    required this.minLevel,
    required this.userLevel,
    required this.isLevelOk,
    required this.isSubscribed,
    required this.alreadyEntered,
    required this.chanceLabel,
    required this.countdownText,
    required this.successFx,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final style = _tierStyle(tier);
    final canEnter = isLevelOk && !alreadyEntered;

    return AnimatedScale(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      scale: successFx ? 1.015 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: successFx
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: _LuxuryPanel(
          child: Stack(
            children: [
              if (successFx)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TierBadge(
                        tier: tier,
                        style: style,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fascia $tier',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      if (alreadyEntered)
                        _SmallStateChip(
                          text: 'Già dentro',
                          color: AppTheme.primaryGreen,
                          icon: Icons.check_circle_outline,
                        )
                      else if (!isSubscribed)
                        _SmallStateChip(
                          text: 'Premium',
                          color: AppTheme.goldSoft,
                          icon: Icons.lock_outline,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // countdown strip
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: style.accent.withValues(alpha: 0.07),
                      border: Border.all(
                        color: style.accent.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 16, color: style.accent),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Chiusura tra $countdownText',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: style.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

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
                        _InfoRow(
                          icon: Icons.payments_outlined,
                          label: 'Quota ingresso',
                          value: '€$cost',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.groups_rounded,
                          label: 'Partecipanti',
                          value: '$totalEntries',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.emoji_events_outlined,
                          label: 'Montepremi',
                          value: '€${prizePool.toStringAsFixed(2)}',
                          valueColor: style.accent,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.auto_graph_rounded,
                          label: 'Chance stimata',
                          value: chanceLabel,
                          valueColor: AppTheme.goldSoft,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.trending_up_rounded,
                          label: 'Livello richiesto',
                          value: 'LV $minLevel',
                          valueColor: isLevelOk
                              ? AppTheme.primaryGreen
                              : AppTheme.goldSoft,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  _AccessBanner(
                    isLevelOk: isLevelOk,
                    minLevel: minLevel,
                    userLevel: userLevel,
                    alreadyEntered: alreadyEntered,
                  ),

                  const SizedBox(height: 12),

                  _GradientActionButton(
                    onPressed: canEnter ? onEnter : null,
                    loading: false,
                    text: alreadyEntered
                        ? 'Partecipazione registrata'
                        : (isSubscribed ? 'Partecipa' : 'Richiede abbonamento'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessBanner extends StatelessWidget {
  final bool isLevelOk;
  final int minLevel;
  final int userLevel;
  final bool alreadyEntered;

  const _AccessBanner({
    required this.isLevelOk,
    required this.minLevel,
    required this.userLevel,
    required this.alreadyEntered,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = alreadyEntered
        ? AppTheme.primaryGreen
        : (isLevelOk ? AppTheme.primaryGreen : AppTheme.goldSoft);

    final String text = alreadyEntered
        ? '✅ Sei già registrato in questa fascia'
        : (isLevelOk
            ? 'Livello ok • Puoi partecipare (LV $userLevel)'
            : 'Bloccata • Richiede livello $minLevel (tu sei LV $userLevel)');

    final IconData icon = alreadyEntered
        ? Icons.verified_rounded
        : (isLevelOk ? Icons.check_circle_outline : Icons.lock_outline_rounded);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent.withValues(alpha: 0.95)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accent.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionRequiredDialog extends StatelessWidget {
  const _SubscriptionRequiredDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldLuxury.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.goldSoft.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.goldSoft,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Abbonamento richiesto',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Devi avere un abbonamento attivo per partecipare alla lotteria giornaliera.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Chiudi'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.pushNamed(AppRoutes.subscription),
                    child: const Text('Abbonati'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmEntryDialog extends StatelessWidget {
  final String tier;
  final String costText;

  const _ConfirmEntryDialog({
    required this.tier,
    required this.costText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Conferma partecipazione',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.02),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.emoji_events_outlined,
                    label: 'Fascia',
                    value: tier,
                    valueColor: AppTheme.goldSoft,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Quota',
                    value: costText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(false),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GradientActionButton(
                    onPressed: () => context.pop(true),
                    loading: false,
                    text: 'Conferma',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _dialogDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF202127), Color(0xFF15161B)],
    ),
    border: Border.all(color: AppTheme.goldLuxury.withValues(alpha: 0.24)),
    boxShadow: [
      BoxShadow(
        color: AppTheme.goldLuxury.withValues(alpha: 0.07),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
      const BoxShadow(
        color: Colors.black54,
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  );
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
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
              Icons.event_busy_outlined,
              color: AppTheme.goldSoft,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nessuna estrazione disponibile oggi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Torna più tardi per nuove fasce giornaliere.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
          ),
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
          Icon(icon,
              size: 16, color: AppTheme.mutedText.withValues(alpha: 0.95)),
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

class _TierStyle {
  final Color accent;
  final IconData icon;
  final List<Color> gradient;

  const _TierStyle({
    required this.accent,
    required this.icon,
    required this.gradient,
  });
}

_TierStyle _tierStyle(String tier) {
  final t = tier.toLowerCase();

  if (t.contains('vip') || t.contains('diamond')) {
    return const _TierStyle(
      accent: AppTheme.goldSoft,
      icon: Icons.diamond_outlined,
      gradient: [Color(0x44FFD76A), Color(0x11000000)],
    );
  }

  if (t.contains('gold')) {
    return const _TierStyle(
      accent: AppTheme.goldSoft,
      icon: Icons.workspace_premium_outlined,
      gradient: [Color(0x33FFD76A), Color(0x11000000)],
    );
  }

  if (t.contains('silver')) {
    return const _TierStyle(
      accent: Color(0xFFC9CED8),
      icon: Icons.military_tech_outlined,
      gradient: [Color(0x33C9CED8), Color(0x11000000)],
    );
  }

  if (t.contains('bronze')) {
    return const _TierStyle(
      accent: Color(0xFFC98A5A),
      icon: Icons.local_fire_department,
      gradient: [Color(0x33C98A5A), Color(0x11000000)],
    );
  }

  return const _TierStyle(
    accent: AppTheme.primaryGreen,
    icon: Icons.local_fire_department,
    gradient: [Color(0x331D8548), Color(0x11000000)],
  );
}

class _TierBadge extends StatelessWidget {
  final String tier;
  final _TierStyle style;

  const _TierBadge({
    required this.tier,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: style.gradient),
        border: Border.all(color: style.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(style.icon, size: 16, color: style.accent),
          const SizedBox(width: 6),
          Text(
            tier,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: style.accent,
                ),
          ),
        ],
      ),
    );
  }
}

class _SmallStateChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _SmallStateChip({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
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
        Icon(icon, size: 16, color: AppTheme.mutedText.withValues(alpha: 0.95)),
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
