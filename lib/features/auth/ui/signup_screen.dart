import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../widget/app_scaffold.dart';
import '../../../router.dart';
import '../../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _referral = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _acceptTerms = true;
  bool _rememberMe = true;
  String? _error;

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
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _doSignup() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    final fullName = _fullName.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final referralCode = _referral.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Inserisci email e password.';
        _loading = false;
      });
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _error = 'Devi accettare i termini per continuare.';
        _loading = false;
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _error = 'La password deve avere almeno 8 caratteri.';
        _loading = false;
      });
      return;
    }

    final emailRedirectTo =
        kIsWeb ? '${Uri.base.origin}/login' : 'kash://auth-callback';

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: emailRedirectTo,
        data: {
          'full_name': fullName.isEmpty ? null : fullName,
          'referral_code': referralCode.isEmpty ? null : referralCode,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registrazione completata. Controlla la tua email per confermare l’account.',
          ),
        ),
      );

      context.goNamed(AppRoutes.login);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Errore registrazione: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  double get _passwordStrength {
    final p = _password.text;
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

          // Glow orbs (se vuoi riattivarli, togli i commenti)
          /*
          Positioned(
            top: -50,
            left: -30,
            child: _GlowOrb(
              size: 160,
              color: AppTheme.goldLuxury.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -50,
            child: _GlowOrb(
              size: 200,
              color: AppTheme.primaryGreen.withValues(alpha: 0.10),
            ),
          ),
          */

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
                        'Crea il tuo account Kash',
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
                        'Inizia con wallet, XP e lotterie in un’esperienza premium.',
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
                                  icon: Icons.person_add_alt_1_rounded,
                                  gold: true,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Registrazione',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _LuxuryInput(
                              controller: _fullName,
                              enabled: !_loading,
                              hintText: 'Nome completo',
                              prefixIcon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            _LuxuryInput(
                              controller: _email,
                              enabled: !_loading,
                              hintText: 'Email',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            _LuxuryInput(
                              controller: _password,
                              enabled: !_loading,
                              hintText: 'Password (min 8 caratteri)',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppTheme.mutedText,
                                ),
                                onPressed: _loading
                                    ? null
                                    : () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
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
                              controller: _referral,
                              enabled: !_loading,
                              hintText: 'Codice referral (opzionale)',
                              prefixIcon: Icons.card_giftcard_rounded,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _loading ? null : _doSignup(),
                            ),
                            const SizedBox(height: 10),
                            _CheckRow(
                              value: _rememberMe,
                              onChanged: _loading
                                  ? null
                                  : (v) => setState(() => _rememberMe = v),
                              label: 'Ricordami su questo dispositivo',
                            ),
                            const SizedBox(height: 2),
                            _CheckRow(
                              value: _acceptTerms,
                              onChanged: _loading
                                  ? null
                                  : (v) => setState(() => _acceptTerms = v),
                              label: 'Accetto termini e condizioni',
                              highlight: true,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              _ErrorBanner(message: _error!),
                            ],
                            const SizedBox(height: 14),
                            _GradientActionButton(
                              onPressed: _loading ? null : _doSignup,
                              loading: _loading,
                              text: 'Crea account',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text(
                                    'oppure',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppTheme.mutedText),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),
                            /*const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Google',
                                    icon: Icons.g_mobiledata_rounded,
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Signup Google in arrivo',
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Apple',
                                    icon: Icons.apple_rounded,
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Signup Apple in arrivo',
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                ),
                              ],
                            ),*/
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context.pushNamed(AppRoutes.login),
                                child: const Text('Hai già un account? Accedi'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Kash Account • Secure signup',
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
      child: Stack(
        children: [
          /*
          Positioned(
            top: 0,
            left: 0,
            right: 40,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldSoft.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          */
          child,
        ],
      ),
    );
  }
}

/// Input premium ma con focus gestito da AppTheme.inputDecorationTheme
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

class _CheckRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final bool highlight;

  const _CheckRow({
    required this.value,
    required this.onChanged,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? AppTheme.goldSoft : AppTheme.primaryGreen;

    return Row(
      children: [
        Transform.scale(
          scale: 0.95,
          child: Checkbox(
            value: value,
            onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
            activeColor: AppTheme.primaryGreen,
            side: BorderSide(
              color: accent.withValues(alpha: 0.35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: highlight ? AppTheme.goldSoft : AppTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: label == 'Google' ? 22 : 18,
                  color: label == 'Google' ? AppTheme.goldSoft : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.redAccent.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Colors.redAccent.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 8),
          Expanded(
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
