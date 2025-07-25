import 'package:flutter/material.dart';

Widget buttonMenu(
  String texto,
  IconData? icono,
  Color color,
  VoidCallback onPressed, {
  String? imageAsset,
}) {
  return SizedBox(
    width: 250,
    height: 150,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: color, width: 3),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageAsset != null)
            Image.asset(imageAsset, height: 50)
          else if (icono != null)
            Icon(icono, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            texto,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
