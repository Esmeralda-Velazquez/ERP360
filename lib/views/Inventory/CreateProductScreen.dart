import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/InventoryProvider.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockMinCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(); // existencia inicial

  bool _saving = false;
  late InventoryProvider inv;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    inv = context.read<InventoryProvider>();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _brandCtrl.dispose();
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    _priceCtrl.dispose();
    _stockMinCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      "name": _nameCtrl.text.trim(),
      "category": _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      "brand": _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      "size": _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
      "color": _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      "price": _priceCtrl.text.trim().isEmpty ? null : _priceCtrl.text.trim(),
    };

    final smText = _stockMinCtrl.text.trim();
    if (smText.isNotEmpty) {
      final sm = int.tryParse(smText);
      if (sm != null) payload["stockMin"] = sm;
    }

    final stockText = _stockCtrl.text.trim();
    if (stockText.isNotEmpty) {
      final st = int.tryParse(stockText);
      if (st != null) payload["stock"] = st;
    }

    final ok = await inv.create(payload);

    setState(() => _saving = false);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      final err = inv.error ?? 'No se pudo crear el producto';
      AppSnackBar.show(
        context,
        type: SnackType.error,
        message: err,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo producto'),
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
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _categoryCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _brandCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Marca',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sizeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Talla',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _colorCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stockMinCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Stock mínimo',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.production_quantity_limits_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Existencia inicial',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.add_box_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                        ],
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
                              onPressed: _saving ? null : _guardar,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_saving ? 'Guardando...' : 'Crear producto'),
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
