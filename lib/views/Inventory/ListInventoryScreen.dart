import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/InventoryProvider.dart';
import 'package:erpraf/views/Inventory/EditProductScreen.dart';
import 'package:erpraf/views/Inventory/CreateProductScreen.dart';

class ListInventoryScreen extends StatefulWidget {
  const ListInventoryScreen({super.key});

  @override
  State<ListInventoryScreen> createState() => _ListInventoryScreenState();
}

class _ListInventoryScreenState extends State<ListInventoryScreen> {
  final _searchCtrl = TextEditingController();

  late InventoryProvider inv; // referencia cacheada
  bool _didInit = false; // para asegurar un solo fetch post-frame

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      inv = context.read<InventoryProvider>();
      // ⚠️ Programar el fetch para después del primer frame:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        inv.fetchAll(); // ya no notifica durante build
      });
      _didInit = true;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Listado de Inventario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              inv.fetchAll(q: _searchCtrl.text);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            onSearch: (term) => inv.fetchAll(q: term),
          ),
          // Encabezados
          Container(
            color: const Color.fromARGB(120, 57, 112, 129),
            child: const Row(
              children: [
                _HeaderCell('Código'),
                _HeaderCell('Nombre'),
                _HeaderCell('Categoría'),
                _HeaderCell('Marca'),
                _HeaderCell('Talla'),
                _HeaderCell('Stock mín'),
                _HeaderCell('Existencia'),
                _HeaderCell('Precio'),
                _HeaderCell(''),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: prov.loading
                ? const Center(child: CircularProgressIndicator())
                : (prov.error != null)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(prov.error!,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      )
                    : _InventoryList(
                        items: prov.items,
                        onEdit: (it) async {
                          final edited = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductScreen(
                                product: {
                                  'id': it.id,
                                  'name': it.name,
                                  'category': it.category,
                                  'brand': it.brand,
                                  'size': it.size,
                                  'color': it.color,
                                  'price': it.price,
                                },
                              ),
                            ),
                          );
                          if (!mounted) return;
                          if (edited == true) {
                            inv.fetchAll(q: _searchCtrl.text);
                          }
                        },
                        onDelete: (it) async {
                          final confirm = await _confirmDeleteDialog(context);
                          if (!mounted || confirm != true) return;

                          final ok = await inv.deleteById(it.id);
                          if (!mounted) return;

                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Producto eliminado: ${it.name}')),
                            );
                          } else {
                            final err = inv.error ?? 'No se pudo eliminar';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err)),
                            );
                          }
                        },
                        onDeactivate: (it) async {
                          final confirm = await _confirmDeactivateDialog(context);
                          if (!mounted || confirm != true) return;

                          final ok = await inv.deactivate(it.id);
                          if (!mounted) return;

                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Producto desactivado: ${it.name}')),
                            );
                          } else {
                            final err = inv.error ?? 'No se pudo desactivar';
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(err)));
                          }
                        },
                        onDetails: (it) => _showDetailsDialog(context, it),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey.shade900,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductScreen()),
          );
          if (!mounted) return;
          if (created == true) {
            inv.fetchAll(q: _searchCtrl.text);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Producto creado')),
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/* ===================== Widgets auxiliares ===================== */

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  const _SearchBar({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre / categoría / marca',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: onSearch,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => onSearch(controller.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade900),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}

class _InventoryList extends StatelessWidget {
  final List items;
  final Future<void> Function(dynamic it) onEdit;
  final Future<void> Function(dynamic it) onDelete;
  final Future<void> Function(dynamic it) onDeactivate;
  final void Function(dynamic it) onDetails;

  const _InventoryList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onDeactivate,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay productos en inventario'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final it = items[index];
        return Container(
          color: index.isEven
              ? const Color.fromARGB(120, 135, 180, 194)
              : Colors.white,
          child: Row(
            children: [
              _DataCell(it.id.toString()),
              _DataCell(it.name),
              _DataCell(it.category ?? ''),
              _DataCell(it.brand ?? ''),
              _DataCell(it.size ?? ''),
              _DataCell(it.stockMin.toStringAsFixed(0)),
              _DataCell(it.stock.toStringAsFixed(0)),
              _DataCell(it.price ?? ''),
              _OptionsMenu(
                onSelected: (option) async {
                  switch (option) {
                    case 'editar':
                      await onEdit(it);
                      break;
                    case 'desactivar':
                      await onDeactivate(it);
                      break;
                    case 'detalles':
                      onDetails(it);
                      break;
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String value;
  const _DataCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(value),
      ),
    );
  }
}

class _OptionsMenu extends StatelessWidget {
  final void Function(String) onSelected;
  const _OptionsMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz),
        onSelected: onSelected,
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'editar', child: Text('Editar')),
          PopupMenuItem(
              value: 'desactivar',
              child: Text('Desactivar')), // <— antes decía Eliminar
          PopupMenuItem(value: 'detalles', child: Text('Detalles')),
        ],
      ),
    );
  }
}

/* ===================== Diálogos ===================== */
Future<bool?> _confirmDeactivateDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const Text('Desactivar producto'),
      content: const Text(
          'El producto no se mostrará en el inventario activo. ¿Continuar?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('Cancelar')),
        ElevatedButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('Desactivar')),
      ],
    ),
  );
}

Future<bool?> _confirmDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('¿Eliminar producto?'),
      content:
          const Text('¿Estás seguro de eliminar este producto del inventario?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

void _showDetailsDialog(BuildContext context, dynamic it) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Detalle de #${it.id}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Nombre', it.name),
          _buildDetailRow('Categoría', it.category),
          _buildDetailRow('Marca', it.brand),
          _buildDetailRow('Talla', it.size),
          _buildDetailRow('Precio', it.price),
          _buildDetailRow('Color', it.color),
          _buildDetailRow('Stock mín', it.stockMin.toStringAsFixed(0)),
          _buildDetailRow('Existencia', it.stock.toStringAsFixed(0)),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cerrar'),
          onPressed: () => Navigator.of(dialogCtx).pop(),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value ?? ''),
        ],
      ),
    ),
  );
}
