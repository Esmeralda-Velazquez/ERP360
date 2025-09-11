import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/SalesProvider.dart';
import 'package:erpraf/models/sales/sale_detail.dart';

class SaleDetailScreen extends StatefulWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  SaleDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prov = context.read<SalesProvider>();
    final (ok, data) = await prov.fetchById(widget.saleId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (ok && data != null) {
        _detail = data;
      } else {
        _error = prov.error ?? 'No fue posible cargar el detalle';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: Text('Venta #${widget.saleId}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _detail == null
                  ? const Center(child: Text('Sin datos'))
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Encabezado tipo recibo
                                  Text('RECIBO DE VENTA', textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text('Folio: ${_detail!.saleId}', textAlign: TextAlign.center),
                                  Text('Fecha: ${df.format(_detail!.date)}', textAlign: TextAlign.center),
                                  Text('Estado: ${_detail!.status ? 'Vigente' : 'Cancelada'}', textAlign: TextAlign.center),
                                  const Divider(height: 24),

                                  // Cliente y usuario
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _infoBlock('Cliente', [
                                          'ID: ${_detail!.customerId ?? '-'}',
                                          'Nombre: ${_detail!.customerName ?? '-'}',
                                          if ((_detail!.customerEmail ?? '').isNotEmpty) 'Correo: ${_detail!.customerEmail}',
                                          if ((_detail!.customerPhone ?? '').isNotEmpty) 'Tel: ${_detail!.customerPhone}',
                                        ]),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _infoBlock('Atendió', [
                                          'ID: ${_detail!.userId ?? '-'}',
                                          'Usuario: ${_detail!.userName ?? '-'}',
                                          'Pago: ${_detail!.paymentMethod ?? '-'}',
                                        ]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Encabezado de items
                                  Container(
                                    color: const Color.fromARGB(120, 57, 112, 129),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    child: const Row(
                                      children: [
                                        _HeaderCell('Producto'),
                                        _HeaderCell('Cant.'),
                                        _HeaderCell('Precio'),
                                        _HeaderCell('Desc.'),
                                        _HeaderCell('Importe'),
                                      ],
                                    ),
                                  ),

                                  // Lista de items
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _detail!.items.length,
                                      itemBuilder: (_, i) {
                                        final it = _detail!.items[i];
                                        final q = double.tryParse(it.quantity) ?? 0;
                                        final p = double.tryParse(it.price) ?? 0;
                                        final d = double.tryParse(it.discount ?? '0') ?? 0;
                                        final imp = (q * p) - d;
                                        return Container(
                                          color: i.isEven
                                              ? const Color.fromARGB(120, 135, 180, 194)
                                              : Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                          child: Row(
                                            children: [
                                              _DataCell('${it.productName} (#${it.productId})'),
                                              _DataCell(it.quantity),
                                              _DataCell(p.toStringAsFixed(2)),
                                              _DataCell(d == 0 ? '-' : d.toStringAsFixed(2)),
                                              _DataCell(imp.toStringAsFixed(2)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 6),
                                  const Divider(),

                                  // Totales
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _totalRow('Subtotal', _detail!.subtotal ?? _calcSubtotal(_detail!).toStringAsFixed(2)),
                                        _totalRow('IVA', _detail!.iva ?? _calcIva(_detail!).toStringAsFixed(2)),
                                        _totalRow('Total', _detail!.totalAmount ?? _calcTotal(_detail!).toStringAsFixed(2), bold: true),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _infoBlock(String title, List<String> lines) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ...lines.map((t) => Text(t)).toList(),
      ],
    ),
  );

  Widget _totalRow(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$label: ', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    ),
  );

  double _calcSubtotal(SaleDetail d) {
    double s = 0;
    for (final it in d.items) {
      final q = double.tryParse(it.quantity) ?? 0;
      final p = double.tryParse(it.price) ?? 0;
      final disc = double.tryParse(it.discount ?? '0') ?? 0;
      s += (q * p) - disc;
    }
    return s;
  }

  double _calcIva(SaleDetail d) => _calcSubtotal(d) * 0.16;
  double _calcTotal(SaleDetail d) => _calcSubtotal(d) + _calcIva(d);
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) =>
      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)));
}

class _DataCell extends StatelessWidget {
  final String value;
  const _DataCell(this.value);
  @override
  Widget build(BuildContext context) =>
      Expanded(child: Text(value));
}
