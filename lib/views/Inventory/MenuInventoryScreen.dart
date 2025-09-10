import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erpraf/views/LoginScreen.dart';
import 'package:erpraf/widgets/buttonMenu.dart';
import 'package:erpraf/views/Inventory/ListInventoryScreen.dart';

class MenuInventoryScreen extends StatelessWidget {
  const MenuInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('INVENTARIO'),
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
                    'Listado', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/list.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  ListInventoryScreen(),
                    ),
                  );
                }),
                const SizedBox(width: 30),
                buttonMenu(
                    'Movimientos', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/movi.png', () {
                  print('Ir a Movimientos');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
