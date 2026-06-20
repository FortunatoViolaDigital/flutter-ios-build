import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'change_password_dialog.dart';
import '../../../widget/app_scaffold.dart';
import '../../../router.dart';

// ✅ provider centralizzati
import '../../../providers/app_providers.dart';

// (opzionale) se in account mostri/usi wallet
import '../../wallet/controller/wallet_controller.dart';
import '../../../widget/refreshing_consumer_state.dart';
import '../../../theme/app_theme.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends RefreshingConsumerState<AccountScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  void onRouteVisible() {
    // ✅ quando entri o torni su Account aggiorna i dati base
    ref.invalidate(profileProvider);
    ref.invalidate(subscriptionStatusProvider);

    // opzionale
    ref.invalidate(walletProvider);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutConfirmDialog(),
    );

    if (confirm != true) return;

    await Supabase.instance.client.auth.signOut();

    // ✅ pulizia cache
    ref.invalidate(profileProvider);
    ref.invalidate(subscriptionStatusProvider);
    ref.invalidate(subscriptionDetailsProvider);
    ref.invalidate(todayWinnersProvider);
    ref.invalidate(drawsProvider);
    ref.invalidate(walletProvider);

    if (mounted) {
      context.goNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = ref.watch(profileProvider);
    final subscriptionAsync = ref.watch(subscriptionStatusProvider);

    return AppScaffold(
      title: '',
      body: Stack(
        children: [
          // Background luxury gradient
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ListView(
                    children: [
                      const _AccountHeader(),
                      const SizedBox(height: 16),

                      // HERO ACCOUNT BOX
                      profileAsync.when(
                        loading: () => const _LuxuryPanel(
                          child: SizedBox(
                            height: 140,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        error: (_, __) => _buildIdentityCard(
                          context,
                          userEmail: user?.email ?? 'N/A',
                          fullName: null,
                          avatarUrl: null,
                          level: null,
                        ),
                        data: (profile) => _buildIdentityCard(
                          context,
                          userEmail: user?.email ?? 'N/A',
                          fullName: profile?.fullName,
                          avatarUrl: profile?.avatarUrl,
                          level: profile?.level,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Subscription state box (se vuoi tenerlo visibile)
                      _LuxuryPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(context, 'Abbonamento'),
                            const SizedBox(height: 10),
                            subscriptionAsync.when(
                              loading: () => const SizedBox(
                                height: 22,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              error: (_, __) => _InfoRow(
                                icon: Icons.workspace_premium_outlined,
                                label: 'Stato',
                                value: 'Non disponibile',
                              ),
                              data: (isActive) => _InfoRow(
                                icon: Icons.workspace_premium_outlined,
                                label: 'Stato',
                                value: isActive ? 'Attivo' : 'Non attivo',
                                valueColor: isActive
                                    ? AppTheme.primaryGreen
                                    : AppTheme.goldSoft,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _LuxuryPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(context, 'Attività'),
                            const SizedBox(height: 12),
                            _ActionTile(
                              icon: Icons.receipt_long_rounded,
                              title: 'Storico movimenti',
                              subtitle: 'Wallet, lotterie, abbonamenti e bonus',
                              gold: true,
                              onTap: () =>
                                  context.pushNamed(AppRoutes.transactions),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // AZIONI ACCOUNT
                      _LuxuryPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(context, 'Gestione account'),
                            const SizedBox(height: 12),
                            _ActionTile(
                              icon: Icons.edit_outlined,
                              title: 'Modifica profilo',
                              subtitle: 'Nome, avatar e dati account',
                              onTap: () =>
                                  context.pushNamed(AppRoutes.editProfile),
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.lock_reset_rounded,
                              title: 'Cambia password',
                              subtitle: 'Aggiorna le credenziali di accesso',
                              gold: true,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const ChangePasswordDialog(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // DANGER ZONE
                      _LuxuryPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(context, 'Sicurezza'),
                            const SizedBox(height: 12),
                            _DangerTile(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              subtitle:
                                  'Esci dal tuo account su questo dispositivo',
                              onTap: _logout,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: Text(
                          'Kash Account • Premium UI',
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(
    BuildContext context, {
    required String userEmail,
    String? fullName,
    String? avatarUrl,
    int? level,
  }) {
    final displayName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : 'Utente Kash';

    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                    ),
                  ],
                ),
              ),
              if (level != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.goldLuxury.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppTheme.goldSoft.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    'LV $level',
                    style: const TextStyle(
                      color: AppTheme.goldSoft,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
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
              children: const [
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Stato account',
                  value: 'Attivo',
                  valueColor: AppTheme.primaryGreen,
                ),
                SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.shield_outlined,
                  label: 'Sicurezza',
                  value: 'Gestita da Supabase',
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

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
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
            Icons.manage_accounts_rounded,
            color: AppTheme.goldSoft,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Gestione Account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202127), Color(0xFF15161B)],
        ),
        border: Border.all(
          color: AppTheme.goldLuxury.withValues(alpha: 0.24),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldLuxury.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 0.5,
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
        Icon(
          icon,
          size: 17,
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
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool gold;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = gold ? AppTheme.goldSoft : AppTheme.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.20),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: gold ? AppTheme.goldSoft : Colors.white,
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
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.mutedText.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.redAccent.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: Colors.redAccent.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: Colors.redAccent.withValues(alpha: 0.95),
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
                            color: Colors.redAccent.withValues(alpha: 0.95),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.redAccent.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1B20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.goldLuxury.withValues(alpha: 0.20),
        ),
      ),
      title: const Text('Conferma logout'),
      content: const Text('Vuoi davvero uscire dal tuo account?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
