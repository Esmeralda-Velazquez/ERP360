import 'package:flutter/material.dart';
import 'package:erpraf/views/UserManagment/EditRolesScreen.dart';
import 'package:erpraf/views/UserManagment/CreateRolesScreen.dart';

class ListRolScreen extends StatelessWidget {
  const ListRolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rol = [
      {
        'id': 1,
        'nombreRol': 'Administrador',
        'status': true,
        'permisos': ['Crear', 'Editar', 'Ver'],
      },
      {
        'id': 2,
        'nombreRol': 'Ventas',
        'status': true,
        'permisos': ['Crear', 'Editar', 'Ver'],
      },
      {
        'id': 3,
        'nombreRol': 'Compras',
        'status': false,
        'permisos': ['Crear', 'Editar', 'Ver'],
      },
      {
        'id': 4,
        'nombreRol': 'Usuario General',
        'status': true,
        'permisos': ['Crear', 'Editar', 'Ver'],
      },
      {
        'id': 5,
        'nombreRol': 'Vista',
        'status': false,
        'permisos': ['Crear', 'Editar', 'Ver'],
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
              itemCount: rol.length,
              itemBuilder: (context, index) {
                final rolItem = rol[index];
                return Dismissible(
                  key: Key(rolItem['id'].toString()),
                  background: _buildSwipeActionLeft(),
                  secondaryBackground: _buildSwipeActionRight(),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditRolesScreen(
                            roles: rolItem,
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
                        print('Rol eliminado: ${rolItem['id']}');
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
                          _buildCell(rolItem['id'].toString(), flex: 1),
                          _buildCell(rolItem['nombreRol'] as String?, flex: 2),
                          _buildCell(
                            (rolItem['permisos'] as List<String>).join(', '),
                            flex: 3,
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                label: Text(
                                  rolItem['status'] == true
                                      ? 'Activo'
                                      : 'Inactivo',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: rolItem['status'] == true
                                    ? Colors.green
                                    : Colors.red,
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
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

          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateRoleScreen()));
        },
        label: const Text('+CREAR ROL'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AlertDialog DelateAlert(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar rol'),
      content: const Text('¿Estás seguro de eliminar este rol?'),
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
              child: Text('Nombre de Rol', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Permisos', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Estatus', style: TextStyle(fontWeight: FontWeight.bold))),
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
