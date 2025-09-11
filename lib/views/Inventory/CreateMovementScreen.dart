import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:erpraf/controllers/MovementsProvider.dart';
import 'package:erpraf/controllers/InventoryProvider.dart';

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
  bool _didInit = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      movProv = context.read<MovementsProvider>();
      invProv = context.read<InventoryProvider>();
      // Carga productos si no hay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (invProv.items.isEmpty) {
          invProv.fetchAll();
        }
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }
    setState(() => _saving = true);

    final ok = await movProv.createMovement(
      productId: _productId!,
      type: _type!,
      amount: _amountCtrl.text.trim(),
      date: DateTime.tryParse('${_dateCtrl.text}T00:00:00'),
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
    final products = context.watch<InventoryProvider>().items;

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Producto
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
                          DropdownMenuItem(value: 'IN',  child: Text('Entrada (IN)')),
                          DropdownMenuItem(value: 'OUT', child: Text('Salida (OUT)')),
                          DropdownMenuItem(value: 'ADJ', child: Text('Ajuste (ADJ)')),
                        ],
                        onChanged: (v) => setState(() => _type = v),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),

                      // Cantidad
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          final d = double.tryParse(v);
                          if (d == null || d <= 0) return 'Debe ser numérico > 0';
                          return null;
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
                              onPressed: _saving ? null : () => Navigator.pop(context, false),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_saving ? 'Guardando...' : 'Registrar'),
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
