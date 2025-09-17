import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class EmailInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final IconData icon;

  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode autovalidateMode;

  final bool isRequired;

  const EmailInput({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.icon = Icons.email_outlined,
    this.validator,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.isRequired = true,
  });

  String? _builtInValidator(String? value) {
    final v = (value ?? '').trim();
    if (!isRequired && v.isEmpty) return null;  
    if (isRequired && v.isEmpty) return 'El correo es requerido';

    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (v.isNotEmpty && !emailRegex.hasMatch(v)) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      validator: validator ?? _builtInValidator, 
      onChanged: onChanged,
      autovalidateMode: autovalidateMode,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), 
      ],
      decoration: InputDecoration(
        labelText: labelText ?? 'Correo electrónico',
        hintText: hintText ?? 'ejemplo@correo.com',
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
        ),
      ),
    );
  }
}
