import 'package:erpraf/views/UserManagment/ListCustomerScreen.dart';
import 'package:erpraf/views/UserManagment/ListUserScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erpraf/views/LoginScreen.dart';
import 'package:erpraf/widgets/buttonMenu.dart';
import 'package:erpraf/views/UserManagment/CreateUserScreen.dart';
import 'package:erpraf/views/UserManagment/ListRolScreen.dart';
import 'package:erpraf/views/UserManagment/ListCustomerScreen.dart';

class UserManagmentScreen extends StatelessWidget {
  const UserManagmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Gestión de usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonMenu(
                    'Crear usuario', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/userIcon.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateUserScreen(),
                    ),
                  );
                }),
                const SizedBox(width: 30),
                buttonMenu(
                    'Lista de usuario', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/listUser.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListUserScreen(),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonMenu('Clientes', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/cliente.png', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListCustomerScreen(),
                        ),
                      );
                    }),
                const SizedBox(width: 30),
                buttonMenu(
                    'Registrar Rol', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/rol.png', () {
                                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListRolScreen(),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void cerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cerrar sesión"),
        content: Text("¿Estás segura de que deseas cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Sesión cerrada")),
              );
            },
            child: Text("Cerrar sesión"),
          ),
        ],
      ),
    );
  }

  Future<void> limpiarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
