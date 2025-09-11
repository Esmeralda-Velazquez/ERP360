import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/InventoryProvider.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product; 
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _sizeCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _priceCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.product['name']?.toString() ?? '');
    _categoryCtrl = TextEditingController(text: widget.product['category']?.toString() ?? '');
    _brandCtrl    = TextEditingController(text: widget.product['brand']?.toString() ?? '');
    _sizeCtrl     = TextEditingController(text: widget.product['size']?.toString() ?? '');
    _colorCtrl    = TextEditingController(text: widget.product['color']?.toString() ?? '');
    _priceCtrl    = TextEditingController(text: widget.product['price']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _brandCtrl.dispose();
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await context.read<InventoryProvider>().update(
      widget.product['id'] as int,
      {
        "nameProduct": _nameCtrl.text.trim(),
        "category": _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
        "brand": _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        "size": _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
        "color": _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
        "price": _priceCtrl.text.trim().isEmpty ? null : _priceCtrl.text.trim(),
      },
    );

    setState(() => _saving = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
      Navigator.pop(context, true);
    } else {
      final err = context.read<InventoryProvider>().error ?? 'No se pudo actualizar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar producto'), backgroundColor: primary),
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
                          labelText: 'Nombre del producto',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(
                            controller: _categoryCtrl,
                            decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(
                            controller: _brandCtrl,
                            decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(
                            controller: _sizeCtrl,
                            decoration: const InputDecoration(labelText: 'Talla', border: OutlineInputBorder()),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(
                            controller: _colorCtrl,
                            decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Precio (texto - tu BD usa varchar)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
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
                              onPressed: _saving ? null : _guardar,
                              icon: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_outlined),
                              label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                            ),
                          ),
                        ],
                      )
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
