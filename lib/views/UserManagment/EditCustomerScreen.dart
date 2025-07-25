import 'package:flutter/material.dart';

class EditCustomerScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _nombreClienteCtrl = TextEditingController();
  final _telefonoClienteCtrl = TextEditingController();
  final _correoClienteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;

    _nombreClienteCtrl.text = customer['Nombre'] ?? '';
    _telefonoClienteCtrl.text = customer['Telefono']?.toString() ?? '';
    _correoClienteCtrl.text = customer['Correo'] ?? '';
  }

  @override
  void dispose() {
    _nombreClienteCtrl.dispose();
    _telefonoClienteCtrl.dispose();
    _correoClienteCtrl.dispose();
    super.dispose();
  }

  void _guardarCambios() {
    final clienteActualizado = {
      'Nombre': _nombreClienteCtrl.text.trim(),
      'Telefono': int.tryParse(_telefonoClienteCtrl.text.trim()) ?? 0,
      'Correo': _correoClienteCtrl.text.trim(),
    };

    print('Cliente actualizado: $clienteActualizado');

    // Aquí podrías guardar los cambios en la base de datos o backend

    // Regresar a la pantalla anterior con el nuevo cliente (opcional)
    Navigator.pop(context, clienteActualizado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text("Editar Cliente"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nombreClienteCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre del Cliente",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefonoClienteCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Teléfono",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _correoClienteCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Correo Electrónico",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _guardarCambios,
              child: const Text(
                "Guardar cambios",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
