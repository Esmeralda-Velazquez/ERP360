import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/SalesProvider.dart';
import 'package:erpraf/models/sales/sale_detail.dart';
import 'package:erpraf/widgets/nice_dialogs.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

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

  bool _sending = false; // estado de envío por correo

  // ==== Formateadores ====
  final _df = DateFormat('yyyy-MM-dd HH:mm');
  final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
  final _intFmt = NumberFormat.decimalPattern('es_MX');

  String fmtMoneyNum(num? v) => _mxn.format((v ?? 0).toDouble());
  String fmtMoneyStr(String? raw) => fmtMoneyNum(double.tryParse((raw ?? '0').trim()));

  /// Cantidades como entero con separador de miles
  String fmtQtyNum(num? v) => _intFmt.format((v ?? 0).round());
  String fmtQtyStr(String? raw) => fmtQtyNum(double.tryParse((raw ?? '0').trim()));

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

  bool _isValidEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return false;
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(s);
  }

  Future<String?> _askEmail(BuildContext context, {String? initial}) async {
    final ctrl = TextEditingController(text: initial ?? '');
    final primary = Colors.blueGrey.shade900;

    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            // para que no tape el teclado
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enviar comprobante por email',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo del cliente',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                autofocus: true,
                onSubmitted: (_) => Navigator.pop(ctx, ctrl.text.trim()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (email == null) return null;
    return email.trim();
  }

  Future<void> _sendReceipt() async {
    if (_detail == null) return;

    // 1) Tomar email del cliente si existe, si no pedirlo
    String? email = (_detail!.customerEmail ?? '').trim();
    if (email.isEmpty) {
      email = await _askEmail(context);
      if (email == null) return; // canceló
    }

    if (!_isValidEmail(email)) {
      AppSnackBar.show(
        context,
        message: 'Correo inválido. Verifica y vuelve a intentar.',
        type: SnackType.error,
      );
      return;
    }

    // 2) Confirmar
    final ok = await NiceDialogs.showConfirm(
      context,
      title: 'Enviar comprobante',
      message: 'Se enviará el comprobante de la venta #${_detail!.saleId} a:\n$email',
      confirmText: 'Enviar',
      cancelText: 'Cancelar',
      icon: Icons.mail_outline_rounded,
      accentColor: Colors.blueGrey.shade900,
      barrierDismissible: false,
    );
    if (ok != true) return;

    // 3) Llamar Provider
    try {
      setState(() => _sending = true);
      final prov = context.read<SalesProvider>();
      final sent = await prov.emailReceipt(widget.saleId, toEmail: email);
      if (!mounted) return;
      setState(() => _sending = false);

      if (sent) {
        AppSnackBar.show(
          context,
          message: 'Comprobante enviado a $email',
          type: SnackType.success,
        );
      } else {
        AppSnackBar.show(
          context,
          message: prov.error ?? 'No fue posible enviar el comprobante.',
          type: SnackType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      AppSnackBar.show(
        context,
        message: 'Error inesperado: $e',
        type: SnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: Text('Venta #${widget.saleId}'),
        actions: [
          IconButton(
            tooltip: 'Enviar por correo',
            onPressed: _loading || _detail == null || _sending ? null : _sendReceipt,
            icon: _sending
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.mail_outline_rounded),
          ),
        ],
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
                                  Text(
                                    'RECIBO DE VENTA',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Folio: ${_detail!.saleId}', textAlign: TextAlign.center),
                                  Text('Fecha: ${_df.format(_detail!.date)}', textAlign: TextAlign.center),
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
                                        _HeaderCell('Producto', flex: 4),
                                        _HeaderCell('Cant.',  flex: 2, right: true),
                                        _HeaderCell('Precio', flex: 2, right: true),
                                        _HeaderCell('Desc.',  flex: 2, right: true),
                                        _HeaderCell('Importe',flex: 2, right: true),
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
                                              _DataCell('${it.productName} (#${it.productId})', flex: 4),
                                              _DataCell(fmtQtyNum(q),       flex: 2, right: true),
                                              _DataCell(fmtMoneyNum(p),     flex: 2, right: true),
                                              _DataCell(d == 0 ? '-' : fmtMoneyNum(d), flex: 2, right: true),
                                              _DataCell(fmtMoneyNum(imp),   flex: 2, right: true),
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
                                        _totalRow('Subtotal', _detail!.subtotal != null
                                          ? fmtMoneyStr(_detail!.subtotal)
                                          : fmtMoneyNum(_calcSubtotal(_detail!))),
                                        _totalRow('IVA (16%)', _detail!.iva != null
                                          ? fmtMoneyStr(_detail!.iva)
                                          : fmtMoneyNum(_calcIva(_detail!))),
                                        _totalRow('Total', _detail!.totalAmount != null
                                          ? fmtMoneyStr(_detail!.totalAmount)
                                          : fmtMoneyNum(_calcTotal(_detail!)), bold: true),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Botón extra al pie (opcional, además del AppBar)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                                      onPressed: _sending ? null : _sendReceipt,
                                      icon: _sending
                                          ? const SizedBox(
                                              width: 16, height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Icon(Icons.mail_outline_rounded),
                                      label: const Text('Enviar por correo'),
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
            Text(
              '$label: ',
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            ),
            Text(
              value,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.right,
            ),
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

// ==== Helpers visuales con flex y alineación ====

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool right;
  const _HeaderCell(this.label, {this.flex = 1, this.right = false, super.key});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: right ? TextAlign.right : TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
        child: Text(
          value,
          textAlign: right ? TextAlign.right : TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      );
}
