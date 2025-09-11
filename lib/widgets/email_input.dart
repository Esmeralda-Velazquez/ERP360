// lib/ui/widgets/email_input.dart
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

  const EmailInput({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.icon = Icons.email_outlined,
    this.validator,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.disabled, 
  });

  static String? defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
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
      validator: validator ?? defaultValidator,
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
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
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
