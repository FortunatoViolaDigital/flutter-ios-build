import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../widget/app_scaffold.dart';
import '../../../router.dart';
import '../../../theme/app_theme.dart';

class OtpRecoveryScreen extends StatefulWidget {
  final String email;

  const OtpRecoveryScreen({super.key, required this.email});

  @override
  State<OtpRecoveryScreen> createState() => _OtpRecoveryScreenState();
}

class _OtpRecoveryScreenState extends State<OtpRecoveryScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();

  bool _loading = false;
  String? _message;

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
    _otpController.dispose();
    super.dispose();
  }

  String _maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts.first;
    final domain = parts.last;

    if (local.length <= 2) return email;
    final visibleStart = local.substring(0, 2);
    return '$visibleStart•••@$domain';
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _message = '❌ Inserisci un codice OTP valido di 6 cifre.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        email: widget.email,
        token: otp,
      );

      if (!mounted) return;

      if (res.user != null) {
        context.goNamed(AppRoutes.newPassword);
      } else {
        setState(() {
          _message = '❌ Codice OTP non valido o scaduto.';
        });
      }
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
    final otpLen = _otpController.text.trim().length;

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
                        'Verifica codice OTP',
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
                        'Inserisci il codice a 6 cifre inviato alla tua email.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                      ),

                      const SizedBox(height: 14),

                      // email chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 16,
                              color: AppTheme.goldSoft.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _maskedEmail(widget.email),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
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
                                  icon: Icons.password_rounded,
                                  gold: true,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Codice OTP',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            _LuxuryInput(
                              controller: _otpController,
                              enabled: !_loading,
                              hintText: 'Inserisci 6 cifre',
                              prefixIcon: Icons.dialpad_rounded,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  _loading ? null : _verifyOtp(),
                              onChanged: (_) => setState(() {}),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              maxLength: 6,
                            ),

                            const SizedBox(height: 8),

                            // Progress / helper
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: otpLen / 6,
                                      minHeight: 6,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.06),
                                      color: otpLen == 6
                                          ? AppTheme.primaryGreen
                                          : AppTheme.goldLuxury,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$otpLen/6',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppTheme.mutedText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
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
                                    'Il codice può scadere. Se non funziona, richiedi un nuovo reset password.',
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
                              onPressed: _loading ? null : _verifyOtp,
                              loading: _loading,
                              text: 'Verifica codice',
                            ),

                            const SizedBox(height: 10),

                            Center(
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context
                                        .goNamed(AppRoutes.resetPassword),
                                child: const Text('Richiedi un nuovo codice'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      Center(
                        child: Text(
                          'OTP verification • Kash Security',
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

/// Input premium con focus gestito dal tema globale
class _LuxuryInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const _LuxuryInput({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2, // look OTP
      ),
      decoration: InputDecoration(
        hintText: hintText,
        counterText: '',
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
