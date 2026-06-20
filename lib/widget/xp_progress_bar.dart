import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class XPProgressBar extends StatelessWidget {
  final int xp;
  final int level;

  const XPProgressBar({
    super.key,
    required this.xp,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    const xpPerLevel = 100;

    final currentLevelXP = xp % xpPerLevel;
    final progress = (currentLevelXP / xpPerLevel).clamp(0.0, 1.0);
    final xpToNext = xpPerLevel - currentLevelXP;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: 0.01),
          ],
        ),
        border: Border.all(
          color: AppTheme.goldSoft.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riga header
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppTheme.goldSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Livello $level',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppTheme.primaryGreen.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.30),
                  ),
                ),
                child: Text(
                  '$currentLevelXP / $xpPerLevel XP',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Barra custom
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 12,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.06),
              child: Stack(
                children: [
                  // Fill progress
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.goldLuxury,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldLuxury.withValues(alpha: 0.18),
                            blurRadius: 8,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Highlight top line
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Riga info sotto
          Row(
            children: [
              Text(
                'Progresso livello',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedText.withValues(alpha: 0.95),
                    ),
              ),
              const Spacer(),
              Text(
                xpToNext == xpPerLevel
                    ? 'Pronto a salire'
                    : '$xpToNext XP al prossimo livello',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.goldSoft,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
