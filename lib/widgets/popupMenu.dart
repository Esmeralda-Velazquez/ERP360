
import 'package:flutter/material.dart';

// ignore: unused_element
class _OptionsMenu extends StatelessWidget {
  final void Function(String) onSelected;
  const _OptionsMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(value: 'editar', child: Text('Editar')),
          const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          const PopupMenuItem(value: 'detalles', child: Text('Detalles')),
        ],
      ),
    );
  }
}

