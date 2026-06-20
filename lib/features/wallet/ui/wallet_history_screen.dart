import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';
import '../../../widget/app_scaffold.dart';

final walletHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await Supabase.instance.client
      .from('wallet_transactions')
      .select(
          'id, created_at, amount_cents, kind, description, provider, status')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);

  return List<Map<String, dynamic>>.from(res);
});

class WalletHistoryScreen extends ConsumerStatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  ConsumerState<WalletHistoryScreen> createState() =>
      _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends ConsumerState<WalletHistoryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(walletHistoryProvider);

    return AppScaffold(
      title: '',
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: historyAsync.when(
                loading: () => const _HistoryLoadingView(),
                error: (e, _) => _CenteredError(message: 'Errore: $e'),
                data: (items) {
                  final filtered = items.where((tx) {
                    if (_filter == 'all') return true;
                    final kind = (tx['kind'] ?? '').toString();
                    return kind == _filter;
                  }).toList();

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _Header(totalCount: items.length),
                      const SizedBox(height: 14),
                      _HistorySummaryCard(items: items),
                      const SizedBox(height: 14),
                      _FilterBar(
                        selected: _filter,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                      const SizedBox(height: 14),
                      if (filtered.isEmpty)
                        const _EmptyHistoryCard()
                      else
                        ...filtered.map((tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TransactionTile(tx: tx),
                            )),
                    ],
                  );
                },
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

class _Header extends StatelessWidget {
  final int totalCount;

  const _Header({required this.totalCount});

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
                Icons.receipt_long_rounded,
                color: AppTheme.goldSoft,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Movimenti',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Storico completo delle operazioni wallet e account.',
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
              icon: Icons.history_rounded,
              text: '$totalCount movimenti',
              color: AppTheme.goldSoft,
            ),
          ],
        ),
      ],
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _HistorySummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final positive =
        items.where((e) => ((e['amount_cents'] ?? 0) as num) > 0).length;
    final negative =
        items.where((e) => ((e['amount_cents'] ?? 0) as num) < 0).length;

    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Panoramica'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Entrate',
                  value: '$positive',
                  valueColor: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Uscite',
                  value: '$negative',
                  valueColor: AppTheme.goldSoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.receipt_rounded,
                  label: 'Totali',
                  value: '${items.length}',
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

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = <MapEntry<String, String>>[
      const MapEntry('all', 'Tutti'),
      const MapEntry('topup', 'Ricariche'),
      const MapEntry('lottery_entry', 'Lotterie'),
      const MapEntry('lottery_win', 'Vincite'),
      const MapEntry('subscription_fee', 'Abbonamento'),
      const MapEntry('referral_bonus', 'Bonus'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final active = selected == f.key;
        final color = active ? AppTheme.goldSoft : Colors.white70;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(f.key),
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active
                    ? AppTheme.goldSoft.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: active
                      ? AppTheme.goldSoft.withValues(alpha: 0.28)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                f.value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amountCents = (tx['amount_cents'] ?? 0) as num;
    final amount = amountCents / 100;
    final isPositive = amountCents > 0;
    final kind = (tx['kind'] ?? '').toString();
    final description = (tx['description'] ?? _kindLabel(kind)).toString();
    final createdAt =
        DateTime.tryParse((tx['created_at'] ?? '').toString())?.toLocal();
    final provider = (tx['provider'] ?? '').toString();

    final accent = isPositive ? AppTheme.primaryGreen : AppTheme.goldSoft;
    final sign = isPositive ? '+' : '';

    return _LuxuryPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withValues(alpha: 0.10),
              border: Border.all(
                color: accent.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(
              _kindIcon(kind),
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TinyPill(
                      icon: _kindIcon(kind),
                      text: _kindLabel(kind),
                      color: accent,
                    ),
                    if (provider.isNotEmpty)
                      _TinyPill(
                        icon: Icons.link_rounded,
                        text: provider,
                        color: Colors.white70,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$sign€${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
          ),
        ],
      ),
    );
  }

  static IconData _kindIcon(String kind) {
    switch (kind) {
      case 'topup':
      case 'test_topup':
        return Icons.add_card_rounded;
      case 'lottery_entry':
        return Icons.local_activity_outlined;
      case 'lottery_win':
        return Icons.emoji_events_outlined;
      case 'subscription_fee':
        return Icons.workspace_premium_outlined;
      case 'referral_bonus':
        return Icons.card_giftcard_rounded;
      case 'refund':
        return Icons.replay_circle_filled_outlined;
      case 'withdrawal':
        return Icons.outbox_outlined;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  static String _kindLabel(String kind) {
    switch (kind) {
      case 'topup':
        return 'Ricarica';
      case 'test_topup':
        return 'Test';
      case 'lottery_entry':
        return 'Ingresso lotteria';
      case 'lottery_win':
        return 'Vincita';
      case 'subscription_fee':
        return 'Abbonamento';
      case 'referral_bonus':
        return 'Bonus referral';
      case 'refund':
        return 'Rimborso';
      case 'withdrawal':
        return 'Prelievo';
      default:
        return 'Movimento';
    }
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return 'Data non disponibile';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} • '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

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
              Icons.receipt_long_rounded,
              color: AppTheme.goldSoft,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nessun movimento disponibile',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quando inizierai a usare wallet, lotterie e bonus, vedrai qui tutto il tuo storico.',
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

class _HistoryLoadingView extends StatelessWidget {
  const _HistoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _SkeletonPanel(height: 110),
        SizedBox(height: 14),
        _SkeletonPanel(height: 110),
        SizedBox(height: 14),
        _SkeletonPanel(height: 90),
        SizedBox(height: 10),
        _SkeletonPanel(height: 90),
        SizedBox(height: 10),
        _SkeletonPanel(height: 90),
      ],
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

class _SkeletonPanel extends StatelessWidget {
  final double height;

  const _SkeletonPanel({required this.height});

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
