import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/InventoryProvider.dart';
import 'package:erpraf/views/Inventory/EditProductScreen.dart';
import 'package:erpraf/views/Inventory/CreateProductScreen.dart';
import 'package:erpraf/widgets/nice_dialogs.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

class ListInventoryScreen extends StatefulWidget {
  const ListInventoryScreen({super.key});

  @override
  State<ListInventoryScreen> createState() => _ListInventoryScreenState();
}

class _ListInventoryScreenState extends State<ListInventoryScreen> {
  final _searchCtrl = TextEditingController();

  late InventoryProvider inv;
  bool _didInit = false;

  Timer? _debounce;
  static const _debounceMs = 350;

  final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
  final _intFmt = NumberFormat.decimalPattern('es_MX');

  String fmtMoneyDyn(dynamic v) {
    if (v == null) return _mxn.format(0);
    final d = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    return _mxn.format(d);
  }

  String fmtQtyDyn(dynamic v) {
    if (v == null) return _intFmt.format(0);
    final n = (v is num) ? v : (double.tryParse(v.toString()) ?? 0.0);
    return _intFmt.format(n.round());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      inv = context.read<InventoryProvider>();

      _searchCtrl.addListener(() => setState(() {}));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Trae activos + inactivos para tabear sin doble fetch
        inv.fetchAll(includeInactive: true);
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

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      inv.fetchAll(q: q, includeInactive: true);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchCtrl.clear();
    inv.fetchAll(q: '', includeInactive: true);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InventoryProvider>();
    final primary = Colors.blueGrey.shade900;

    final suffix = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: prov.loading
          ? const SizedBox(
              key: ValueKey('spin'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : (_searchCtrl.text.isNotEmpty
              ? IconButton(
                  key: const ValueKey('clear'),
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.clear),
                  onPressed: _clearQuery,
                )
              : const SizedBox.shrink()),
    );

    // Filtrado por status en UI
    final activeItems = prov.items.where((e) => e.status).toList();
    final inactiveItems = prov.items.where((e) => !e.status).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primary,
          title: const Text('Listado de Inventario'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  inv.fetchAll(q: _searchCtrl.text, includeInactive: true),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activos'),
              Tab(text: 'Inactivos'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Buscador en vivo (sin botón)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: (v) =>
                          inv.fetchAll(q: v, includeInactive: true),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre / categoría / marca',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: suffix,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Encabezados fijos
            Container(
              color: const Color.fromARGB(120, 57, 112, 129),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: const Row(
                children: [
                  _HeaderCell('Código', flex: 2, right: true),
                  _HeaderCell('Nombre', flex: 3),
                  _HeaderCell('Categoría', flex: 2),
                  _HeaderCell('Marca', flex: 2),
                  _HeaderCell('Talla', flex: 1),
                  _HeaderCell('Stock mín', flex: 1, right: true),
                  _HeaderCell('Existencia', flex: 1, right: true),
                  _HeaderCell('Precio', flex: 2, right: true),
                  SizedBox(width: 112), // acciones
                ],
              ),
            ),

            // SOLO el cuerpo scroll
            Expanded(
              child: prov.loading
                  ? const Center(child: CircularProgressIndicator())
                  : (prov.error != null)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              prov.error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : TabBarView(
                          children: [
                            // === Activos ===
                            _InventoryList(
                              items: activeItems,
                              fmtMoney: fmtMoneyDyn,
                              fmtQty: fmtQtyDyn,
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
                                        'stockMin': it.stockMin,
                                        'stock': it.stock,
                                      },
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                if (edited == true) {
                                  inv.fetchAll(
                                      q: _searchCtrl.text,
                                      includeInactive: true);
                                }
                              },
                              onDelete: (it) async {
                                final confirm =
                                    await _confirmDeleteDialog(context);
                                if (!mounted || confirm != true) return;

                                final ok = await inv.deleteById(it.id);
                                if (!mounted) return;

                                var message = ok
                                    ? 'Producto eliminado: ${it.name}'
                                    : (inv.error ?? 'No se pudo eliminar');
                                if (!ok) {
                                  AppSnackBar.show(
                                    context,
                                    type: SnackType.error,
                                    message: message,
                                  );
                                }else {
                                AppSnackBar.show(
                                  context,
                                  type: SnackType.success,
                                  message: message,
                                );
                                }
                              },
                              onDeactivate: (it) async {
                                final confirm =
                                    await _confirmDeactivateDialog(context);
                                if (!mounted || confirm != true) return;

                                final ok = await inv.deactivate(it.id);
                                if (!mounted) return;
                                var message = ok
                                    ? 'Producto desactivado: ${it.name}'
                                    : (inv.error ?? 'No se pudo desactivar');
                                if (!ok) {
                                  AppSnackBar.show(
                                    context,
                                    type: SnackType.error,
                                    message: message,
                                  );
                                }else {
                                AppSnackBar.show(
                                  context,
                                  type: SnackType.success,
                                  message: message,
                                );
                                }
                                if (ok)
                                  inv.fetchAll(
                                      q: _searchCtrl.text,
                                      includeInactive: true);
                              },
                              onDetails: (it) => _showDetailsDialog(
                                context,
                                it,
                                fmtMoney: fmtMoneyDyn,
                                fmtQty: fmtQtyDyn,
                              ),
                              inactiveList: false,
                              onActivate: null,
                            ),

                            // === Inactivos ===
                            _InventoryList(
                              items: inactiveItems,
                              fmtMoney: fmtMoneyDyn,
                              fmtQty: fmtQtyDyn,
                              onEdit: (_) async {}, // no editar aquí
                              onDelete: (_) async {}, // no borrar aquí
                              onDeactivate: (_) async {}, // no aplica
                              onDetails: (it) => _showDetailsDialog(
                                context,
                                it,
                                fmtMoney: fmtMoneyDyn,
                                fmtQty: fmtQtyDyn,
                              ),
                              inactiveList: true,
                              onActivate: (it) async {
                                final ok = await inv.activate(it.id);
                                if (!mounted) return;

                                 var message = ok
                                    ? 'Producto activado: ${it.name}'
                                    : (inv.error ?? 'No se pudo activar');
                                if (!ok) {
                                  AppSnackBar.show(
                                    context,
                                    type: SnackType.error,
                                    message: message,
                                  );
                                }else {
                                AppSnackBar.show(
                                  context,
                                  type: SnackType.success,
                                  message: message,
                                );
                                }
                                if (ok)
                                  inv.fetchAll(
                                      q: _searchCtrl.text,
                                      includeInactive: true);
                              },
                            ),
                          ],
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primary,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo producto'),
          onPressed: () async {
            final created = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateProductScreen()),
            );
            if (!mounted) return;
            if (created == true) {
              inv.fetchAll(q: _searchCtrl.text, includeInactive: true);
              AppSnackBar.show(
                context,
                type: SnackType.success,
                message: 'Producto creado',
              );
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

/* ===================== Widgets auxiliares ===================== */

class _InventoryList extends StatefulWidget {
  final List items;
  final String Function(dynamic) fmtMoney;
  final String Function(dynamic) fmtQty;
  final Future<void> Function(dynamic it) onEdit;
  final Future<void> Function(dynamic it) onDelete;
  final Future<void> Function(dynamic it) onDeactivate;
  final void Function(dynamic it) onDetails;

  // Modo inactivos
  final bool inactiveList;
  final Future<void> Function(dynamic it)? onActivate;

  const _InventoryList({
    super.key,
    required this.items,
    required this.fmtMoney,
    required this.fmtQty,
    required this.onEdit,
    required this.onDelete,
    required this.onDeactivate,
    required this.onDetails,
    required this.inactiveList,
    required this.onActivate,
  });

  @override
  State<_InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends State<_InventoryList> {
  late final ScrollController _sc;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // padding inferior para que el FAB no tape el último ítem
    final bottomPad = MediaQuery.of(context).padding.bottom + 88.0;

    if (widget.items.isEmpty) {
      return Scrollbar(
        controller: _sc,
        thumbVisibility: true,
        child: ListView(
          controller: _sc,
          primary: false,
          padding: EdgeInsets.only(bottom: bottomPad),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: const [
            SizedBox(height: 24),
            Center(child: Text('Sin resultados')),
          ],
        ),
      );
    }

    return Scrollbar(
      controller: _sc,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _sc,
        primary: false,
        padding: EdgeInsets.only(bottom: bottomPad),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final it = widget.items[index];
          final bg = index.isEven
              ? const Color.fromARGB(120, 135, 180, 194)
              : Colors.white;

          return Container(
            color: bg,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: [
                _DataCell('#${it.id}', flex: 2, right: true),
                _DataCell(it.name, flex: 3),
                _DataCell(it.category ?? '', flex: 2),
                _DataCell(it.brand ?? '', flex: 2),
                _DataCell(it.size ?? '', flex: 1),
                _DataCell(widget.fmtQty(it.stockMin), flex: 1, right: true),
                _DataCell(widget.fmtQty(it.stock), flex: 1, right: true),
                _DataCell(widget.fmtMoney(it.price), flex: 2, right: true),

                // Acciones
                SizedBox(
                  width: 112,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: widget.inactiveList
                        ? [
                            IconButton(
                              tooltip: 'Activar',
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              onPressed: widget.onActivate == null
                                  ? null
                                  : () => widget.onActivate!(it),
                            ),
                            IconButton(
                              tooltip: 'Detalles',
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => widget.onDetails(it),
                            ),
                          ]
                        : [
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (option) async {
                                switch (option) {
                                  case 'editar':
                                    await widget.onEdit(it);
                                    break;
                                  case 'desactivar':
                                    await widget.onDeactivate(it);
                                    break;
                                  case 'detalles':
                                    widget.onDetails(it);
                                    break;
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                    value: 'editar', child: Text('Editar')),
                                PopupMenuItem(
                                    value: 'desactivar',
                                    child: Text('Desactivar')),
                                PopupMenuItem(
                                    value: 'detalles', child: Text('Detalles')),
                              ],
                            ),
                          ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool right;
  const _HeaderCell(this.label, {this.flex = 1, this.right = false, super.key});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            textAlign: right ? TextAlign.right : TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
}

class _DataCell extends StatelessWidget {
  final String value;
  final int flex;
  final bool right;
  const _DataCell(this.value, {this.flex = 1, this.right = false, super.key});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            textAlign: right ? TextAlign.right : TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
}

Future<bool?> _confirmDeactivateDialog(BuildContext context) {
  return NiceDialogs.showConfirm(
    context,
    title: 'Desactivar producto',
    message: 'El producto no se mostrará en el inventario activo. ¿Continuar?',
    confirmText: 'Desactivar',
    cancelText: 'Cancelar',
    icon: Icons.block,
    accentColor: Colors.amber.shade800, // sensación de advertencia
    barrierDismissible: false,
  );
}

Future<bool?> _confirmDeleteDialog(BuildContext context) {
  return NiceDialogs.showConfirm(
    context,
    title: '¿Eliminar producto?',
    message:
        'Esta acción eliminará el producto del inventario. ¿Seguro que deseas continuar?',
    confirmText: 'Eliminar',
    cancelText: 'Cancelar',
    icon: Icons.delete_forever_rounded,
    accentColor: Colors.red, // sensación de peligro
    barrierDismissible: false,
  );
}

void _showDetailsDialog(
  BuildContext context,
  dynamic it, {
  required String Function(dynamic) fmtMoney,
  required String Function(dynamic) fmtQty,
}) {
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
          _buildDetailRow('Precio', fmtMoney(it.price)),
          _buildDetailRow('Color', it.color),
          _buildDetailRow('Stock mín', fmtQty(it.stockMin)),
          _buildDetailRow('Existencia', fmtQty(it.stock)),
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
