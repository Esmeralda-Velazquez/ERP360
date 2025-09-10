import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erpraf/views/LoginScreen.dart';
import 'package:erpraf/widgets/buttonMenu.dart';
import 'package:erpraf/views/UserManagment/UserManagmentScreen.dart';
import 'package:erpraf/views/Proveedores/ListSupplierScreen.dart';
import 'package:erpraf/views/Inventory/MenuInventoryScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            SizedBox(width: 10),
            Text('Esmeralda Velazquez'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => cerrarSesion(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonMenu('Proveedores', Icons.people_outline, Colors.blue,
                    () {
                                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListSupplierScreen(),
                    ),
                  );
                }),
                const SizedBox(width: 30),
                buttonMenu('Ventas', Icons.sell_outlined, Colors.purple, () {
                  print('Ir a Ventas');
                }),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buttonMenu('Gestion de usuarios',
                    Icons.manage_accounts_outlined, Colors.indigo, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagmentScreen(),
                    ),
                  );
                }),
                const SizedBox(width: 30),
                buttonMenu(
                    'Inventarios', Icons.inventory_2_outlined, Colors.red, () {
                                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  MenuInventoryScreen(),
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
