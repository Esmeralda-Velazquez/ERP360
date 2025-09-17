import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/SupplierProvider.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

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
  final _categoriaCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    // Prellenar campos desde el mapa recibido
    _nombreCtrl.text      = (widget.supplier['Nombre'] ?? '').toString();
    _telefonoCtrl.text    = (widget.supplier['Telefono'] ?? '').toString();
    _metodoPagoCtrl.text  = (widget.supplier['MetodoPago'] ?? '').toString();
    _direccionCtrl.text   = (widget.supplier['Direccion'] ?? '').toString();
    _categoriaCtrl.text   = (widget.supplier['Categoria'] ?? '').toString(); // <-- categoría como texto
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _metodoPagoCtrl.dispose();
    _direccionCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  Future<void> _actualizarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    final categoria = _categoriaCtrl.text.trim();

    final payload = {
      "supplierName": _nombreCtrl.text.trim(),
      "phoneNumber": _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
      "paymentMethod": _metodoPagoCtrl.text.trim().isEmpty ? null : _metodoPagoCtrl.text.trim(),
      "address": _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      "categorySupplierId": categoria.isEmpty ? null : categoria,
    };

    setState(() => _submitting = true);
    final id = int.tryParse(widget.supplier['id'].toString())!;
    final ok = await context.read<SupplierProvider>().update(id, payload);
    setState(() => _submitting = false);

    if (!mounted) return;

    if (ok) {
      AppSnackBar.show(
        context,
        type: SnackType.success,
        title: 'Proveedor actualizado',
        message: 'Se actualizaron los datos de ${_nombreCtrl.text.trim()}',
      );
      Navigator.pop(context, true);
    } else {
      final error = context.read<SupplierProvider>().error ?? 'No se pudo actualizar el proveedor';
      AppSnackBar.show(
        context,
        type: SnackType.error,
        title: 'Error',
        message: error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;

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

                      TextFormField(
                        controller: _telefonoCtrl,
                        decoration: const InputDecoration(
                          labelText: "Teléfono",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final x = (v ?? '').trim();
                          if (x.isEmpty) return 'El teléfono es obligatorio';
                          if (x.length != 10) return 'Debe tener exactamente 10 dígitos';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

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

                      TextFormField(
                        controller: _categoriaCtrl,
                        decoration: const InputDecoration(
                          labelText: "Categoría (opcional)",
                          hintText: "Ej. Materias primas",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        textInputAction: TextInputAction.done,
                      ),

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
