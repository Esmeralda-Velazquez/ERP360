import 'package:flutter/material.dart';

class CreateRoleScreen extends StatefulWidget {
  const CreateRoleScreen({super.key});

  @override
  State<CreateRoleScreen> createState() => _CreateRoleScreenState();
}

class _CreateRoleScreenState extends State<CreateRoleScreen> {
  final _nombreRolCtrl = TextEditingController();
  bool _statusActivo = true;

  final Map<String, bool> _permisosSeleccionados = {
    'Crear': false,
    'Editar': false,
    'Ver': false,
    'Eliminar': false,
  };

  @override
  void dispose() {
    _nombreRolCtrl.dispose();
    super.dispose();
  }

  void _guardarRol() {
    final nombreRol = _nombreRolCtrl.text.trim();
    if (nombreRol.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre del rol')),
      );
      return;
    }

    final rolCreado = {
      'nombreRol': nombreRol,
      'status': _statusActivo,
      'permisos': _permisosSeleccionados.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
    };

    print("Nuevo rol creado: $rolCreado");
    Navigator.pop(context, rolCreado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text("Crear Nuevo Rol"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nombreRolCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre del Rol",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text("Estado (Activo/Inactivo)"),
              value: _statusActivo,
              onChanged: (value) {
                setState(() {
                  _statusActivo = value;
                });
              },
              activeColor: Colors.green,
              inactiveThumbColor: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              "Permisos:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Column(
              children: _permisosSeleccionados.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (value) {
                    setState(() {
                      _permisosSeleccionados[entry.key] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _guardarRol,
              child: const Text(
                "Crear Rol",
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
