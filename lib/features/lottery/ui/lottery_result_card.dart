import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class LotteryResultCard extends StatefulWidget {
  final List<Map<String, dynamic>> results;
  final String? currentUserId;

  const LotteryResultCard({
    super.key,
    required this.results,
    this.currentUserId,
  });

  @override
  State<LotteryResultCard> createState() => _LotteryResultCardState();
}

class _LotteryResultCardState extends State<LotteryResultCard>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  late final AnimationController _podiumCtrl;
  late final Animation<double> _podiumFade;
  late final Animation<Offset> _firstSlide;
  late final Animation<Offset> _secondSlide;
  late final Animation<Offset> _thirdSlide;

  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _podiumCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _podiumFade = CurvedAnimation(parent: _podiumCtrl, curve: Curves.easeOut);

    _secondSlide = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _podiumCtrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    ));

    _firstSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _podiumCtrl,
      curve: const Interval(0.12, 1.0, curve: Curves.easeOutBack),
    ));

    _thirdSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _podiumCtrl,
      curve: const Interval(0.05, 0.85, curve: Curves.easeOutCubic),
    ));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeCtrl.forward();
    _podiumCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _podiumCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LotteryResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results) {
      _fadeCtrl.forward(from: 0);
      _podiumCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.results;

    if (results.isEmpty) {
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
                Icons.emoji_events_outlined,
                color: AppTheme.goldSoft,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nessun vincitore oggi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'I risultati appariranno qui dopo l’estrazione.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
          ],
        ),
      );
    }

    final sorted = [...results]..sort((a, b) {
        final pa = (a['position'] ?? 999) as int;
        final pb = (b['position'] ?? 999) as int;
        return pa.compareTo(pb);
      });

    Map<String, dynamic>? first;
    Map<String, dynamic>? second;
    Map<String, dynamic>? third;

    for (final r in sorted) {
      final p = r['position'];
      if (p == 1) first = r;
      if (p == 2) second = r;
      if (p == 3) third = r;
    }

    final others = sorted.where((r) {
      final p = r['position'] as int? ?? 999;
      return p > 3;
    }).toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultsHeader(
            total: sorted.length,
            onSeeAll: () => _openAllResultsBottomSheet(context, sorted),
          ),
          const SizedBox(height: 12),
          if (first != null || second != null || third != null) ...[
            _LuxuryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(text: 'Podio'),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _podiumFade,
                    child: _HorizontalPodium(
                      first: first,
                      second: second,
                      third: third,
                      firstSlide: _firstSlide,
                      secondSlide: _secondSlide,
                      thirdSlide: _thirdSlide,
                      glowAnimation: _glowCtrl,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (others.isNotEmpty)
            _LuxuryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(text: 'Altri vincitori'),
                  const SizedBox(height: 10),
                  ...others.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i == others.length - 1 ? 0 : 10),
                      child: _WinnerTile(
                        result: r,
                        currentUserId: widget.currentUserId,
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openAllResultsBottomSheet(
    BuildContext context,
    List<Map<String, dynamic>> allResults,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF131419),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          'Tutti i risultati',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const Spacer(),
                        _TinyChip(
                          icon: Icons.list_alt_rounded,
                          text: '${allResults.length}',
                          color: AppTheme.goldSoft,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: allResults.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _WinnerTile(
                            result: allResults[i],
                            currentUserId: widget.currentUserId,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// ======================================================
/// HEADER
/// ======================================================

class _ResultsHeader extends StatelessWidget {
  final int total;
  final VoidCallback onSeeAll;

  const _ResultsHeader({
    required this.total,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppTheme.goldLuxury, AppTheme.primaryGreen],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldLuxury.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vincitori di oggi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total vincitori estratti',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Vedi tutti'),
          ),
        ],
      ),
    );
  }
}

/// ======================================================
/// PODIO ORIZZONTALE ANIMATO
/// ======================================================

class _HorizontalPodium extends StatelessWidget {
  final Map<String, dynamic>? first;
  final Map<String, dynamic>? second;
  final Map<String, dynamic>? third;
  final Animation<Offset> firstSlide;
  final Animation<Offset> secondSlide;
  final Animation<Offset> thirdSlide;
  final Animation<double> glowAnimation;
  final String? currentUserId;

