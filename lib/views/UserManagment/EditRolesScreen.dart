import 'package:flutter/material.dart';

class EditRolesScreen extends StatefulWidget {
  final Map<String, dynamic> roles;

  const EditRolesScreen({super.key, required this.roles});

  @override
  State<EditRolesScreen> createState() => _EditRolesScreenState();
}

class _EditRolesScreenState extends State<EditRolesScreen> {
  final _nombreRolCtrl = TextEditingController();
  bool _statusActivo = true;

  final Map<String, bool> _permisosSeleccionados = {
    'Crear': false,
    'Editar': false,
    'Ver': false,
    'Eliminar': false,
  };

  @override
  void initState() {
    super.initState();

    final rol = widget.roles;

    _nombreRolCtrl.text = rol['nombreRol'] ?? '';
    _statusActivo = rol['status'] ?? true;

    final permisos = (rol['permisos'] as List?)?.cast<String>() ?? [];
    for (var permiso in permisos) {
      _permisosSeleccionados[permiso] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text("Editar Rol"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nombreRolCtrl,
              decoration: const InputDecoration(labelText: "Nombre del Rol"),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            const Text(
              "Permisos:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Column(
              children: _permisosSeleccionados.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (value) {
                    setState(() {
                      _permisosSeleccionados[entry.key] = value!;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                final rolActualizado = {
                  'nombreRol': _nombreRolCtrl.text,
                  'status': _statusActivo,
                  'permisos': _permisosSeleccionados.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList(),
                };

                print("Rol actualizado: $rolActualizado");

                // Aquí podrías navegar o mostrar un mensaje de éxito
              },
              child: const Text("Guardar cambios"),
            )
          ],
        ),
      ),
    );
  }
}
