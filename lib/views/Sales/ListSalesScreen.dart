import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:erpraf/controllers/SalesProvider.dart';
import 'package:erpraf/views/Sales/CreateSaleScreen.dart';
import 'package:erpraf/views/Sales/SaleDetailScreen.dart';
import 'package:erpraf/widgets/nice_dialogs.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

class ListSalesScreen extends StatefulWidget {
  const ListSalesScreen({super.key});

  @override
  State<ListSalesScreen> createState() => _ListSalesScreenState();
}

class _ListSalesScreenState extends State<ListSalesScreen> {
  final _qCtrl = TextEditingController();
  late SalesProvider prov;
  bool _didInit = false;

  Timer? _debounce;
  static const _debounceMs = 350;

  // SCROLL: controller para el cuerpo (lista)
  final ScrollController _bodyScrollCtrl = ScrollController();

  // Formateadores
  final _df = DateFormat('yyyy-MM-dd HH:mm');
  final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

  String fmtMoney(String? raw) {
    final v = double.tryParse((raw ?? '0').trim());
    return _mxn.format(v ?? 0);
  }

  String fmtInt(num? v) => (v ?? 0).toInt().toString();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      prov = context.read<SalesProvider>();
      _qCtrl.addListener(() => setState(() {})); // para refrescar suffix
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        prov.fetchAll();
      });
      _didInit = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    _bodyScrollCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      prov.fetchAll(q: q);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _qCtrl.clear();
    prov.fetchAll(q: '');
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final primary = Colors.blueGrey.shade900;

    // Espacio para que el FAB no tape la última fila
    final bottomInset = MediaQuery.of(context).padding.bottom; // notch / safe area
    const fabHeight = 56.0;
    const fabMargin = 16.0;
    final bottomPadding = bottomInset + fabHeight + fabMargin + 8.0;

    final suffix = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: sales.loading
          ? const SizedBox(
              key: ValueKey('spin'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : (_qCtrl.text.isNotEmpty
              ? IconButton(
                  key: const ValueKey('clear'),
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.clear),
                  onPressed: _clearQuery,
                )
              : const SizedBox.shrink()),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Ventas actuales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.fetchAll(q: _qCtrl.text),
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro en vivo (sin botón)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (v) => prov.fetchAll(q: v),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente / usuario',
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

          // Encabezado fijo
          Container(
            color: const Color.fromARGB(120, 57, 112, 129),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: const Row(
              children: [
                _HeaderCell('Folio',   flex: 1, right: true),
                _HeaderCell('Fecha',   flex: 2),
                _HeaderCell('Cliente', flex: 3),
                _HeaderCell('Usuario', flex: 2),
                _HeaderCell('Total',   flex: 2, right: true),
                SizedBox(width: 120), // acciones
              ],
            ),
          ),

          // Cuerpo con SCROLL independiente + padding por FAB
          Expanded(
            child: sales.loading
                ? const Center(child: CircularProgressIndicator())
                : (sales.error != null)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            sales.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller: _bodyScrollCtrl,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _bodyScrollCtrl,
                          primary: false,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(bottom: bottomPadding),
                          itemCount: sales.items.length,
                          itemBuilder: (_, i) {
                            final s = sales.items[i];
                            final bg = i.isEven
                                ? const Color.fromARGB(120, 135, 180, 194)
                                : Colors.white;

                            final folio = '#${fmtInt(s.saleId)}';
                            final fecha = _df.format(s.date);
                            final cliente = s.customerName ?? '-';
                            final usuario = s.userName ?? '-';
                            final total = fmtMoney(s.totalAmount);

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SaleDetailScreen(saleId: s.saleId),
                                  ),
                                );
                              },
                              child: Container(
                                color: bg,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 6,
                                ),
                                child: Row(
                                  children: [
                                    _DataCell(folio,   flex: 1, right: true),
                                    _DataCell(fecha,   flex: 2),
                                    _DataCell(cliente, flex: 3),
                                    _DataCell(usuario, flex: 2),
                                    _DataCell(total,   flex: 2, right: true),
                                    SizedBox(
                                      width: 120,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            tooltip: 'Cancelar (soft)',
                                            icon: const Icon(Icons.cancel, color: Colors.red),
                                            onPressed: s.status
                                                ? () async {
                                                    final confirm = await NiceDialogs.showConfirm(
                                                      context,
                                                      title: 'Cancelar venta',
                                                      message: 'Se reingresará el stock en el inventario. ¿Continuar?',
                                                      confirmText: 'Sí',
                                                      cancelText: 'No',
                                                      icon: Icons.cancel_rounded,
                                                      accentColor: Colors.red,
                                                      barrierDismissible: false,
                                                    );
                                                    if (confirm == true) {
                                                      final res = await prov.cancel(s.saleId);
                                                      if (!mounted) return;
                                                      final msg = res
                                                          ? 'Venta cancelada'
                                                          : (prov.error ?? 'Error');
                                                      AppSnackBar.show(
                                                        context,
                                                        message: msg,
                                                        type: res ? SnackType.success : SnackType.error,
                                                      );
                                                    }
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva venta'),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
          );
          if (!mounted) return;
          if (created == true) prov.fetchAll(q: _qCtrl.text);
        },
      ),
    );
  }
}

// ======= Helpers visuales con flex y alineación =======

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
