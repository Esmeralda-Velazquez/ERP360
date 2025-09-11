import 'package:flutter/material.dart';

enum SnackType { error, warning, info, success }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackType type,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);

    // Configuración por tipo
    final config = _configByType(type, theme);

    final snackBar = SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: config['color'] as Color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config['icon'] as IconData, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static Map<String, dynamic> _configByType(SnackType type, ThemeData theme) {
    switch (type) {
      case SnackType.error:
        return {
          'color': Colors.red.shade700,
          'icon': Icons.error_rounded,
        };
      case SnackType.warning:
        return {
          'color': Colors.orange.shade800,
          'icon': Icons.warning_amber_rounded,
        };
      case SnackType.info:
        return {
          'color': Colors.blue.shade600,
          'icon': Icons.info_rounded,
        };
      case SnackType.success:
        return {
          'color': Colors.green.shade700,
          'icon': Icons.check_circle_rounded,
        };
    }
  }
}

/*
AppSnackBar.show(
  context,
  type: SnackType.error,
  title: "Ups...",
  message: "Algo salió mal al iniciar sesión",
);

AppSnackBar.show(
  context,
  type: SnackType.warning,
  title: "Atención",
  message: "Tu sesión está por expirar",
);

AppSnackBar.show(
  context,
  type: SnackType.info,
  message: "La actualización estará disponible mañana",
);

AppSnackBar.show(
  context,
  type: SnackType.success,
  title: "¡Éxito!",
  message: "Has iniciado sesión correctamente",
);
*/