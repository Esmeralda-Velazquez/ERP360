import 'package:flutter/material.dart';
import 'package:erpraf/views/UserManagment/EditUserScreen.dart';

class ListUserScreen extends StatelessWidget {
  const ListUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
final usuarios = [
  {
    'id': 1,
    'nombre': 'Esmeralda',
    'apellido': 'Velazquez',
    'email': 'esme@example.com',
    'area': 'Sistemas',
    'rol': 'Admin',
    'permisos': ['Crear usuarios', 'Editar usuarios', 'Ver reportes'],
  },
  {
    'id': 2,
    'nombre': 'Carlos',
    'apellido': 'Sánchez',
    'email': 'carlos@example.com',
    'area': 'Finanzas',
    'rol': 'Editor',
    'permisos': ['Ver reportes'],
  },
];


    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Lista de usuarios'),
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
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                return Dismissible(
                  key: Key(usuario['id'].toString()),
                  background: _buildSwipeActionLeft(),
                  secondaryBackground: _buildSwipeActionRight(),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditUserScreen(
                            usuario: usuario,
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
                        print('Usuario eliminado: ${usuario['id']}');
                      }
                      return confirm == true;
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          _buildCell(usuario['id'].toString(), flex: 1), // Conversión aquí también
                          _buildCell(usuario['nombre'] as String?, flex: 2),
                          _buildCell(usuario['area'] as String?, flex: 2),
                          _buildCell((usuario['permisos'] as List<String>).join(', '), flex: 3),
                          _buildCell(usuario['rol'] as String?, flex: 2),
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
    );
  }

  AlertDialog DelateAlert(BuildContext context) {
    return AlertDialog(
                        title: const Text('Eliminar usuario'),
                        content: const Text('¿Estás seguro de eliminar este usuario?'),
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
          Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Área', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Módulos', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold))),
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
