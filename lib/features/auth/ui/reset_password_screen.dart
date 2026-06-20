import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../widget/app_scaffold.dart';
import '../../../router.dart';
import '../../../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();

  String? _message;
  bool _loading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Inserisci la tua email.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    final redirectTo =
        kIsWeb ? '${Uri.base.origin}/new-password' : 'kash://auth-callback';

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );

      if (!mounted) return;

      setState(() {
        _message =
            'Se l’email è registrata, riceverai un link per impostare la nuova password.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Controlla la tua email e apri il link ricevuto.'),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _message = '❌ ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = '❌ Errore: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '',
      body: Stack(
        children: [
          // Background luxury
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recupera la password',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inserisci la tua email e ti invieremo un link per impostare una nuova password.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                      ),
                      const SizedBox(height: 18),
                      _LuxuryPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _TinyBadgeIcon(
                                  icon: Icons.mark_email_read_outlined,
                                  gold: true,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Reset password',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _LuxuryInput(
                              controller: _emailController,
                              enabled: !_loading,
                              hintText: 'Email',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  _loading ? null : _sendResetEmail(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color:
                                      AppTheme.mutedText.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Controlla anche la cartella spam o promozioni.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppTheme.mutedText,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 12),
                              _StatusBanner(message: _message!),
                            ],
                            const SizedBox(height: 14),
                            _GradientActionButton(
                              onPressed: _loading ? null : _sendResetEmail,
                              loading: _loading,
                              text: 'Invia email di reset',
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context.goNamed(AppRoutes.login),
                                child: const Text('Torna al login'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Password recovery • Kash Security',
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
          colors: [
            Color(0xFF202127),
            Color(0xFF15161B),
          ],
        ),
        border: Border.all(
          color: AppTheme.goldLuxury.withValues(alpha: 0.26),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldLuxury.withValues(alpha: 0.07),
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

/// Input premium con focus gestito dal tema globale (AppTheme.inputDecorationTheme)
class _LuxuryInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _LuxuryInput({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          color: AppTheme.mutedText.withValues(alpha: 0.9),
          size: 20,
        ),
      ),
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
      opacity: disabled ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldLuxury.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isError = message.startsWith('❌');
    final accent = isError ? Colors.redAccent : AppTheme.primaryGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 16,
            color: accent.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isError ? message.replaceFirst('❌ ', '') : message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accent.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadgeIcon extends StatelessWidget {
  final IconData icon;
  final bool gold;

  const _TinyBadgeIcon({
    required this.icon,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = gold ? AppTheme.goldSoft : AppTheme.primaryGreen;

    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.20),
            accent.withValues(alpha: 0.07),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(
        icon,
        size: 17,
        color: gold ? AppTheme.goldSoft : Colors.white,
      ),
    );
  }
}
