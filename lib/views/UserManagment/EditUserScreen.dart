import 'package:flutter/material.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const EditUserScreen({super.key, required this.usuario});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  String? _rolSeleccionado;

  final Map<String, bool> _permisosSeleccionados = {};


  @override
  void initState() {
    super.initState();

    final u = widget.usuario;

    _nombreCtrl.text = u['nombre'] ?? '';
    _apellidoCtrl.text = u['apellido'] ?? '';
    _correoCtrl.text = u['email'] ?? '';
    _passwordCtrl.text = ''; 
    _areaCtrl.text = u['area'] ?? '';
    _rolSeleccionado = u['rol']?.toString();

        // Lista de permisos del usuario
    final permisosUsuario = (u['permisos'] as List?)?.cast<String>() ?? [];
    for (var permiso in permisosUsuario) {
      _permisosSeleccionados[permiso] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text("Editar usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: _apellidoCtrl,
              decoration: const InputDecoration(labelText: "Apellido"),
            ),
            TextField(
              controller: _correoCtrl,
              decoration: const InputDecoration(labelText: "Correo"),
            ),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),
            TextField(
              controller: _areaCtrl,
              decoration: const InputDecoration(labelText: "Área"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _rolSeleccionado,
              onChanged: (value) {
                setState(() {
                  _rolSeleccionado = value;
                });
              },
              items: ['Administrador', 'Editor', 'Lector']
                  .map((rol) => DropdownMenuItem(
                        value: rol,
                        child: Text(rol),
                      ))
                  .toList(),
              decoration: const InputDecoration(labelText: "Rol"),
            ),
            const SizedBox(height: 16),
            const Text(
              "Permisos:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Column(
              children: _permisosSeleccionados.keys.map((permiso) {
                return CheckboxListTile(
                  title: Text(permiso),
                  value: _permisosSeleccionados[permiso] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _permisosSeleccionados[permiso] = value!;
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
                // Aquí puedes armar el objeto actualizado
                final usuarioActualizado = {
                  'nombre': _nombreCtrl.text,
                  'apellido': _apellidoCtrl.text,
                  'email': _correoCtrl.text,
                  'password': _passwordCtrl.text,
                  'area': _areaCtrl.text,
                  'rol': _rolSeleccionado,
                  'permisos': _permisosSeleccionados.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList(),
                };

                print("Usuario actualizado: $usuarioActualizado");
              },
              child: const Text("Guardar cambios"),
            )
          ],
        ),
      ),
    );
  }
}
