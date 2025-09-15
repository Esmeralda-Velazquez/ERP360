import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,

    // ✅ Encender/apagar validación
    this.enforcePolicy = true,

    // ✅ Mostrar checklist en vivo debajo del campo
    this.showPolicyHelper = true,

    // ✅ Parámetros de política
    this.minLength = 12,
    this.requireUpper = true,
    this.requireLower = true,
    this.requireDigit = true,
    this.requireSpecial = true,

    // UI
    this.labelText = 'Ingresa tu contraseña',
    this.hintText = '********',
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final TextEditingController controller;

  /// Si `true`, aplica validación del `validator`.
  final bool enforcePolicy;

  /// Si `true`, muestra el checklist dinámico con ticks.
  final bool showPolicyHelper;

  /// Política configurable
  final int minLength;
  final bool requireUpper;
  final bool requireLower;
  final bool requireDigit;
  final bool requireSpecial;

  /// UI
  final String labelText;
  final String hintText;
  final AutovalidateMode autovalidateMode;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  void _toggle() => setState(() => _obscure = !_obscure);

  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(widget.controller.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(widget.controller.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(widget.controller.text);
  bool get _hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(widget.controller.text);
  bool get _hasMinLen => widget.controller.text.length >= widget.minLength;

  String? _policyValidator(String? value) {
    if (!widget.enforcePolicy) return null; // 🔕 sin validación
    final v = value ?? '';

    final missing = <String>[];
    if (v.length < widget.minLength) missing.add('mín. ${widget.minLength} caracteres');
    if (widget.requireUpper && !RegExp(r'[A-Z]').hasMatch(v)) missing.add('una mayúscula');
    if (widget.requireLower && !RegExp(r'[a-z]').hasMatch(v)) missing.add('una minúscula');
    if (widget.requireDigit && !RegExp(r'\d').hasMatch(v)) missing.add('un número');
    if (widget.requireSpecial && !RegExp(r'[^A-Za-z0-9]').hasMatch(v)) missing.add('un símbolo');

    if (missing.isEmpty) return null;
    return 'La contraseña debe incluir: ${missing.join(', ')}.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Forzar rebuild del checklist al escribir
    widget.controller.removeListener(_onTextChange);
    widget.controller.addListener(_onTextChange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          autovalidateMode: widget.autovalidateMode,
          validator: _policyValidator,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
            ),
            suffixIcon: IconButton(
              onPressed: _toggle,
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              tooltip: _obscure ? 'Mostrar' : 'Ocultar',
            ),
          ),
        ),

        if (widget.showPolicyHelper) ...[
          const SizedBox(height: 8),
          _RuleTile(
            ok: _hasMinLen,
            text: 'Mínimo ${widget.minLength} caracteres',
          ),
          if (widget.requireUpper)
            _RuleTile(ok: _hasUpper, text: 'Al menos 1 mayúscula (A-Z)'),
          if (widget.requireLower)
            _RuleTile(ok: _hasLower, text: 'Al menos 1 minúscula (a-z)'),
          if (widget.requireDigit)
            _RuleTile(ok: _hasDigit, text: 'Al menos 1 número (0-9)'),
          if (widget.requireSpecial)
            _RuleTile(ok: _hasSpecial, text: 'Al menos 1 símbolo (p. ej. !@#\$%&)'),
        ],
      ],
    );
  }

  void _onTextChange() {
    if (widget.showPolicyHelper) setState(() {});
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    this.ok,
    this.text, this.okTextWhenFalse,
  });

  final bool? ok;
  final String? text;
  final String? okTextWhenFalse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passed = ok ?? false;
    final label = text ?? (passed ? 'OK' : (okTextWhenFalse ?? 'Requisito'));

    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: passed ? Colors.green.shade700 : theme.disabledColor,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: passed ? Colors.green.shade800 : theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
            ),
          ),
        ),
      ],
    );
  }
}
