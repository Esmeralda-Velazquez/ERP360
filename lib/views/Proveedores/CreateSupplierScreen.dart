import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/SupplierProvider.dart';
import 'package:erpraf/models/SupplierModels/SupplierCategory.dart';

class CreateSupplierScreen extends StatefulWidget {
  const CreateSupplierScreen({super.key});

  @override
  State<CreateSupplierScreen> createState() => _CreateSupplierScreenState();
}

class _CreateSupplierScreenState extends State<CreateSupplierScreen> {
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
    // Carga categorías post-frame para no chocar con build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchCategories();
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

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      "supplierName": _nombreCtrl.text.trim(),
      "phoneNumber": _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
      "paymentMethod": _metodoPagoCtrl.text.trim().isEmpty ? null : _metodoPagoCtrl.text.trim(),
      "address": _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      "categorySupplierId": _selectedCategoryId, // puede ser null
    };

    setState(() => _submitting = true);
    final ok = await context.read<SupplierProvider>().create(payload);
    setState(() => _submitting = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor creado con éxito')),
      );
      Navigator.pop(context, true);
    } else {
      final error = context.read<SupplierProvider>().error ?? 'No se pudo crear el proveedor';
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
        title: const Text("Crear Proveedor"),
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
                        'Nuevo proveedor',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nombre",
                          hintText: "Ej. Guillermo Guerrero",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                          if (v.trim().length < 3) return 'El nombre debe tener al menos 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Teléfono
                      TextFormField(
                        controller: _telefonoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Teléfono",
                          hintText: "Ej. 479535686",
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

                      // Método de pago (tu ejemplo usa email)
                      TextFormField(
                        controller: _metodoPagoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Método de Pago / Email",
                          hintText: "Ej. compras@acme.com",
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
                          hintText: "Ej. Calle Falsa 123",
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
                              onPressed: _submitting ? null : _guardarProveedor,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_submitting ? 'Guardando...' : 'Guardar Proveedor'),
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
