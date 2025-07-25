import 'package:flutter/material.dart';

class EditSupplierScreen extends StatefulWidget {
  final Map<String, dynamic> supplier;

  const EditSupplierScreen({super.key, required this.supplier});

  @override
  State<EditSupplierScreen> createState() => _EditSupplierScreenState();
}

class _EditSupplierScreenState extends State<EditSupplierScreen> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _metodoPagoCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _categoriaCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.supplier['Nombre']);
    _telefonoCtrl = TextEditingController(text: widget.supplier['Telefono'].toString());
    _metodoPagoCtrl = TextEditingController(text: widget.supplier['MetodoPago']);
    _direccionCtrl = TextEditingController(text: widget.supplier['Direccion']);
    _categoriaCtrl = TextEditingController(text: widget.supplier['Categoria']);
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

  void _guardarCambios() {
    final proveedorActualizado = {
      'id': widget.supplier['id'],
      'Nombre': _nombreCtrl.text.trim(),
      'Telefono': _telefonoCtrl.text.trim(),
      'MetodoPago': _metodoPagoCtrl.text.trim(),
      'Direccion': _direccionCtrl.text.trim(),
      'Categoria': _categoriaCtrl.text.trim(),
    };

    print("Proveedor actualizado: $proveedorActualizado");
    Navigator.pop(context, proveedorActualizado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Proveedor"),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefonoCtrl,
              decoration: const InputDecoration(labelText: "Teléfono", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _metodoPagoCtrl,
              decoration: const InputDecoration(labelText: "Método de Pago", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(labelText: "Dirección", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoriaCtrl,
              decoration: const InputDecoration(labelText: "Categoría", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _guardarCambios,
              child: const Text("Guardar Cambios"),
            )
          ],
        ),
      ),
    );
  }
}
