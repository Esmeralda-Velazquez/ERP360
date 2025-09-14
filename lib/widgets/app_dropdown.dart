import 'package:flutter/material.dart';

/// Dropdown genérico y reutilizable para toda la app.
/// - Typed (T) para usarlo con String, enums o tus propios modelos.
/// - Soporta validación (Form), autovalidación, ícono, loading y estado sin datos.
/// - Estilo consistente con bordes redondeados.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.itemLabel,
    this.value,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.enabled = true,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.menuMaxHeight,
    this.isLoading = false,
    this.emptyText = 'Sin opciones',
    this.filled = true,
    this.fillColor,
  });

  /// Lista de opciones
  final List<T> items;

  /// Función para mostrar el texto de cada opción
  final String Function(T item) itemLabel;

  /// Valor seleccionado (puede ser null)
  final T? value;

  /// Callback al cambiar
  final ValueChanged<T?>? onChanged;

  /// Guardado (para Form)
  final FormFieldSetter<T?>? onSaved;

  /// Validador (para Form)
  final FormFieldValidator<T?>? validator;

  /// Texto de etiqueta del campo
  final String? labelText;

  /// Hint dentro del campo cuando no hay valor
  final String? hintText;

  /// Ícono al inicio (opcional)
  final IconData? prefixIcon;

  /// Habilitar/deshabilitar
  final bool enabled;

  /// Autovalidación
  final AutovalidateMode autovalidateMode;

  /// Altura máx del menú
  final double? menuMaxHeight;

  /// Modo cargando (muestra spinner y deshabilita)
  final bool isLoading;

  /// Texto a mostrar cuando no hay items
  final String emptyText;

  /// Estilo de relleno
  final bool filled;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveEnabled = enabled && !isLoading && items.isNotEmpty;

    final decoration = InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: theme.colorScheme.primary)
          : null,
      filled: filled,
      fillColor: (fillColor ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.18)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

    if (isLoading) {
      return _LoadingShell(decoration: decoration);
    }

    if (items.isEmpty) {
      return _EmptyShell(decoration: decoration, text: emptyText);
    }

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      autovalidateMode: autovalidateMode,
      validator: validator,
      onSaved: onSaved,
      onChanged: effectiveEnabled ? onChanged : null,
      menuMaxHeight: menuMaxHeight ?? 320,
      decoration: decoration,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                itemLabel(e),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell({required this.decoration});
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: decoration.copyWith(
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      child: const Text('Cargando...', style: TextStyle(color: Colors.grey)),
    );
  }
}

class _EmptyShell extends StatelessWidget {
  const _EmptyShell({required this.decoration, required this.text});
  final InputDecoration decoration;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: decoration,
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}
