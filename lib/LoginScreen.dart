import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Columna izquierda
          Expanded(
            flex: 1,
            child: columnLeft(),
          ),

          // Columna derecha
          Expanded(
            flex: 1,
            child: Center(
              child: columnRifth(),
            ),
          ),
        ],
      ),
    );
  }

  Container columnRifth() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(
                'assets/avatar.png'), // Asegúrate de tener esta imagen
          ),
          const SizedBox(height: 30),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Ingresa tu nombre de usuario',
              border: OutlineInputBorder(),
              hintText: 'Admin',
            ),
          ), 
          const SizedBox(height: 20),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Ingresa tu contraseña',
              border: OutlineInputBorder(),
              hintText: '********',
            ),
          ), 
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1E3A5F),
              ),
              child: const Text(
                'Inicia sesión',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {},
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
          const SizedBox(height: 20),
          const Text(
            '©2025 All Rights Reserved.\nERP System by DR',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Container columnLeft() {
    return Container(
      color: const Color(0xFF17496B), // Azul oscuro
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "BIENVENIDO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Gestión empresarial inteligente",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 200,
              child: Image.asset(
                  'assets/illustration.png'), // Asegúrate de tener la imagen
            ),
          ],
        ),
      ),
    );
  }
}
