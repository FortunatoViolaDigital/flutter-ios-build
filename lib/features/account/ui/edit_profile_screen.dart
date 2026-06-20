import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/profile.dart';
import '../../../data/services/profile_service.dart';
import '../../../widget/app_scaffold.dart';

// ✅ provider centralizzati
import '../../../providers/app_providers.dart';

// (opzionale) se il profilo impatta wallet/credito
import '../../wallet/controller/wallet_controller.dart';
import '../../../theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();

  bool _saving = false;
  String? _error;

  String? _avatarUrl;
  File? _newAvatarFile;

  bool _initializedFromProvider = false;

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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _newAvatarFile = File(picked.path));
    }
  }

  Future<void> _save(Profile profile) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      String? avatarUrl = _avatarUrl;

      if (_newAvatarFile != null) {
        avatarUrl = await ProfileService().uploadAvatar(_newAvatarFile!);
      }

      final updated = Profile(
        id: profile.id,
        email: profile.email,
        fullName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        avatarUrl: avatarUrl,
        // Se il model include altri campi obbligatori (xp, level, ecc.)
        // assicurati che il service update faccia merge o li gestisca.
      );

      await ProfileService().update(updated);

      // ✅ aggiorna cache globale
      ref.invalidate(profileProvider);

      // ✅ se il profilo influenza altre schermate
      ref.invalidate(todayWinnersProvider);

      // opzionale
      ref.invalidate(walletProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profilo aggiornato con successo'),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Errore nel salvataggio: $e';
        _saving = false;
      });
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => AppScaffold(
        title: '',
        body: Stack(
          children: [
            _background(),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (e, _) => AppScaffold(
        title: '',
        body: Stack(
          children: [
            _background(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _StatusBanner(
                  message: '❌ Errore nel caricamento del profilo: $e',
                ),
              ),
            ),
          ],
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return AppScaffold(
            title: '',
            body: Stack(
              children: [
                _background(),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Profilo non trovato.'),
                  ),
                ),
              ],
            ),
          );
        }

        // ✅ inizializza i campi una sola volta quando arriva il profilo
        if (!_initializedFromProvider) {
          _initializedFromProvider = true;
          _nameController.text = profile.fullName ?? '';
          _avatarUrl = profile.avatarUrl;
        }

        ImageProvider<Object>? avatarImage;
        if (_newAvatarFile != null) {
          avatarImage = FileImage(_newAvatarFile!);
        } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
          avatarImage = NetworkImage(_avatarUrl!);
        }

        return AppScaffold(
          title: '',
          body: Stack(
            children: [
              _background(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ListView(
                        children: [
                          const _Header(),
                          const SizedBox(height: 16),
                          _LuxuryPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(context, 'Profilo'),
                                const SizedBox(height: 14),
                                if (_error != null) ...[
                                  _StatusBanner(message: '❌ $_error'),
                                  const SizedBox(height: 12),
                                ],
                                Center(
                                  child: _AvatarEditor(
                                    image: avatarImage,
                                    onTap: _saving ? null : _pickAvatar,
                                    loading: _saving,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: Text(
                                    'Tocca per cambiare immagine',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppTheme.mutedText),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Nome completo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: AppTheme.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                _LuxuryInput(
                                  controller: _nameController,
                                  enabled: !_saving,
                                  hintText: 'Inserisci il tuo nome',
                                  prefixIcon: Icons.person_outline_rounded,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) =>
                                      _saving ? null : _save(profile),
                                ),
                                const SizedBox(height: 12),
                                _StaticInfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: profile.email ?? 'N/D',
                                ),
                                const SizedBox(height: 8),
                                _StaticInfoRow(
                                  icon: Icons.workspace_premium_outlined,
                                  label: 'Livello',
                                  value: 'LV ${profile.level}',
                                  valueColor: AppTheme.goldSoft,
                                ),
                                const SizedBox(height: 18),
                                _GradientActionButton(
                                  onPressed:
                                      _saving ? null : () => _save(profile),
                                  loading: _saving,
                                  text: 'Salva modifiche',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _LuxuryPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(context, 'Suggerimenti'),
                                const SizedBox(height: 10),
                                _HintRow(
                                  icon: Icons.info_outline_rounded,
                                  text:
                                      'Usa un nome chiaro per essere riconosciuto nelle lotterie e nel profilo.',
                                ),
                                const SizedBox(height: 8),
                                _HintRow(
                                  icon: Icons.image_outlined,
                                  text:
                                      'Un avatar ben visibile rende l’esperienza più premium e personale.',
                                ),
                              ],
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
      },
    );
  }

  Widget _background() {
    return Positioned.fill(
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

class _Header extends StatelessWidget {
  const _Header();

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
            Icons.edit_rounded,
            color: AppTheme.goldSoft,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Modifica Profilo',
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

/// Input premium con focus gestito dal tema globale
class _LuxuryInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final IconData prefixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _LuxuryInput({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
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

class _AvatarEditor extends StatelessWidget {
  final ImageProvider<Object>? image;
  final VoidCallback? onTap;
  final bool loading;

  const _AvatarEditor({
    required this.image,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.goldLuxury.withValues(alpha: 0.30),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldLuxury.withValues(alpha: 0.10),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            backgroundImage: image,
            child: image == null
                ? const Icon(Icons.person, size: 34, color: Colors.white)
                : null,
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.goldLuxury, AppTheme.goldSoft],
                ),
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
            ),
          ),
        ),
      ],
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

class _StaticInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StaticInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
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
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HintRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: AppTheme.mutedText.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
          ),
        ),
      ],
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
