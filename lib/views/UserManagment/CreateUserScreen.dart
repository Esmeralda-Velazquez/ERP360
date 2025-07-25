import 'package:flutter/material.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidoCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();

  final List<String> _modulos = [
    'Gestión de usuario',
    'Proveedores',
    'Ventas',
    'Compras',
    'Finanzas',
    'Inventarios',
    'Distribución',
  ];
  final Map<String, bool> _modulosSeleccionados = {};

  String? _rolSeleccionado;
  final List<String> _roles = ['Administrador', 'Editor', 'Consulta'];

  @override
  void initState() {
    super.initState();
    for (var modulo in _modulos) {
      _modulosSeleccionados[modulo] = false;
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _nombreCtrl.clear();
    _apellidoCtrl.clear();
    _correoCtrl.clear();
    _passwordCtrl.clear();
    _areaCtrl.clear();
    setState(() {
      for (var key in _modulosSeleccionados.keys) {
        _modulosSeleccionados[key] = false;
      }
      _rolSeleccionado = null;
    });
  }

  void _crearUsuario() {
    if (_formKey.currentState?.validate() ?? false) {
      print('Usuario creado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Crear usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput('Nombre', _nombreCtrl),
              _buildInput('Apellido', _apellidoCtrl),
              _buildInput('Correo electrónico', _correoCtrl, isEmail: true),
              _buildInput('Nueva contraseña', _passwordCtrl, isPassword: true),
              _buildInput('Área', _areaCtrl),
              const SizedBox(height: 16),
              const Text('Módulos', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._modulos.map((modulo) => CheckboxListTile(
                    title: Text(modulo),
                    value: _modulosSeleccionados[modulo],
                    onChanged: (val) {
                      setState(() {
                        _modulosSeleccionados[modulo] = val ?? false;
                      });
                    },
                  )),
              const SizedBox(height: 16),
              const Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                hint: const Text('Seleccionar un rol'),
                items: _roles
                    .map((rol) => DropdownMenuItem(value: rol, child: Text(rol)))
                    .toList(),
                onChanged: (valor) {
                  setState(() => _rolSeleccionado = valor);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _limpiarFormulario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('LIMPIAR'),
                  ),
                  ElevatedButton(
                    onPressed: _crearUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('CREAR'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {bool isPassword = false, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if ((value ?? '').isEmpty) return 'Campo obligatorio';
          return null;
        },
      ),
    );
  }
}
