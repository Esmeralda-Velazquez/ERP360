import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/UsersProvider.dart';
import 'package:erpraf/views/UserManagment/EditUserScreen.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

class ListUserScreen extends StatefulWidget {
  const ListUserScreen({Key? key}) : super(key: key);

  @override
  State<ListUserScreen> createState() => _ListUserScreenState();
}

class _ListUserScreenState extends State<ListUserScreen> {
  bool _showInactive = false; 

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Activos'), icon: Icon(Icons.people_alt_rounded)),
                ButtonSegment(value: true,  label: Text('Inactivos'), icon: Icon(Icons.person_off_rounded)),
              ],
              selected: {_showInactive},
              onSelectionChanged: (s) => setState(() => _showInactive = s.first),
            ),
          ),

          _buildTableHeader(),

          Expanded(
            child: Builder(
              builder: (_) {
                if (prov.loading) return const Center(child: CircularProgressIndicator());
                if (prov.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(prov.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ),
                  );
                }

                final users = _showInactive ? prov.inactiveItems : prov.activeItems;
                if (users.isEmpty) {
                  return Center(
                    child: Text(_showInactive ? 'No hay usuarios inactivos' : 'No hay usuarios'),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: ListView.builder(
                    key: ValueKey(_showInactive), 
                    padding: const EdgeInsets.all(8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];

                      if (_showInactive) {
                        return Dismissible(
                          key: Key('inactive_${u.userId}'),
                          background: _buildSwipeActivateLeft(),
                          secondaryBackground: _buildSwipeActivateRight(),
                          confirmDismiss: (direction) async {
                            final ok = await _confirmActivate(context, u.fullName);
                            if (ok == true) {
                              final done = await context.read<UsersProvider>().activateById(u.userId);
                              if (done && mounted) {
                                AppSnackBar.show(
                                  context,
                                  type: SnackType.success,
                                  title: '¡Usuario activado!',
                                  message: '${u.fullName} ha sido activado',
                                );
                              } else {
                                AppSnackBar.show(
                                  context,
                                  type: SnackType.error,
                                  title: 'Error',
                                  message: 'No se pudo activar al usuario',
                                );
                              }
                            }
                            return ok == true;
                          },
                          child: _userCardRow(u),
                        );
                      } else {
                        return Dismissible(
                          key: Key('active_${u.userId}'),
                          background: _buildSwipeActionLeft(),
                          secondaryBackground: _buildSwipeActionRight(),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditUserScreen(
                                    usuario: {
                                      'id': u.userId,
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
                              final confirm = await _confirmDelete(context);
                              if (confirm == true) {
                                final ok = await context.read<UsersProvider>().deleteById(u.userId);
                                if (ok && mounted) {
                                  AppSnackBar.show(
                                    context,
                                    type: SnackType.success,
                                    title: '¡Éxito!',
                                    message: 'Usuario eliminado: ${u.fullName}',
                                  );
                                }
                              }
                              return confirm == true;
                            }
                          },
                          child: _userCardRow(u),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _userCardRow(u) {
    return Card(
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

  Widget _buildSwipeActivateLeft() {
    return Container(
      color: Colors.green,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  Widget _buildSwipeActivateRight() {
    return Container(
      color: Colors.green,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.check_circle, color: Colors.white),
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

  Future<bool?> _confirmDelete(BuildContext ctx) async {
    return showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
        title: const Text('Eliminar usuario'),
        content: const Text('¿Estás seguro de eliminar este usuario?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmActivate(BuildContext ctx, String name) async {
    return showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
        title: const Text('Activar usuario'),
        content: Text('¿Deseas activar a $name?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }
}

