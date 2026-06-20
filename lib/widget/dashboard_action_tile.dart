import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'luxury_box.dart';

class DashboardActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool goldAccent;

  const DashboardActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.goldAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = goldAccent ? AppTheme.goldSoft : AppTheme.primaryGreen;

    return LuxuryBox(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: goldAccent
                    ? [
                        AppTheme.goldLuxury.withValues(alpha: 0.25),
                        AppTheme.goldSoft.withValues(alpha: 0.10),
                      ]
                    : [
                        AppTheme.primaryGreen.withValues(alpha: 0.22),
                        AppTheme.primaryGreen.withValues(alpha: 0.08),
                      ],
              ),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: goldAccent ? AppTheme.goldSoft : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText.withValues(alpha: 0.95),
                  height: 1.15,
                ),
          ),
        ],
      ),
    );
  }
}
