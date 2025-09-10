import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/UsersProvider.dart';
import 'package:erpraf/views/UserManagment/EditUserScreen.dart';

class ListUserScreen extends StatefulWidget {
  const ListUserScreen({super.key});

  @override
  State<ListUserScreen> createState() => _ListUserScreenState();
}

class _ListUserScreenState extends State<ListUserScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UsersProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Lista de usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UsersProvider>().fetchAll(),
          )
        ],
      ),
      body: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: Builder(
              builder: (_) {
                if (prov.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (prov.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        prov.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final users = prov.items;
                if (users.isEmpty) {
                  return const Center(child: Text('No hay usuarios'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return Dismissible(
                      key: Key(u.userId.toString()),
                      background: _buildSwipeActionLeft(),
                      secondaryBackground: _buildSwipeActionRight(),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // Editar
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditUserScreen(
                                usuario: {
                                  'id': u.userId,
                                  // separamos nombre en caso de necesitar first/last en tu edit
                                  'nombre': u.fullName.split(' ').first,
                                  'apellido': u.fullName.split(' ').skip(1).join(' '),
                                  'email': u.email,
                                  'area': u.area ?? '',
                                  'rol': u.role,
                                  'permisos': u.permissions,
                                },
                              ),
                            ),
                          );
                          return false;
                        } else {
                          // Eliminar (cuando tengamos backend)
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => DelateAlert(context),
                          );
                          if (confirm == true) {
                            final ok = await context.read<UsersProvider>().deleteById(u.userId);
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Usuario eliminado: ${u.fullName}')),
                              );
                            }
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
                              _buildCell(u.userId.toString(), flex: 1),
                              _buildCell(u.fullName, flex: 2),
                              _buildCell(u.area ?? '', flex: 2),
                              _buildCell(u.permissions.join(', '), flex: 3),
                              _buildCell(u.role, flex: 2),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
          Expanded(flex: 3, child: Text('Permisos', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
