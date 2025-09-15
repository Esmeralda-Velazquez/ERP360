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

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Lista de Clientes'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<CustomerProvider>().fetchAll())],
      ),
      body: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : prov.error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(prov.error!, style: const TextStyle(color: Colors.red))))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: prov.items.length,
                        itemBuilder: (context, i) {
                          final c = prov.items[i];
                          return Dismissible(
                            key: Key(c.id.toString()),
                            background: _buildSwipeActionLeft(),
                            secondaryBackground: _buildSwipeActionRight(),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditCustomerScreen(customer: {
                                      'id': c.id,
                                      'Nombre': c.fullName,
                                      'Telefono': c.phone ?? '',
                                      'Correo': c.email ?? '',
                                      'status': c.status,
                                    }),
                                  ),
                                );
                                return false;
                              } else {
                                final confirm = await showDialog(context: context, builder: (_) => DelateAlert(context));
                                if (confirm == true) {
                                  final ok = await context.read<CustomerProvider>().deleteById(c.id);
                                  if (ok && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cliente eliminado: ${c.fullName}')));
                                    return true;
                                  } else {
                                    final err = context.read<CustomerProvider>().error ?? 'No se pudo eliminar';
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
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
                                    _buildCell(c.id.toString(), flex: 1),
                                    _buildCell(c.fullName, flex: 2),
                                    _buildCell(c.phone ?? '', flex: 2),
                                    _buildCell(c.email ?? '', flex: 2),
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
        onPressed: () async {
          final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCustomerScreen()));
          if (created == true && mounted) context.read<CustomerProvider>().fetchAll();
        },
        label: const Text('CREAR CLIENTE'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AlertDialog DelateAlert(BuildContext context) => AlertDialog(
    title: const Text('Eliminar cliente'),
    content: const Text('¿Estás seguro de eliminar este cliente?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
    ],
  );

  Widget _buildSwipeActionLeft() => Container(color: Colors.red, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white));
  Widget _buildSwipeActionRight() => Container(color: Colors.blue, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.edit, color: Colors.white));

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 38),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: Colors.blueGrey.shade200, borderRadius: BorderRadius.circular(8)),
      child: const Row(
        children: [
          Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Nombre de Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Correo', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildCell(String text, {required int flex}) =>
      Expanded(flex: flex, child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 2, style: const TextStyle(fontSize: 14)));
}
