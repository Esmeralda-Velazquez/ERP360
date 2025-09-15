import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/CustomerProvider.dart';
import 'package:erpraf/views/UserManagment/CreateCustomerScreen.dart';
import 'package:erpraf/views/UserManagment/EditCustomerScreen.dart';

class ListCustomerScreen extends StatefulWidget {
  const ListCustomerScreen({super.key});

  @override
  State<ListCustomerScreen> createState() => _ListCustomerScreenState();
}

class _ListCustomerScreenState extends State<ListCustomerScreen> {
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CustomerProvider>();

    // Segmentamos en memoria por status (true=activo, false=inactivo)
    final activeItems = prov.items.where((c) => (c.status == true)).toList();
    final inactiveItems = prov.items.where((c) => (c.status == false)).toList();
    final customers = _showInactive ? inactiveItems : activeItems;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Lista de Clientes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CustomerProvider>().fetchAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toggle Activos/Inactivos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Activos'),
                    icon: Icon(Icons.groups_rounded)),
                ButtonSegment(
                    value: true,
                    label: Text('Inactivos'),
                    icon: Icon(Icons.person_off_rounded)),
              ],
              selected: {_showInactive},
              onSelectionChanged: (s) =>
                  setState(() => _showInactive = s.first),
            ),
          ),

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

                if (customers.isEmpty) {
                  return Center(
                    child: Text(_showInactive
                        ? 'No hay clientes inactivos'
                        : 'No hay clientes'),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: ListView.builder(
                    key: ValueKey(_showInactive),
                    padding: const EdgeInsets.all(8),
                    itemCount: customers.length,
                    itemBuilder: (context, i) {
                      final c = customers[i];

                      if (_showInactive) {
                        // INACTIVOS -> swipe para ACTIVAR (ambas direcciones permitido)
                        return Dismissible(
                          key: Key('inactive_${c.id}'),
                          background: _buildSwipeActivateLeft(),
                          secondaryBackground: _buildSwipeActivateRight(),
                          confirmDismiss: (direction) async {
                            final ok =
                                await _confirmActivate(context, c.fullName);
                            if (ok == true) {
                              final done = await context
                                  .read<CustomerProvider>()
                                  .activateById(c.id);
                              if (done && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Cliente activado: ${c.fullName}')),
                                );
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(prov.error ??
                                            'No se pudo activar al cliente')),
                                  );
                                }
                              }
                            }
                            return ok == true;
                          },
                          child: _customerCardRow(c),
                        );
                      } else {
                        // ACTIVOS -> SOLO editar con swipe de derecha a izquierda (endToStart)
                        // ACTIVOS -> SOLO editar con swipe endToStart
                        return Dismissible(
                          key: Key('active_${c.id}'),
                          direction: DismissDirection.endToStart,
                          background: const SizedBox
                              .shrink(), // <-- agrega un fondo "vacío"
                          secondaryBackground:
                              _buildSwipeActionRight(), // tu fondo azul de editar
                          confirmDismiss: (direction) async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCustomerScreen(
                                  customer: {
                                    'id': c.id,
                                    'Nombre': c.fullName,
                                    'Telefono': c.phone ?? '',
                                    'Correo': c.email ?? '',
                                    'status': c.status,
                                  },
                                ),
                              ),
                            );
                            return false;
                          },
                          child: _customerCardRow(c),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCustomerScreen()),
          );
          if (created == true && mounted) {
            context.read<CustomerProvider>().fetchAll();
          }
        },
        label: const Text('CREAR CLIENTE'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ----- UI helpers -----

  Widget _customerCardRow(dynamic c) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            _buildCell(c.id.toString(), flex: 1),
            _buildCell(c.fullName, flex: 2),
            _buildCell(c.phone ?? '', flex: 3),
            _buildCell(c.email ?? '', flex: 3),
          ],
        ),
      ),
    );
  }

  // (Eliminé el fondo rojo de eliminar)
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
          Expanded(
              flex: 1,
              child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Nombre de Cliente',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Teléfono',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Correo',
                  style: TextStyle(fontWeight: FontWeight.bold))),
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

  // Eliminado _confirmDelete() completamente

  Future<bool?> _confirmActivate(BuildContext ctx, String name) async {
    return showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
        title: const Text('Activar cliente'),
        content: Text('¿Deseas activar a $name?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
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
