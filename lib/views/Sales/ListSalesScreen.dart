import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:erpraf/controllers/SalesProvider.dart';
import 'package:erpraf/views/Sales/CreateSaleScreen.dart';
import 'package:erpraf/views/Sales/SaleDetailScreen.dart';

class ListSalesScreen extends StatefulWidget {
  const ListSalesScreen({super.key});

  @override
  State<ListSalesScreen> createState() => _ListSalesScreenState();
}

class _ListSalesScreenState extends State<ListSalesScreen> {
  final _qCtrl = TextEditingController();
  late SalesProvider prov;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      prov = context.read<SalesProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        prov.fetchAll();
      });
      _didInit = true;
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.fetchAll(q: _qCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // filtros sencillos
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar cliente/usuario/método',
                      border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => prov.fetchAll(q: _qCtrl.text),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900),
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),

          // encabezado
          Container(
            color: const Color.fromARGB(120, 57, 112, 129),
            child: const Row(
              children: [
                _HeaderCell('Folio'),
                _HeaderCell('Fecha'),
                _HeaderCell('Cliente'),
                _HeaderCell('Usuario'),
                _HeaderCell('Total'),
                _HeaderCell('Estado'),
                _HeaderCell(''),
              ],
            ),
          ),

          Expanded(
            child: sales.loading
                ? const Center(child: CircularProgressIndicator())
                : (sales.error != null)
                    ? Center(child: Text(sales.error!, style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        itemCount: sales.items.length,
                        itemBuilder: (_, i) {
                          final s = sales.items[i];
                          return InkWell(
                            onTap: () => {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SaleDetailScreen(saleId: s.saleId),
                                ),
                              )

                            },
                            child: Container(
                              color: i.isEven ? const Color.fromARGB(120, 135, 180, 194) : Colors.white,
                              child: Row(
                                children: [
                                  _DataCell('#${s.saleId}'),
                                  _DataCell(df.format(s.date)),
                                  _DataCell(s.customerName ?? '-'),
                                  _DataCell(s.userName ?? '-'),
                                  _DataCell(s.totalAmount ?? '0'),
                                  _DataCell(s.status ? 'Vigente' : 'Cancelada'),
                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Cancelar (soft)',
                                          icon: const Icon(Icons.cancel, color: Colors.red),
                                          onPressed: s.status
                                              ? () async {
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      title: const Text('Cancelar venta'),
                                                      content: const Text('Se reingresará el stock de los renglones.'),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok == true) {
                                                    final res = await prov.cancel(s.saleId);
                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(res ? 'Venta cancelada' : (prov.error ?? 'Error'))),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey.shade900,
        icon: const Icon(Icons.add),
        label: const Text('Nueva venta'),
        onPressed: () async {
          final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSaleScreen()));
          if (!mounted) return;
          if (created == true) prov.fetchAll(q: _qCtrl.text);
        },
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) =>
      Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));
}

class _DataCell extends StatelessWidget {
  final String value;
  const _DataCell(this.value);
  @override
  Widget build(BuildContext context) =>
      Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(value)));
}
