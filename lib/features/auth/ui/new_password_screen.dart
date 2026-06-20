import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../widget/app_scaffold.dart';
import '../../../router.dart';
import '../../../theme/app_theme.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _pwd = TextEditingController();
  final _confirmPwd = TextEditingController();

  bool _loading = false;
  String? _msg;
  bool _obscure = true;
  bool _obscureConfirm = true;

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
    _pwd.dispose();
    _confirmPwd.dispose();
    super.dispose();
  }

  double get _passwordStrength {
    final p = _pwd.text;
    if (p.isEmpty) return 0;
    double score = 0;
    if (p.length >= 8) score += 0.35;
    if (p.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(p)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(p)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\]').hasMatch(p)) score += 0.15;
    return score.clamp(0, 1);
  }

  String get _passwordStrengthLabel {
    final s = _passwordStrength;
    if (s == 0) return 'Inserisci una password';
    if (s < 0.4) return 'Debole';
    if (s < 0.75) return 'Media';
    return 'Forte';
  }

  Color get _passwordStrengthColor {
    final s = _passwordStrength;
    if (s < 0.4) return Colors.redAccent;
    if (s < 0.75) return AppTheme.goldLuxury;
    return AppTheme.primaryGreen;
  }

  Future<void> _update() async {
    FocusScope.of(context).unfocus();

    final p = _pwd.text.trim();
    final c = _confirmPwd.text.trim();

    if (p.length < 8) {
      setState(() => _msg = 'La password deve avere almeno 8 caratteri.');
      return;
    }

    if (p != c) {
      setState(() => _msg = 'Le password non coincidono.');
      return;
    }

    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: p),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Password aggiornata.')),
      );

      context.goNamed(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = 'Errore: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordsMatch =
        _confirmPwd.text.isEmpty || _pwd.text == _confirmPwd.text;

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
                      const SizedBox(height: 4),
                      Text(
                        'Imposta una nuova password',
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
                        'Scegli una password sicura per proteggere il tuo account.',
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
                                  icon: Icons.lock_reset_rounded,
                                  gold: true,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Nuova password',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _LuxuryInput(
                              controller: _pwd,
                              enabled: !_loading,
                              hintText: 'Nuova password',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppTheme.mutedText,
                                ),
                                onPressed: _loading
                                    ? null
                                    : () =>
                                        setState(() => _obscure = !_obscure),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                            _PasswordStrengthBar(
                              value: _passwordStrength,
                              label: _passwordStrengthLabel,
                              color: _passwordStrengthColor,
                            ),
                            const SizedBox(height: 12),
                            _LuxuryInput(
                              controller: _confirmPwd,
                              enabled: !_loading,
                              hintText: 'Conferma password',
                              prefixIcon: Icons.verified_user_outlined,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppTheme.mutedText,
                                ),
                                onPressed: _loading
                                    ? null
                                    : () => setState(
                                          () => _obscureConfirm =
                                              !_obscureConfirm,
                                        ),
                              ),
                              onSubmitted: (_) => _loading ? null : _update(),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            if (_confirmPwd.text.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    passwordsMatch
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline_rounded,
                                    size: 16,
                                    color: passwordsMatch
                                        ? AppTheme.primaryGreen
                                        : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    passwordsMatch
                                        ? 'Le password coincidono'
                                        : 'Le password non coincidono',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: passwordsMatch
                                              ? AppTheme.primaryGreen
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            if (_msg != null) ...[
                              const SizedBox(height: 10),
                              _ErrorBanner(message: _msg!),
                            ],
                            const SizedBox(height: 14),
                            _GradientActionButton(
                              onPressed: _loading ? null : _update,
                              loading: _loading,
                              text: 'Aggiorna password',
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
                          'Password reset • Kash Security',
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

/// Input premium con focus gestito da AppTheme.inputDecorationTheme
class _LuxuryInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const _LuxuryInput({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          color: AppTheme.mutedText.withValues(alpha: 0.9),
          size: 20,
        ),
        suffixIcon: suffixIcon,
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

class _PasswordStrengthBar extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _PasswordStrengthBar({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 8,
            color: Colors.white.withValues(alpha: 0.05),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value == 0 ? 0.04 : value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.85),
                      AppTheme.goldLuxury.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sicurezza password: $label',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: value == 0
                    ? AppTheme.mutedText
                    : color.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSuccess = message.startsWith('✅');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: (isSuccess ? AppTheme.primaryGreen : Colors.redAccent)
            .withValues(alpha: 0.08),
        border: Border.all(
          color: (isSuccess ? AppTheme.primaryGreen : Colors.redAccent)
              .withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_outline
                : Icons.error_outline_rounded,
            size: 16,
            color: (isSuccess ? AppTheme.primaryGreen : Colors.redAccent)
                .withValues(alpha: 0.95),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        (isSuccess ? AppTheme.primaryGreen : Colors.redAccent)
                            .withValues(alpha: 0.95),
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
