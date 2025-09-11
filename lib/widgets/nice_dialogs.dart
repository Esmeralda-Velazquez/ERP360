import 'dart:ui';
import 'package:flutter/material.dart';

/// - NiceDialogs.showConfirm(...) -> Confirmar/Cancelar
/// - NiceDialogs.showInfo(...)    -> Solo informativo
class NiceDialogs {
  /// Diálogo de Confirmar / Cancelar
  static Future<bool?> showConfirm(
    BuildContext context, {
    String title = '¿Confirmar?',
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    IconData icon = Icons.help_rounded,
    Color? accentColor,
    bool barrierDismissible = false,
  }) {
    return _showBase(
      context,
      barrierDismissible: barrierDismissible,
      child: _NiceDialogBody(
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
        primaryAction: _NiceAction(
          label: confirmText,
          onPressed: () => Navigator.of(context).pop(true),
          isFilled: true,
        ),
        secondaryAction: _NiceAction(
          label: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
          isFilled: false,
        ),
      ),
    );
  }

  /// Diálogo informativo
  static Future<void> showInfo(
    BuildContext context, {
    String title = 'Información',
    required String message,
    String buttonText = 'Entendido',
    IconData icon = Icons.info_rounded,
    Color? accentColor,
    bool barrierDismissible = true,
    VoidCallback? onClose,
  }) {
    return _showBase(
      context,
      barrierDismissible: barrierDismissible,
      child: _NiceDialogBody(
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
        primaryAction: _NiceAction(
          label: buttonText,
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
          isFilled: true,
        ),
      ),
    );
  }

  /// Animación + blur + scale/fade
  static Future<T?> _showBase<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
  }) {
    final theme = Theme.of(context);
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierDismissible: barrierDismissible,
      barrierColor: theme.colorScheme.scrim.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.5 * anim.value, sigmaY: 1.5 * anim.value),
          child: Opacity(
            opacity: anim.value,
            child: Transform.scale(
              scale: 0.96 + 0.04 * curved.value,
              child: Center(
                child: _NiceDialogShell(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Contenedor visual con estilo (card + glass + sombras)
class _NiceDialogShell extends StatelessWidget {
  const _NiceDialogShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: (isDark
                  ? theme.colorScheme.surface.withOpacity(0.85)
                  : theme.colorScheme.surface.withOpacity(0.92))
              .withAlpha(235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              spreadRadius: -6,
              offset: const Offset(0, 12),
              color: Colors.black.withOpacity(isDark ? 0.55 : 0.18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Cuerpo del diálogo: header + message + acciones
class _NiceDialogBody extends StatelessWidget {
  const _NiceDialogBody({
    required this.title,
    required this.message,
    required this.icon,
    required this.primaryAction,
    this.secondaryAction,
    this.accentColor,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color? accentColor;
  final _NiceAction primaryAction;
  final _NiceAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(icon: icon, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (secondaryAction != null) ...[
                  Expanded(child: _NiceButton(action: secondaryAction!, color: color, filled: false)),
                  const SizedBox(width: 10),
                ],
                Expanded(child: _NiceButton(action: primaryAction, color: color, filled: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = color.withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _NiceAction {
  _NiceAction({required this.label, required this.onPressed, required this.isFilled});
  final String label;
  final VoidCallback onPressed;
  final bool isFilled;
}

class _NiceButton extends StatelessWidget {
  const _NiceButton({required this.action, required this.color, required this.filled});
  final _NiceAction action;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = filled ? color : theme.colorScheme.surface;
    final fg = filled ? theme.colorScheme.onPrimary : theme.colorScheme.primary;
    final borderColor = filled ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.28);

    return SizedBox(
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: filled ? 0 : 0,
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor, width: 1),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        onPressed: action.onPressed,
        child: Text(action.label),
      ),
    );
  }
}
