import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:erpraf/controllers/MovementsProvider.dart';
import 'package:erpraf/controllers/InventoryProvider.dart';
import 'package:erpraf/controllers/AuthProvider.dart';
import 'package:erpraf/models/inventory/product_item.dart' show ProductItem;

class CreateMovementScreen extends StatefulWidget {
  const CreateMovementScreen({super.key});

  @override
  State<CreateMovementScreen> createState() => _CreateMovementScreenState();
}

class _CreateMovementScreenState extends State<CreateMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  String? _type; // 'IN' | 'OUT' | 'ADJ'
  int? _productId;

  late MovementsProvider movProv;
  late InventoryProvider invProv;
  late AuthProvider authProv;
  bool _didInit = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      movProv = context.read<MovementsProvider>();
      invProv = context.read<InventoryProvider>();
      authProv = context.read<AuthProvider>();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Solo productos activos
        invProv.fetchAll(includeInactive: false);
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      });

      _didInit = true;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final init = DateTime.tryParse('${_dateCtrl.text}T00:00:00') ?? now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
      initialDate: init,
    );
    if (picked != null) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  ProductItem? get _selectedProduct {
    final all = context.read<InventoryProvider>().items;
    try {
      return all.firstWhere((p) => p.id == _productId);
    } catch (_) {
      return null;
    }
  }

  int _parseAmount() {
    final t = _amountCtrl.text.trim();
    if (t.isEmpty) return 0;
    final n = int.tryParse(t);
    return (n ?? 0);
  }

  /// Máximo permitido para salida respetando stock mínimo.
  /// permitidos = max(0, stock - stockMin)
  int _maxOutAllowedFor(ProductItem p) {
    final stock = p.stock.floor();
    final stockMin = p.stockMin.floor();
    final allowed = stock - stockMin;
    return allowed > 0 ? allowed : 0;
  }

  String? _amountErrorText() {
    // Solo validamos reglas adicionales cuando hay tipo y producto
    if (_type == null || _productId == null) return null;

    // Entero > 0
    final qty = _parseAmount();
    if (qty <= 0) return 'Debe ser un entero mayor a 0';

    final prod = _selectedProduct;
    if (prod == null) return null;

    if (_type == 'OUT') {
      final stock = prod.stock.floor();
      final allowed = _maxOutAllowedFor(prod);

      if (stock <= 0) {
        return 'No hay existencia para retirar.';
      }
      if (qty > stock) {
        return 'No puedes retirar más de $stock (existencia actual).';
      }
      if (qty > allowed) {
        final min = prod.stockMin.floor();
        return 'Máximo permitido: $allowed (existencia: $stock, mínimo: $min).';
      }
    }

    if (_type == 'ADJ') {
      final min = prod.stockMin.floor();
      // El ajuste fija el stock; no puede ser menor al mínimo
      if (qty < min) {
        return 'El ajuste no puede ser menor al mínimo ($min).';
      }
    }

    // IN no tiene tope superior aquí
    return null;
  }

  bool get _canSubmit {
    if (_saving) return false;
    if (_productId == null || _type == null) return false;
    final err = _amountErrorText();
    return err == null && _formKey.currentState?.validate() != false;
  }

  Future<void> _save() async {
    // Forzamos validaciones de formulario
    if (!_formKey.currentState!.validate()) return;

    // Validaciones adicionales de negocio (OUT / ADJ)
    final extraErr = _amountErrorText();
    if (extraErr != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(extraErr)));
      return;
    }

    if (_productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }

    final uid = authProv.userId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tu sesión caducó. Vuelve a iniciar sesión.')),
      );
      return;
    }

    setState(() => _saving = true);

    final ok = await movProv.createMovement(
      productId: _productId!,
      type: _type!,
      amount: _amountCtrl.text.trim(),
      date: DateTime.tryParse('${_dateCtrl.text}T00:00:00'),
      userId: uid,
    );

    setState(() => _saving = false);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      final err = movProv.error ?? 'No se pudo registrar el movimiento';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;

    // Solo activos
    final all = context.watch<InventoryProvider>().items;
    final products = all.where((p) => p.status == true).toList();

    final p = _selectedProduct;
    final isOut = _type == 'OUT';
    final isAdj = _type == 'ADJ';

    final infoText = (p == null)
        ? null
        : isOut
            ? 'Existencia: ${p.stock.floor()}  |  Mínimo: ${p.stockMin.floor()}  |  Máx. retirar: ${_maxOutAllowedFor(p)}'
            : (isAdj
                ? 'Existencia: ${p.stock.floor()}  |  Mínimo: ${p.stockMin.floor()}'
                : null);

    final amountExtraError = _amountErrorText();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar movimiento'),
        backgroundColor: primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Producto (solo activos)
                      DropdownButtonFormField<int>(
                        value: _productId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Producto *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        items: products.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text('#${p.id} — ${p.name}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _productId = v),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),

                      // Tipo
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de movimiento *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'IN', child: Text('Entrada (IN)')),
                          DropdownMenuItem(
                              value: 'OUT', child: Text('Salida (OUT)')),
                          DropdownMenuItem(
                              value: 'ADJ', child: Text('Ajuste (ADJ)')),
                        ],
                        onChanged: (v) => setState(() => _type = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),

                      // Cantidad (enteros)
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: 'Cantidad *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.numbers),
                          // Si hay error extra de negocio, lo mostramos aquí también
                          errorText: amountExtraError,
                          helperText: infoText,
                          helperMaxLines: 2,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          final i = int.tryParse(v);
                          if (i == null || i <= 0)
                            return 'Debe ser un entero > 0';
                          return null; // el resto se valida con _amountErrorText()
                        },
                      ),
                      const SizedBox(height: 12),

                      // Fecha (opcional)
                      TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.date_range),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: _pickDate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.pop(context, false),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _canSubmit ? _save : null,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label:
                                  Text(_saving ? 'Guardando...' : 'Registrar'),
                            ),
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
      ),
    );
  }
}
