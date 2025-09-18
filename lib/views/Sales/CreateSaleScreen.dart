import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:erpraf/controllers/SalesProvider.dart';
import 'package:erpraf/controllers/InventoryProvider.dart';
import 'package:erpraf/controllers/CustomerProvider.dart';
import 'package:erpraf/controllers/AuthProvider.dart';
import 'package:erpraf/models/sales/sale_models.dart';
import 'package:erpraf/models/CustomerModels/customer_option.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

import 'package:erpraf/views/UserManagment/CreateCustomerScreen.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

final List<String> _paymentMethods = [
  'Efectivo',
  'Tarjeta de crédito',
  'Tarjeta de débito',
  'Transferencia bancaria',
  'Cheque',
  'PayPal',
];

String? _selectedPayment;

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Cabecera
  final _paymentCtrl = TextEditingController(text: 'Efectivo');
  final _dateCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');

  // Producto para carrito
  int? _selectedProductId;
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();

  // Cliente seleccionado
  int? _selectedCustomerId;

  final List<SaleRow> _rows = [];

  late InventoryProvider invProv;
  late SalesProvider salesProv;
  late CustomerProvider custProv;

  bool _didInit = false;
  bool _saving = false;

  // ==== Formateador MXN solo para UI ====
  final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
  String fmtMoney(num? v) => _mxn.format(v ?? 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _selectedPayment ??= _paymentMethods.first;
      invProv = context.read<InventoryProvider>();
      salesProv = context.read<SalesProvider>();
      custProv = context.read<CustomerProvider>();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (invProv.items.isEmpty) invProv.fetchAll();
        await custProv.fetchOptions();
        _dateCtrl.text = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      });

      _didInit = true;
    }
  }

  @override
  void dispose() {
    _paymentCtrl.dispose();
    _dateCtrl.dispose();
    _discountCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _onSelectProduct(int id) {
    final p = invProv.items.firstWhere((e) => e.id == id);
    _selectedProductId = id;
    _priceCtrl.text = (p.price ?? '').isEmpty ? '0' : p.price!;
    setState(() {});
  }

  void _addRow() {
    if (_selectedProductId == null) {
      AppSnackBar.show(
        context,
        type: SnackType.warning,
        title: 'Cuidado',
        message: 'Selecciona un producto',
      );
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text.trim());
    final prc = double.tryParse(_priceCtrl.text.trim());
    if (qty == null || qty <= 0 || prc == null || prc < 0) {
      AppSnackBar.show(
        context,
        type: SnackType.warning,
        title: 'Cuidado',
        message: 'Cantidad/Precio inválidos',
      );
      return;
    }

    final p = invProv.items.firstWhere((e) => e.id == _selectedProductId);
    _rows.add(SaleRow(
      productId: p.id,
      productName: p.name,
      quantity: qty.toString(),
      price: prc.toStringAsFixed(2),
    ));
    setState(() {
      _selectedProductId = null;
      _qtyCtrl.text = '1';
      _priceCtrl.clear();
    });
  }

  // Totales
  double get _subtotal {
    double s = 0;
    for (final r in _rows) {
      final q = double.tryParse(r.quantity) ?? 0;
      final p = double.tryParse(r.price) ?? 0;
      final d = double.tryParse(r.discount ?? '0') ?? 0;
      s += (q * p) - d;
    }
    return s;
  }

  double get _iva => (_subtotal * 0.16);

  double get _total {
    final globalDisc = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    return (_subtotal + _iva) - globalDisc;
  }

  Future<void> _save() async {
    if (_rows.isEmpty) {
      AppSnackBar.show(
        context,
        type: SnackType.warning,
        title: 'Cuidado',
        message: 'Agrega al menos un producto',
      );
      return;
    }
    if (_selectedCustomerId == null) {
      AppSnackBar.show(
        context,
        type: SnackType.warning,
        title: 'Cuidado',
        message: 'Selecciona un cliente',
      );
      return;
    }

    setState(() => _saving = true);

    final userId = context.read<AuthProvider>().userId;

    final req = CreateSaleRequest(
      paymentMethod: _selectedPayment,
      totalAmount: _total.toStringAsFixed(2),
      iva: _iva.toStringAsFixed(2),
      date: DateTime.tryParse(_dateCtrl.text.replaceFirst(' ', 'T')),
      customerId: _selectedCustomerId,
      items: _rows,
      userId: userId,
    );

    final (ok, id) = await salesProv.create(req);
    setState(() => _saving = false);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      AppSnackBar.show(
        context,
        type: SnackType.success,
        title: 'Éxito',
        message: 'Venta creada (ID: $id)',
      );
    } else {
      final err = salesProv.error ?? 'No se pudo crear la venta';
      AppSnackBar.show(
        context,
        type: SnackType.error,
        title: 'Error',
        message: err,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<InventoryProvider>().items;
    final customers = context.watch<CustomerProvider>().options;

    final primary = Colors.blueGrey.shade900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva venta'),
        backgroundColor: primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // === Cliente (dropdown) + botón (+) ===
                        SizedBox(
                          width: 360,
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedCustomerId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Cliente *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: customers
                                      .map((CustomerOption c) =>
                                          DropdownMenuItem(
                                            value: c.id,
                                            child: Text('#${c.id} — ${c.name}'),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedCustomerId = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Crear cliente',
                                child: Ink(
                                  decoration: ShapeDecoration(
                                    color: primary,
                                    shape: const CircleBorder(),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add,
                                        color: Colors.white),
                                    onPressed: () async {
                                      final created = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CreateCustomerScreen(),
                                        ),
                                      );
                                      if (!mounted) return;
                                      // Refresca la lista
                                      await context
                                          .read<CustomerProvider>()
                                          .fetchOptions();
                                      // Si la pantalla de crear regresó {id, name}, selecciona
                                      if (created is Map &&
                                          created['id'] != null) {
                                        setState(() => _selectedCustomerId =
                                            created['id'] as int);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            value: _selectedPayment,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Método de pago',
                              border: OutlineInputBorder(),
                            ),
                            items: _paymentMethods
                                .map((m) => DropdownMenuItem(
                                    value: m, child: Text(m)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedPayment = v),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: _dateCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selector de producto para agregar al carrito
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedProductId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Producto',
                              border: OutlineInputBorder(),
                            ),
                            items: products
                                .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text('#${p.id} — ${p.name}'),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _onSelectProduct(v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.right, // alineado
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: false),
                            inputFormatters: [
                              // solo números y punto decimal, max 2 decimales
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}$')),
                            ],
                            textAlign: TextAlign.right, // alineado
                            decoration: const InputDecoration(
                              labelText: 'Precio',
                              prefixText: '\$ ',
                              suffixText: 'MXN',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Encabezado de carrito
                    Container(
                      color: const Color.fromARGB(120, 57, 112, 129),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      child: const Row(
                        children: [
                          _Header('Producto', flex: 4),
                          _Header('Cantidad', flex: 2, right: true),
                          _Header('Precio',   flex: 2, right: true),
                          _Header('Importe',  flex: 2, right: true),
                        ],
                      ),
                    ),

                    // Carrito
                    Expanded(
                      child: ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (ctx, i) {
                          final r = _rows[i];
                          final q = double.tryParse(r.quantity) ?? 0;
                          final p = double.tryParse(r.price) ?? 0;
                          final imp = q * p;
                          return Container(
                            color: i.isEven
                                ? const Color.fromARGB(120, 135, 180, 194)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 6),
                            child: Row(
                              children: [
                                _Cell(r.productName, flex: 4),
                                _Cell(q.toStringAsFixed(0),
                                    flex: 2, right: true),
                                _Cell(fmtMoney(p), flex: 2, right: true),
                                _Cell(fmtMoney(imp), flex: 2, right: true),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() => _rows.removeAt(i));
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Totales + Guardar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _totalRow('Subtotal', _subtotal),
                            _totalRow('IVA (16%)', _iva),
                            _totalRow('Total', _total, bold: true),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => Navigator.pop(context, false),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Cancelar'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.check),
                                  label: Text(_saving
                                      ? 'Guardando...'
                                      : 'Confirmar venta'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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

  Widget _totalRow(String label, double val, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              fmtMoney(val), // ← Mostrar en pesos MXN
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
}

// ===== helpers visuales con alineación y flex =====
class _Header extends StatelessWidget {
  final String t;
  final int flex;
  final bool right;
  const _Header(this.t, {this.flex = 1, this.right = false, super.key});
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          t,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
}

class _Cell extends StatelessWidget {
  final String t;
  final int flex;
  final bool right;
  const _Cell(this.t, {this.flex = 1, this.right = false, super.key});
  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          t,
          textAlign: right ? TextAlign.right : TextAlign.left,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 14),
        ),
      );
}