  const _HorizontalPodium({
    required this.first,
    required this.second,
    required this.third,
    required this.firstSlide,
    required this.secondSlide,
    required this.thirdSlide,
    required this.glowAnimation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (first != null)
          SlideTransition(
            position: firstSlide,
            child: AnimatedBuilder(
              animation: glowAnimation,
              builder: (context, child) {
                final t = glowAnimation.value;
                final pulse = 0.08 + (t * 0.12);

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldSoft.withValues(alpha: pulse),
                        blurRadius: 18 + (t * 10),
                        spreadRadius: 1 + (t * 1.5),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: _PodiumColumn(
                result: first,
                position: 1,
                height: 140,
                avatarSize: 30,
                highlight: true,
                currentUserId: currentUserId,
              ),
            ),
          ),
        const SizedBox(height: 14),
        if (second != null)
          SlideTransition(
            position: secondSlide,
            child: _PodiumColumn(
              result: second,
              position: 2,
              height: 120,
              avatarSize: 26,
              currentUserId: currentUserId,
            ),
          ),
        const SizedBox(height: 14),
        if (third != null)
          SlideTransition(
            position: thirdSlide,
            child: _PodiumColumn(
              result: third,
              position: 3,
              height: 110,
              avatarSize: 24,
              currentUserId: currentUserId,
            ),
          ),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final Map<String, dynamic>? result;
  final int position;
  final double height;
  final double avatarSize;
  final bool highlight;
  final String? currentUserId;

  const _PodiumColumn({
    required this.result,
    required this.position,
    required this.height,
    required this.avatarSize,
    this.highlight = false,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final style = _positionStyle(position);

    if (result == null) {
      return Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            _AvatarCircle(
              size: avatarSize + 8,
              imageUrl: null,
              fallbackLabel: '?',
              borderColor: style.accent.withValues(alpha: 0.20),
            ),
            const SizedBox(height: 8),
            Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.02),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final prizeRaw = result!['prize'] ?? result!['prize_amount'] ?? 0;
    final prize = (prizeRaw is num)
        ? prizeRaw.toDouble().toStringAsFixed(0)
        : prizeRaw.toString();

    final userId = (result!['user_id'] ?? '').toString();
    final avatarUrl = result!['avatar_url']?.toString();
    final tier = (result!['tier'] ?? 'N/D').toString();
    final isMe = currentUserId != null && currentUserId == userId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (highlight)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppTheme.goldSoft.withValues(alpha: 0.12),
              border: Border.all(
                color: AppTheme.goldSoft.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              'TOP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.goldSoft,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _AvatarCircle(
              size: avatarSize + 8,
              imageUrl: avatarUrl,
              fallbackLabel: _shortName(userId),
              borderColor: style.accent.withValues(alpha: 0.35),
              glowColor: highlight
                  ? style.accent.withValues(alpha: 0.14)
                  : Colors.transparent,
            ),
            if (isMe)
              Positioned(
                right: -6,
                bottom: -4,
                child: _TinyChip(
                  icon: Icons.person,
                  text: 'YOU',
                  color: AppTheme.primaryGreen,
                  compact: true,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _shortUser(userId),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                style.accent.withValues(alpha: 0.16),
                const Color(0xFF18191E),
              ],
            ),
            border: Border.all(
              color: style.accent.withValues(alpha: 0.28),
            ),
            boxShadow: [
              if (highlight)
                BoxShadow(
                  color: style.accent.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PositionMiniBadge(position: position, style: style),
                Column(
                  children: [
                    Text(
                      '€$prize',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: style.accent,
                          ),
                    ),
                    const SizedBox(height: 4),
                    _TinyChip(
                      icon: _tierIcon(tier),
                      text: tier,
                      color: _tierAccent(tier),
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _shortUser(String raw) {
    if (raw.isEmpty) return 'Utente';
    if (raw.length <= 6) return raw.toUpperCase();
    return '${raw.substring(0, 4)}••';
  }

  String _shortName(String raw) {
    if (raw.isEmpty) return 'U';
    return raw.characters.first.toUpperCase();
  }

  IconData _tierIcon(String tier) {
    final t = tier.toLowerCase();
    if (t.contains('vip') || t.contains('diamond'))
      return Icons.diamond_outlined;
    if (t.contains('gold')) return Icons.workspace_premium_outlined;
    if (t.contains('silver')) return Icons.military_tech_outlined;
    if (t.contains('bronze')) return Icons.local_fire_department;
    return Icons.casino_outlined;
  }

  Color _tierAccent(String tier) {
    final t = tier.toLowerCase();
    if (t.contains('vip') || t.contains('diamond')) return AppTheme.goldSoft;
    if (t.contains('gold')) return AppTheme.goldSoft;
    if (t.contains('silver')) return const Color(0xFFC9CED8);
    if (t.contains('bronze')) return const Color(0xFFC98A5A);
    return AppTheme.primaryGreen;
  }
}

class _PositionMiniBadge extends StatelessWidget {
  final int position;
  final _PositionStyle style;

  const _PositionMiniBadge({
    required this.position,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.accent.withValues(alpha: 0.12),
        border: Border.all(
          color: style.accent.withValues(alpha: 0.30),
        ),
      ),
      child: Center(
        child: Text(
          '$position',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: style.accent,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

/// ======================================================
/// LISTA ALTRI VINCITORI
/// ======================================================

class _WinnerTile extends StatelessWidget {
  final Map<String, dynamic> result;
  final String? currentUserId;

  const _WinnerTile({
    required this.result,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final position = result['position'] ?? '-';
    final prizeRaw = result['prize'] ?? result['prize_amount'] ?? 0;
    final tier = (result['tier'] ?? 'N/D').toString();
    final userId = (result['user_id'] ?? 'unknown').toString();
    final avatarUrl = result['avatar_url']?.toString();
    final isMe = currentUserId != null && currentUserId == userId;

    final prize = (prizeRaw is num)
        ? prizeRaw.toDouble().toStringAsFixed(2)
        : prizeRaw.toString();

    final style = _positionStyle(
        position is int ? position : int.tryParse('$position') ?? 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          _PositionBadge(position: position, style: style),
          const SizedBox(width: 10),
          _AvatarCircle(
            size: 18,
            imageUrl: avatarUrl,
            fallbackLabel: _initial(userId),
            borderColor: Colors.white.withValues(alpha: 0.10),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _maskUser(userId),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      _TinyChip(
                        icon: Icons.person,
                        text: 'YOU',
                        color: AppTheme.primaryGreen,
                        compact: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                _TinyChip(
                  icon: _tierIcon(tier),
                  text: tier,
                  color: _tierAccent(tier),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Premio',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '€$prize',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: style.accent,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _maskUser(String raw) {
    if (raw.length <= 6) return 'Utente ${raw.toUpperCase()}';
    final start = raw.substring(0, 4);
    final end = raw.substring(raw.length - 2);
    return 'Utente $start••$end';
  }

  String _initial(String raw) {
    if (raw.isEmpty) return 'U';
    return raw.characters.first.toUpperCase();
  }

  IconData _tierIcon(String tier) {
    final t = tier.toLowerCase();
    if (t.contains('vip') || t.contains('diamond'))
      return Icons.diamond_outlined;
    if (t.contains('gold')) return Icons.workspace_premium_outlined;
    if (t.contains('silver')) return Icons.military_tech_outlined;
    if (t.contains('bronze')) return Icons.local_fire_department;
    return Icons.casino_outlined;
  }

  Color _tierAccent(String tier) {
    final t = tier.toLowerCase();
    if (t.contains('vip') || t.contains('diamond')) return AppTheme.goldSoft;
    if (t.contains('gold')) return AppTheme.goldSoft;
    if (t.contains('silver')) return const Color(0xFFC9CED8);
    if (t.contains('bronze')) return const Color(0xFFC98A5A);
    return AppTheme.primaryGreen;
  }
}

/// ======================================================
/// AVATAR
/// ======================================================

class _AvatarCircle extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final String fallbackLabel;
  final Color borderColor;
  final Color? glowColor;

  const _AvatarCircle({
    required this.size,
    required this.imageUrl,
    required this.fallbackLabel,
    required this.borderColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: [
          if (glowColor != null && glowColor != Colors.transparent)
            BoxShadow(
              color: glowColor!,
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: CircleAvatar(
        radius: size,
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
        child: hasImage
            ? null
            : Text(
                fallbackLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
      ),
    );
  }
}

/// ======================================================
/// SHIMMER LOADING
/// ======================================================

class LotteryResultCardShimmer extends StatelessWidget {
  const LotteryResultCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        children: [
          _LuxuryPanel(
            child: Row(
              children: [
                _skeletonBox(42, 42, circular: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonLine(width: 140, height: 14),
                      const SizedBox(height: 6),
                      _skeletonLine(width: 90, height: 10),
                    ],
                  ),
                ),
                _skeletonBox(70, 26, circular: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _LuxuryPanel(
            child: Column(
              children: [
                _skeletonLine(width: 80, height: 12),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _podiumSkeleton(110)),
                    const SizedBox(width: 8),
                    Expanded(child: _podiumSkeleton(145)),
                    const SizedBox(width: 8),
                    Expanded(child: _podiumSkeleton(100)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _LuxuryPanel(
            child: Column(
              children: [
                _winnerRowSkeleton(),
                const SizedBox(height: 10),
                _winnerRowSkeleton(),
                const SizedBox(height: 10),
                _winnerRowSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _podiumSkeleton(double height) {
    return Column(
      children: [
        _skeletonBox(34, 34, circular: true),
        const SizedBox(height: 8),
        _skeletonLine(width: 52, height: 10),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ],
    );
  }

  static Widget _winnerRowSkeleton() {
    return Row(
      children: [
        _skeletonBox(42, 42, circular: true),
        const SizedBox(width: 10),
        _skeletonBox(36, 36, circular: true),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonLine(width: 120, height: 12),
              const SizedBox(height: 6),
              _skeletonLine(width: 70, height: 10),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _skeletonLine(width: 50, height: 14),
      ],
    );
  }

  static Widget _skeletonLine({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }

  static Widget _skeletonBox(
    double w,
    double h, {
    bool circular = false,
  }) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return ShaderMask(
          shaderCallback: (rect) {
            final width = rect.width;
            final dx = (t * (width * 2)) - width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.00),
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.00),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _SlidingGradientTransform(dx),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double dx;

  const _SlidingGradientTransform(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// ======================================================
/// HELPERS UI
/// ======================================================

class _PositionStyle {
  final Color accent;
  final IconData icon;
  final String label;

  const _PositionStyle({
    required this.accent,
    required this.icon,
    required this.label,
  });
}

_PositionStyle _positionStyle(int position) {
  switch (position) {
    case 1:
      return const _PositionStyle(
        accent: AppTheme.goldSoft,
        icon: Icons.emoji_events_rounded,
        label: '1° posto',
      );
    case 2:
      return const _PositionStyle(
        accent: Color(0xFFC9CED8),
        icon: Icons.workspace_premium_outlined,
        label: '2° posto',
      );
    case 3:
      return const _PositionStyle(
        accent: Color(0xFFC98A5A),
        icon: Icons.military_tech_outlined,
        label: '3° posto',
      );
    default:
      return const _PositionStyle(
        accent: AppTheme.primaryGreen,
        icon: Icons.stars_rounded,
        label: 'Vincitore',
      );
  }
}

class _PositionBadge extends StatelessWidget {
  final dynamic position;
  final _PositionStyle style;

  const _PositionBadge({
    required this.position,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            style.accent.withValues(alpha: 0.22),
            style.accent.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: style.accent.withValues(alpha: 0.35),
        ),
      ),
      child: Center(
        child: Text(
          '#$position',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: style.accent,
              ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _TinyChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool compact;

  const _TinyChip({
    required this.icon,
    required this.text,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 20 : 24,
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: color),
          SizedBox(width: compact ? 3 : 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 9.5 : null,
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
        borderRadius: BorderRadius.circular(18),
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
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
