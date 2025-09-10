import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/RolesProvider.dart';
import 'package:erpraf/views/UserManagment/EditRolesScreen.dart';
import 'package:erpraf/views/UserManagment/CreateRolesScreen.dart';

class ListRolScreen extends StatefulWidget {
  const ListRolScreen({super.key});

  @override
  State<ListRolScreen> createState() => _ListRolScreenState();
}

class _ListRolScreenState extends State<ListRolScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RolesProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RolesProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Lista de Roles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RolesProvider>().fetchAll(q: _searchCtrl.text),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(
            controller: _searchCtrl,
            onSearch: (term) => context.read<RolesProvider>().fetchAll(q: term),
            onClear: () { _searchCtrl.clear(); context.read<RolesProvider>().fetchAll(); },
          ),
          _buildTableHeader(),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.error != null
                    ? Center(child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(prov.error!, style: const TextStyle(color: Colors.red)),
                    ))
                    : RefreshIndicator(
                        onRefresh: () => context.read<RolesProvider>().fetchAll(q: _searchCtrl.text),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: prov.items.length,
                          itemBuilder: (context, index) {
                            final r = prov.items[index];
                            return Dismissible(
                              key: Key(r.id.toString()),
                              background: _buildSwipeActionLeft(),
                              secondaryBackground: _buildSwipeActionRight(),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  // Editar
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditRolesScreen(
                                        roles: {
                                          'id': r.id,
                                          'nombreRol': r.name,
                                          'status': r.status,
                                          'permisos': r.permissions,
                                        },
                                      ),
                                    ),
                                  );
                                  return false;
                                } else {
                                  // Eliminar
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (_) => DelateAlert(context),
                                  );
                                  if (confirm == true) {
                                    final ok = await context.read<RolesProvider>().deleteById(r.id);
                                    if (ok && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Rol eliminado: ${r.name}')),
                                      );
                                      return true;
                                    }
                                  }
                                  return false;
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  child: Row(
                                    children: [
                                      _buildCell(r.id.toString(), flex: 1),
                                      _buildCell(r.name, flex: 2),
                                      _buildCell(r.permissions.join(', '), flex: 3),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Chip(
                                            label: Text(
                                              r.status ? 'Activo' : 'Inactivo',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            backgroundColor: r.status ? Colors.green : Colors.red,
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) =>  CreateRolesScreen()),
          );
          if (created == true && mounted) {
            context.read<RolesProvider>().fetchAll(q: _searchCtrl.text);
          }
        },
        label: const Text('+ CREAR ROL'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ====== UI helpers ======

  Widget _buildSearchBar({
    required TextEditingController controller,
    required ValueChanged<String> onSearch,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 6),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSearch,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o permiso…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
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
          Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Nombre de Rol', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Permisos', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Estatus', style: TextStyle(fontWeight: FontWeight.bold))),
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
