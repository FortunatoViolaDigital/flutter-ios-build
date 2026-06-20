import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kash/widget/app_scaffold.dart';
import 'package:kash/data/services/paypal_service.dart';
import 'package:kash/features/wallet/controller/wallet_controller.dart';
import 'package:kash/theme/app_theme.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final _controller = TextEditingController(text: '5.00');
  final _paypal = PayPalService();

  bool _paying = false;
  bool _waitingForReturn = false;

  final List<String> _quickAmounts = const ['5', '10', '20', '50'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _parseAmountToCents(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return 0;
    return (value * 100).round();
  }

  String _amountLabel() {
    final normalized = _controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return '€0.00';
    return '€${value.toStringAsFixed(2)}';
  }

  Future<void> _topUpTest() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final cents = _parseAmountToCents(_controller.text);
    if (cents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido')),
      );
      return;
    }

    try {
      setState(() {
        _paying = true;
        _waitingForReturn = false;
      });

      await Supabase.instance.client.from('wallet_transactions').insert({
        'user_id': user.id,
        'amount_cents': cents,
        'provider': 'test',
        'status': 'completed',
      });

      ref.invalidate(walletProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Top-up TEST completato')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Errore TEST: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _paying = false;
          _waitingForReturn = false;
        });
      }
    }
  }

  Future<void> _topUpPayPal() async {
    final cents = _parseAmountToCents(_controller.text);
    if (cents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido')),
      );
      return;
    }

    try {
      setState(() {
        _paying = true;
        _waitingForReturn = false;
      });

      final order = await _paypal.createOrder(
        kind: 'topup',
        amountCents: cents,
        currency: 'EUR',
      );

      final approvalUrl = order['approval_url'] as String;
      await _paypal.openApprovalUrl(approvalUrl);

      if (!mounted) return;
      setState(() {
        _paying = false;
        _waitingForReturn = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Errore PayPal: $e')),
      );
      setState(() {
        _paying = false;
        _waitingForReturn = false;
      });
    }
  }

  Future<void> _refreshWallet() async {
    ref.invalidate(walletProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aggiornato ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountCents = _parseAmountToCents(_controller.text);
    final canSubmit = !_paying && !_waitingForReturn && amountCents > 0;

    return AppScaffold(
      title: '',
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _TopUpHeader(
                    waitingForReturn: _waitingForReturn,
                    amountLabel: _amountLabel(),
                  ),
                  const SizedBox(height: 14),
                  _LuxuryPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(context, 'Importo ricarica'),
                        const SizedBox(height: 12),
                        Text(
                          'Inserisci quanto vuoi aggiungere al wallet e scegli il metodo di pagamento.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.mutedText,
                                    height: 1.35,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        _LuxuryInput(
                          controller: _controller,
                          enabled: !_paying && !_waitingForReturn,
                          hintText: 'Es. 5.00',
                          prefixIcon: Icons.euro_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickAmounts.map((amount) {
                            final selected = _controller.text
                                        .trim()
                                        .replaceAll(',', '.') ==
                                    amount ||
                                _controller.text.trim().replaceAll(',', '.') ==
                                    '$amount.00';
                            return _QuickAmountChip(
                              label: '€$amount',
                              selected: selected,
                              onTap: (_paying || _waitingForReturn)
                                  ? null
                                  : () {
                                      setState(() {
                                        _controller.text = '$amount.00';
                                      });
                                    },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
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
                            children: [
                              _InfoRow(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Importo selezionato',
                                value: _amountLabel(),
                                valueColor: AppTheme.goldSoft,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.payments_outlined,
                                label: 'Valore in centesimi',
                                value: '$amountCents',
                              ),
                            ],
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
                        _sectionTitle(context, 'Metodo di pagamento'),
                        const SizedBox(height: 12),
                        _MethodCard(
                          icon: Icons.paypal_rounded,
                          title: 'PayPal Sandbox',
                          subtitle:
                              'Apri PayPal, approva il pagamento e rientra in app per la conferma.',
                          accent: AppTheme.primaryGreen,
                        ),
                        const SizedBox(height: 10),
                        _MethodCard(
                          icon: Icons.science_outlined,
                          title: 'Top-up test',
                          subtitle:
                              'Modalità finta per sviluppo e collaudo rapido del wallet.',
                          accent: AppTheme.goldSoft,
                        ),
                        if (_paying) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(minHeight: 6),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_waitingForReturn)
                    _LuxuryPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context, 'Pagamento in attesa'),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppTheme.goldSoft.withValues(alpha: 0.08),
                              border: Border.all(
                                color:
                                    AppTheme.goldSoft.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 18,
                                  color: AppTheme.goldSoft,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'In attesa del ritorno da PayPal. Quando hai finito, aggiorna il saldo wallet.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.goldSoft,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _GradientActionButton(
                            onPressed: _refreshWallet,
                            loading: false,
                            text: 'Ho completato: aggiorna saldo',
                          ),
                        ],
                      ),
                    )
                  else
                    _LuxuryPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context, 'Conferma ricarica'),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.08),
                              border: Border.all(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'La conferma finale e l’accredito avvengono al rientro in app.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _GradientActionButton(
                            onPressed: canSubmit ? _topUpPayPal : null,
                            loading: _paying,
                            text: 'Paga con PayPal (Sandbox)',
                          ),
                          const SizedBox(height: 10),
                          _SecondaryActionButton(
                            onPressed: canSubmit ? _topUpTest : null,
                            text: 'Ricarica TEST (finto)',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  const _TopUpInfoCard(),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Wallet Recharge • Kash Payments',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.mutedText.withValues(alpha: 0.85),
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

class _TopUpHeader extends StatelessWidget {
  final bool waitingForReturn;
  final String amountLabel;

  const _TopUpHeader({
    required this.waitingForReturn,
    required this.amountLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                Icons.account_balance_wallet_rounded,
                color: AppTheme.goldSoft,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ricarica Wallet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.25,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          waitingForReturn
              ? 'Pagamento avviato. Rientra in app e aggiorna il saldo.'
              : 'Aggiungi fondi al tuo wallet in modo rapido e premium.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TinyPill(
              icon: Icons.euro_rounded,
              text: amountLabel,
              color: AppTheme.goldSoft,
            ),
            _TinyPill(
              icon: waitingForReturn
                  ? Icons.hourglass_top_rounded
                  : Icons.payments_outlined,
              text: waitingForReturn ? 'In attesa' : 'Pronto al pagamento',
              color:
                  waitingForReturn ? AppTheme.goldSoft : AppTheme.primaryGreen,
            ),
          ],
        ),
      ],
    );
  }
}

