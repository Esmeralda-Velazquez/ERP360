import 'package:flutter/material.dart';
import 'package:erpraf/views/Proveedores/CreateSupplierScreen.dart';
import 'package:erpraf/views/Proveedores/EditSupplierScreen.dart';

class ListSupplierScreen extends StatelessWidget {
  const ListSupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supplier = [
      {
        'id': 1,
        'Nombre': 'Esmeralda Velazquez',
        'Telefono': 479535685,
        'MetodoPago': 'esmeralda@gmail.com',
        'Direccion': 'Calle Falsa 123',
        'Categoria': 'Camisas',
      },
      {
        'id': 2,
        'Nombre': 'Guillermo Guerrero',
        'Telefono': 479535686,
        'MetodoPago': 'ventas@gmail.com',
        'Direccion': 'Avenida Siempre Viva 456',
        'Categoria': 'Pantalones',
      },
      {
        'id': 3,
        'Nombre': 'Leonardo Perez',
        'Telefono': 479535687,
        'MetodoPago': 'compras@gmail.com',
        'Direccion': 'Calle Falsa 456',
        'Categoria': 'Camisas',
      },
      {
        'id': 4,
        'Nombre': 'Ulises Hernandez',
        'Telefono': 479535688,
        'MetodoPago': 'usuario@gmail.com',
        'Direccion': 'Calle Falsa 789',
        'Categoria': 'Pantalones',
      },
      {
        'id': 5,
        'Nombre': 'Maria Diaz',
        'Telefono': 479535689,
        'MetodoPago': 'vista@gmail.com',
        'Direccion': 'Calle Falsa 101',
        'Categoria': 'Camisas',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Lista de Proveedores'),
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
              itemCount: supplier.length,
              itemBuilder: (context, index) {
                final supplierItem = supplier[index];
                return Dismissible(
                  key: Key(supplierItem['id'].toString()),
                  background: _buildSwipeActionLeft(),
                  secondaryBackground: _buildSwipeActionRight(),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditSupplierScreen(
                            supplier: supplierItem,
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
                        print('Proveedor eliminado: ${supplierItem['id']}');
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
                          _buildCell(supplierItem['id'].toString(), flex: 1),
                          _buildCell(supplierItem['Nombre'] as String?, flex: 2),
                          _buildCell(
                            supplierItem['Telefono'].toString(),
                            flex: 2,
                          ),
                          _buildCell(
                            supplierItem['MetodoPago'] as String?,
                            flex: 2,
                          ),
                          _buildCell(
                            supplierItem['Direccion'] as String?,
                            flex: 2,
                          ),
                          _buildCell(
                            supplierItem['Categoria'] as String?,
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

          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateSupplierScreen()));
        },
        label: const Text('CREAR PROVEEDOR'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AlertDialog DelateAlert(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar proveedor'),
      content: const Text('¿Estás seguro de eliminar este proveedor?'),
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
              child: Text('Nombre de Proveedor', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Telefono', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Método de Pago', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
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
