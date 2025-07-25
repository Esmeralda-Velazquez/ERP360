import 'package:flutter/material.dart';
import 'package:erpraf/views/UserManagment/CreateCustomerScreen.dart';
import 'package:erpraf/views/UserManagment/EditCustomerScreen.dart';

class ListCustomerScreen extends StatelessWidget {
  const ListCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = [
      {
        'id': 1,
        'Nombre': 'Esmeralda Velazquez',
        'Telefono': 479535685,
        'Correo': 'esmeralda@gmail.com',
      },
      {
        'id': 2,
        'Nombre': 'Guillermo Guerrero',
        'Telefono': 479535686,
        'Correo': 'ventas@gmail.com',
      },
      {
        'id': 3,
        'Nombre': 'Leonardo Perez',
        'Telefono': 479535687,
        'Correo': 'compras@gmail.com',
      },
      {
        'id': 4,
        'Nombre': 'Ulises Hernandez',
        'Telefono': 479535688,
        'Correo': 'usuario@gmail.com',

      },
      {
        'id': 5,
        'Nombre': 'Maria Diaz',
        'Telefono': 479535689,
        'Correo': 'vista@gmail.com',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Lista de Roles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: customer.length,
              itemBuilder: (context, index) {
                final customerItem = customer[index];
                return Dismissible(
                  key: Key(customerItem['id'].toString()),
                  background: _buildSwipeActionLeft(),
                  secondaryBackground: _buildSwipeActionRight(),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditCustomerScreen(
                            customer: customerItem,
                          ),
                        ),
                      );
                      return false;
                    } else {
                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => DelateAlert(context),
                      );
                      if (confirm == true) {
                        print('Rol eliminado: ${customerItem['id']}');
                      }
                      return confirm == true;
                    }
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          _buildCell(customerItem['id'].toString(), flex: 1),
                          _buildCell(customerItem['Nombre'] as String?, flex: 2),
                          _buildCell(
                            customerItem['Telefono'].toString(),
                            flex: 2,
                          ),
                          _buildCell(
                            customerItem['Correo'] as String?,
                            flex: 2,
                          ),

                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {

          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCustomerScreen()));
        },
        label: const Text('+CREAR CLIENTE'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AlertDialog DelateAlert(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar cliente'),
      content: const Text('¿Estás seguro de eliminar este cliente?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildSwipeActionLeft() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildSwipeActionRight() {
    return Container(
      color: Colors.blue,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 38),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Nombre de Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Telefono', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildCell(String? text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text ?? '',
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
