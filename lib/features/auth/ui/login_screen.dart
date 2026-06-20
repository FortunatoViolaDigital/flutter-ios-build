import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../widget/app_scaffold.dart';
import '../../../router.dart';
import '../../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Inserisci email e password.';
        _loading = false;
      });
      return;
    }

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await Supabase.instance.client.rpc('ensure_user_initialized');

      if (!mounted) return;
      context.goNamed(AppRoutes.dashboard);
    } on AuthException catch (e) {
      if (!mounted) return;

      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        setState(() {
          _error = 'Devi confermare la tua email prima di accedere.';
        });
      } else {
        setState(() {
          _error = e.message;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Credenziali non valide';
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _onGoogleLogin() async {
    // TODO: collega Supabase OAuth Google
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google login in arrivo')),
    );
  }

  Future<void> _onAppleLogin() async {
    // TODO: collega Supabase OAuth Apple
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple login in arrivo')),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // Glows
          /*Positioned(
            top: -50,
            left: -30,
            child: _GlowOrb(
              size: 160,
              color: AppTheme.goldLuxury.withValues(alpha: 0.12),
            ),
          ),*/
          Positioned(
            bottom: 70,
            right: -50,
            child: _GlowOrb(
              size: 200,
              color: AppTheme.primaryGreen.withValues(alpha: 0.10),
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

                      // Logo brand (asset + fallback)
                      //const _LoginHeaderPremium(),

                      //const SizedBox(height: 26),

                      Text(
                        'Bentornato su Kash',
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
                        'Accedi al tuo account per wallet, XP e lotterie.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                      ),

                      const SizedBox(height: 18),

                      // Login Card Premium
                      _LuxuryPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _TinyBadgeIcon(
                                  icon: Icons.lock_open_rounded,
                                  gold: true,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Login',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            _LuxuryInput(
                              controller: _email,
                              enabled: !_loading,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'Email',
                              prefixIcon: Icons.mail_outline_rounded,
                              onSubmitted: (_) => _doLogin(),
                            ),
                            const SizedBox(height: 12),

                            _LuxuryInput(
                              controller: _password,
                              enabled: !_loading,
                              obscureText: _obscurePassword,
                              hintText: 'Password',
                              prefixIcon: Icons.lock_outline_rounded,
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
                              onSubmitted: (_) => _doLogin(),
                            ),

                            const SizedBox(height: 10),

                            // Remember me + forgot
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 0.95,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: _loading
                                        ? null
                                        : (v) => setState(
                                              () => _rememberMe = v ?? false,
                                            ),
                                    activeColor: AppTheme.primaryGreen,
                                    side: BorderSide(
                                      color: AppTheme.goldSoft
                                          .withValues(alpha: 0.35),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _loading
                                      ? null
                                      : () => setState(
                                            () => _rememberMe = !_rememberMe,
                                          ),
                                  child: Text(
                                    'Ricordami',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.mutedText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => context
                                          .pushNamed(AppRoutes.resetPassword),
                                  child: const Text('Password dimenticata?'),
                                ),
                              ],
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              _ErrorBanner(message: _error!),
                            ],

                            const SizedBox(height: 14),

                            // CTA gradient wow
                            _GradientLoginButton(
                              onPressed: _loading ? null : _doLogin,
                              loading: _loading,
                              text: 'Accedi',
                            ),

                            const SizedBox(height: 14),

                            // Divider "oppure"
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'oppure',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppTheme.mutedText,
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Center(
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context.pushNamed(AppRoutes.signup),
                                child: const Text('Crea un account'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: Text(
                          'Secure login • Powered by Kash',
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

/*class _LoginHeaderPremium extends StatelessWidget {
  const _LoginHeaderPremium();

  /*@override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ✅ Metti qui il tuo logo reale
        // Assicurati di averlo in pubspec.yaml es: assets/logo/kash_logo.png
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldLuxury.withValues(alpha: 0.10),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Image.asset(
              'assets/image/kash_logo-app.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.goldLuxury, AppTheme.primaryGreen],
                  ),
                ),
                child: const Icon(
                  Icons.diamond_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Kash',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
        ),
      ],
    );
  }*/
}*/

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
          /*Positioned(
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
          ),*/
          child,
        ],
      ),
    );
  }
}

class _LuxuryInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _LuxuryInput({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF14151A),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.mutedText.withValues(alpha: 0.8),
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: AppTheme.mutedText.withValues(alpha: 0.9),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _GradientLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String text;

  const _GradientLoginButton({
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
              color: AppTheme.primaryGreen.withValues(alpha: 0.18),
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
