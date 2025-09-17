import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/SupplierProvider.dart';
import 'package:erpraf/views/Proveedores/CreateSupplierScreen.dart';
import 'package:erpraf/views/Proveedores/EditSupplierScreen.dart';
import 'package:erpraf/widgets/app_snackbar.dart';
import 'package:erpraf/widgets/nice_dialogs.dart';

class ListSupplierScreen extends StatefulWidget {
  const ListSupplierScreen({super.key});

  @override
  State<ListSupplierScreen> createState() => _ListSupplierScreenState();
}

class _ListSupplierScreenState extends State<ListSupplierScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SupplierProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Lista de Proveedores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SupplierProvider>().fetchAll(),
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
                final items = prov.items;
                if (items.isEmpty) {
                  return const Center(child: Text('No hay proveedores'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final s = items[index];
                    return Dismissible(
                      key: Key(s.supplierId.toString()),
                      background: _buildSwipeActionLeft(),
                      secondaryBackground: _buildSwipeActionRight(),
                      confirmDismiss: (direction) async {
                        // Editar (swipe derecha -> izquierda)
                        if (direction == DismissDirection.endToStart) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditSupplierScreen(
                                supplier: {
                                  'id': s.supplierId,
                                  'Nombre': s.supplierName,
                                  'Telefono': s.phoneNumber,
                                  'MetodoPago': s.paymentMethod,
                                  'Direccion': s.address,
                                  'Categoria': s.category,
                                },
                              ),
                            ),
                          );
                          return false; // no dismiss
                        }

                        // Eliminar (swipe izquierda -> derecha)
                        final confirmed = await NiceDialogs.showConfirm(
                          context,
                          title: 'Eliminar proveedor',
                          message:
                              '¿Estás seguro de eliminar a "${s.supplierName}"?',
                          confirmText: 'Eliminar',
                          cancelText: 'Cancelar',
                          icon: Icons.delete_forever_rounded,
                          accentColor:
                              Colors.red, // opcional, se ve más “peligro”
                          barrierDismissible:
                              false, // opcional, evita cerrar tocando fuera
                        );

                        if (confirmed != true) return false;

                        final ok = await context
                            .read<SupplierProvider>()
                            .deleteById(s.supplierId);
                        if (ok) {
                          AppSnackBar.show(
                            context,
                            type: SnackType.success,
                            title: 'Proveedor eliminado',
                            message: 'Se eliminó a ${s.supplierName}',
                          );
                          return true; 
                        } else {
                          final error =
                              context.read<SupplierProvider>().error ??
                                  'No se pudo eliminar';
                          AppSnackBar.show(
                            context,
                            type: SnackType.error,
                            title: 'Error',
                            message: error,
                          );
                          return false;
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 30,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              _buildCell(s.supplierId.toString(), flex: 1),
                              _buildCell(s.supplierName, flex: 2),
                              _buildCell(s.phoneNumber ?? '', flex: 2),
                              _buildCell(s.paymentMethod ?? '', flex: 2),
                              _buildCell(s.address ?? '', flex: 2),
                              _buildCell(s.category ?? '', flex: 2),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSupplierScreen()),
          );
        },
        label: const Text('CREAR PROVEEDOR'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              flex: 1,
              child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Nombre de Proveedor',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 3,
              child: Text('Telefono',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Método de Pago',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Dirección',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text('Categoría',
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
}
