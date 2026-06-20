import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../router.dart';
import '../../../theme/app_theme.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  double get _passwordStrength {
    final p = _passwordController.text;
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

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (newPassword.length < 8) {
      setState(() => _error = 'La password deve avere almeno 8 caratteri.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _error = 'Le password non coincidono.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Password aggiornata. Effettuo logout...'),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pop();
      context.goNamed(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Errore: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordsMatch = _confirmController.text.isEmpty ||
        _passwordController.text == _confirmController.text;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF202127), Color(0xFF15161B)],
          ),
          border: Border.all(
            color: AppTheme.goldLuxury.withValues(alpha: 0.24),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldLuxury.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldSoft.withValues(alpha: 0.20),
                        AppTheme.goldSoft.withValues(alpha: 0.07),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.goldSoft.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 17,
                    color: AppTheme.goldSoft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cambia Password',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppTheme.mutedText.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Per sicurezza, dopo l’aggiornamento verrai disconnesso.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
            const SizedBox(height: 14),
            _DialogInput(
              controller: _passwordController,
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
                    : () => setState(() => _obscure = !_obscure),
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
            _DialogInput(
              controller: _confirmController,
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
                    : () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              onSubmitted: (_) => _loading ? null : _changePassword(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (_confirmController.text.isNotEmpty)
              Row(
                children: [
                  Icon(
                    passwordsMatch
                        ? Icons.check_circle_outline
                        : Icons.error_outline_rounded,
                    size: 15,
                    color: passwordsMatch
                        ? AppTheme.primaryGreen
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    passwordsMatch
                        ? 'Le password coincidono'
                        : 'Le password non coincidono',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: passwordsMatch
                              ? AppTheme.primaryGreen
                              : Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GradientDialogButton(
                    onPressed: _loading ? null : _changePassword,
                    loading: _loading,
                    text: 'Aggiorna',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const _DialogInput({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
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

class _GradientDialogButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String text;

  const _GradientDialogButton({
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
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldLuxury.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 46,
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
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
            height: 7,
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
