import 'dart:async';
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
  Timer? _debounce;

  late RolesProvider _roles;           
  late ScaffoldMessengerState _messenger; 
  late ThemeData _theme;                 
  bool _didInit = false;                

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _roles = context.read<RolesProvider>();

    _messenger = ScaffoldMessenger.maybeOf(context) ?? ScaffoldMessenger.of(context);
    _theme = Theme.of(context);

    if (!_didInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _roles.fetchAll();
      });
      _didInit = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTypeSearch(String term) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _roles.fetchAll(q: term);
      });
    });
  }

  void _showSuccess(String msg, {String? title}) {
    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.green.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title == null ? msg : '$title\n$msg',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    _messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snack);
  }

  void _showError(String msg, {String? title}) {
    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title == null ? msg : '$title\n$msg',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    _messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snack);
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
            onPressed: () => _roles.fetchAll(q: _searchCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(
            controller: _searchCtrl,
            onSearch: (term) => _roles.fetchAll(q: term),
            onClear: () {
              _searchCtrl.clear();
              _onTypeSearch('');
            },
          ),
          _buildTableHeader(),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            prov.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _roles.fetchAll(q: _searchCtrl.text),
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
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditRolesScreen(
                                        roles: {
                                          'id': r.id,
                                          'nombreRol': r.name,
                                          'permisos': r.permissions,
                                        },
                                      ),
                                    ),
                                  );
                                  return false;
                                }

                                // Eliminar (swipe izq→der)
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => DelateAlert(context),
                                );
                                if (confirm != true) return false;

                                final result = await _roles.deleteById(r.id);

                                // Resultado (DeleteResult)
                                if (result.success) {
                                  // Programar snackbar en siguiente frame y usar messenger cacheado
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    _showSuccess('Rol eliminado: ${r.name}', title: 'Éxito');
                                  });
                                  return true; // permite que Dismissible quite el item
                                }

                                if (result.conflict == true) {
                                  final action = await showDialog<_ConflictAction>(
                                    context: context,
                                    builder: (_) => _RoleInUseDialog(
                                      roleName: r.name,
                                      userCount: result.userCount ?? 0,
                                    ),
                                  );

                                  if (action == _ConflictAction.viewUsers) {
                                    // TODO: navegar a pantalla de usuarios por rol
                                  } else if (action == _ConflictAction.reassign) {
                                    final newRoleId = await showDialog<int>(
                                      context: context,
                                      builder: (_) => _ReassignDialog(oldRoleId: r.id),
                                    );
                                    if (newRoleId != null) {
                                      final ok = await _roles.reassignAndDelete(
                                        oldRoleId: r.id,
                                        newRoleId: newRoleId,
                                      );
                                      if (ok && mounted) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (!mounted) return;
                                          _showSuccess(
                                            'Usuarios reasignados y rol eliminado',
                                            title: 'Éxito',
                                          );
                                        });
                                        await _roles.fetchAll(q: _searchCtrl.text);
                                      } else {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (!mounted) return;
                                          _showError(
                                            'No se pudo reasignar/eliminar el rol.',
                                            title: 'Error',
                                          );
                                        });
                                      }
                                    }
                                  }
                                  return false;
                                }

                                // Error genérico
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  _showError(
                                    result.message ?? 'No se pudo eliminar el rol.',
                                    title: 'Error',
                                  );
                                });
                                return false;
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: Row(
                                    children: [
                                      _buildCell(r.id.toString(), flex: 1),
                                      _buildCell(r.name, flex: 2),
                                      _buildCell(r.permissions.join(', '), flex: 3),
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
            MaterialPageRoute(builder: (_) => const CreateRolesScreen()),
          );
          if (!mounted) return;
          if (created == true) {
            _roles.fetchAll(q: _searchCtrl.text);
          }
        },
        label: const Text('CREAR ROL'),
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
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSearch,
            onChanged: _onTypeSearch,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              filled: true,
              fillColor: Colors.white,
            ),
          );
        },
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

// ===== Diálogos auxiliares =====

enum _ConflictAction { viewUsers, reassign, cancel }

class _RoleInUseDialog extends StatelessWidget {
  final String roleName;
  final int userCount;
  const _RoleInUseDialog({required this.roleName, required this.userCount});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rol en uso'),
      content: Text('“$roleName” está asignado a $userCount usuario(s). ¿Qué deseas hacer?'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, _ConflictAction.reassign),
          child: const Text('Reasignar y eliminar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ConflictAction.cancel),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _ReassignDialog extends StatefulWidget {
  final int oldRoleId;
  const _ReassignDialog({required this.oldRoleId});

  @override
  State<_ReassignDialog> createState() => _ReassignDialogState();
}

class _ReassignDialogState extends State<_ReassignDialog> {
  int? _selectedId;
  bool _loading = true;
  List<RoleOption> _roles = [];

  @override
  void initState() {
    super.initState();
    // Cargar opciones cuando el diálogo ya está montado
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<RolesProvider>();
      final roles = await provider.fetchAlternatives(widget.oldRoleId);
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reasignar usuarios'),
      content: _loading
          ? const SizedBox(height: 64, child: Center(child: CircularProgressIndicator()))
          : DropdownButtonFormField<int>(
              value: _selectedId,
              decoration: const InputDecoration(labelText: 'Nuevo rol'),
              items: _roles
                  .map((r) => DropdownMenuItem<int>(value: r.id, child: Text(r.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedId = v),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _selectedId == null || _loading ? null : () => Navigator.pop<int>(context, _selectedId),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