class _TopUpInfoCard extends StatelessWidget {
  const _TopUpInfoCard();

  @override
  Widget build(BuildContext context) {
    return _LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Info'),
          const SizedBox(height: 12),
          Text(
            'Con PayPal Sandbox il flusso apre la pagina di approvazione esterna. Una volta completata l’operazione, il saldo viene confermato al rientro in app.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                  height: 1.4,
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

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withValues(alpha: 0.10),
              border: Border.all(
                color: accent.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(icon, size: 18, color: accent),
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
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _QuickAmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppTheme.goldSoft : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? AppTheme.goldSoft.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: selected
                  ? AppTheme.goldSoft.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202127), Color(0xFF15161B)],
        ),
        border: Border.all(
          color: AppTheme.goldLuxury.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldLuxury.withValues(alpha: 0.05),
            blurRadius: 14,
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

class _LuxuryInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _LuxuryInput({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.onChanged,
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
        keyboardType: keyboardType,
        onChanged: onChanged,
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
      opacity: disabled ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldLuxury.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
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
                      textAlign: TextAlign.center,
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

class _SecondaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const _SecondaryActionButton({
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ),
      ),
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
          size: 16,
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
                fontWeight: FontWeight.w800,
                color: valueColor ?? Colors.white,
              ),
        ),
      ],
    );
  }
}

class _TinyPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _TinyPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
