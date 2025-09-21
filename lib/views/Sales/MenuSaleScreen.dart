import 'package:flutter/material.dart';
import 'package:erpraf/widgets/buttonMenu.dart';
import 'package:erpraf/views/Sales/CreateSaleScreen.dart';
import 'package:erpraf/views/Sales/ListSalesScreen.dart';
import 'package:erpraf/views/Sales/ListCancelledSalesScreen.dart';

class MenuSaleScreen extends StatelessWidget {
  const MenuSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Ventas'),
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
                    'Nueva venta', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/list.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateSaleScreen(),
                    ),
                  );
                }),
                const SizedBox(width: 30),
                buttonMenu(
                    'Ventas actuales', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/movi.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListSalesScreen(),
                    ),
                  );
                }),
                const SizedBox(width: 30),
                buttonMenu(
                    'Ventas canceladas', Icons.people, Colors.blueGrey.shade900,
                    imageAsset: 'assets/list.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListCancelledSalesScreen(),
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
}
