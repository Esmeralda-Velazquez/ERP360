import 'package:flutter/material.dart';

class CreateSupplierScreen extends StatefulWidget {
  const CreateSupplierScreen({super.key});

  @override
  State<CreateSupplierScreen> createState() => _CreateSupplierScreenState();
}

class _CreateSupplierScreenState extends State<CreateSupplierScreen> {
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _metodoPagoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _metodoPagoCtrl.dispose();
    _direccionCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  void _guardarProveedor() {
    final nombre = _nombreCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();
    final metodoPago = _metodoPagoCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final categoria = _categoriaCtrl.text.trim();

    if (nombre.isEmpty || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y Teléfono son obligatorios')),
      );
      return;
    }

    final proveedor = {
      'Nombre': nombre,
      'Telefono': telefono,
      'MetodoPago': metodoPago,
      'Direccion': direccion,
      'Categoria': categoria,
    };

    print("Nuevo proveedor creado: $proveedor");
    Navigator.pop(context, proveedor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Proveedor"),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefonoCtrl,
              decoration: const InputDecoration(
                labelText: "Teléfono",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _metodoPagoCtrl,
              decoration: const InputDecoration(
                labelText: "Método de Pago",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(
                labelText: "Dirección",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoriaCtrl,
              decoration: const InputDecoration(
                labelText: "Categoría",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _guardarProveedor,
              child: const Text("Guardar Proveedor"),
            )
          ],
        ),
      ),
    );
  }
}
