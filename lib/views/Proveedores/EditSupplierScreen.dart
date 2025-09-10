import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/SupplierProvider.dart';
import 'package:erpraf/models/SupplierModels/SupplierCategory.dart';

class EditSupplierScreen extends StatefulWidget {
  final Map<String, dynamic> supplier; // viene desde la lista

  const EditSupplierScreen({super.key, required this.supplier});

  @override
  State<EditSupplierScreen> createState() => _EditSupplierScreenState();
}

class _EditSupplierScreenState extends State<EditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _metodoPagoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  int? _selectedCategoryId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    // Prellenar campos desde el mapa recibido
    _nombreCtrl.text   = (widget.supplier['Nombre'] ?? '').toString();
    _telefonoCtrl.text = (widget.supplier['Telefono'] ?? '').toString();
    _metodoPagoCtrl.text = (widget.supplier['MetodoPago'] ?? '').toString();
    _direccionCtrl.text  = (widget.supplier['Direccion'] ?? '').toString();

    // Cargar categorías y preseleccionar la del proveedor
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<SupplierProvider>();
      await prov.fetchCategories();

      final currentCategoryName = (widget.supplier['Categoria'] ?? '').toString().trim();
      if (currentCategoryName.isNotEmpty) {
        final cats = prov.categories;
        final match = cats.firstWhere(
          (c) => c.name.toLowerCase() == currentCategoryName.toLowerCase(),
          orElse: () => SupplierCategory(id: -1, name: ''),
        );
        if (match.id != -1) {
          setState(() => _selectedCategoryId = match.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _metodoPagoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _actualizarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      "supplierName": _nombreCtrl.text.trim(),
      "phoneNumber": _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
      "paymentMethod": _metodoPagoCtrl.text.trim().isEmpty ? null : _metodoPagoCtrl.text.trim(),
      "address": _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      "categorySupplierId": _selectedCategoryId, // puede ser null
    };

    setState(() => _submitting = true);
    final id = int.tryParse(widget.supplier['id'].toString())!;
    final ok = await context.read<SupplierProvider>().update(id, payload);
    setState(() => _submitting = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor actualizado con éxito')),
      );
      Navigator.pop(context, true);
    } else {
      final error = context.read<SupplierProvider>().error ?? 'No se pudo actualizar el proveedor';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;
    final prov = context.watch<SupplierProvider>();
    final List<SupplierCategory> cats = prov.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Proveedor"),
        backgroundColor: primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        'Editar proveedor',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nombre",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                          if (v.trim().length < 3) return 'Debe tener al menos 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Teléfono
                      TextFormField(
                        controller: _telefonoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Teléfono",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                        ],
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'El teléfono es obligatorio';
                          if (v.trim().length < 7) return 'Teléfono inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Método de pago / Email
                      TextFormField(
                        controller: _metodoPagoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Método de Pago / Email",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Dirección
                      TextFormField(
                        controller: _direccionCtrl,
                        decoration: const InputDecoration(
                          labelText: "Dirección",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Categoría (opcional) con Dropdown
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Categoría (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        child: prov.loadingCategories
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: LinearProgressIndicator(),
                              )
                            : DropdownButtonFormField<int?>(
                                isExpanded: true,
                                value: _selectedCategoryId,
                                decoration: const InputDecoration.collapsed(hintText: ''),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Sin categoría'),
                                  ),
                                  ...cats.map((c) => DropdownMenuItem<int?>(
                                        value: c.id,
                                        child: Text(c.name),
                                      )),
                                ],
                                onChanged: (v) => setState(() => _selectedCategoryId = v),
                              ),
                      ),
                      if (prov.categoriesError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          prov.categoriesError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _submitting ? null : () => Navigator.pop(context, false),
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
                              onPressed: _submitting ? null : _actualizarProveedor,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_submitting ? 'Guardando...' : 'Guardar cambios'),
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
