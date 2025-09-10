import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/UsersProvider.dart';
import 'package:erpraf/models/usersManagment/roleOption.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> usuario; // viene de la lista
  const EditUserScreen({super.key, required this.usuario});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _areaCtrl;

  bool _status = true;
  int? _roleId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final fullName = (widget.usuario['nombre'] ?? '').toString() + ' ' + (widget.usuario['apellido'] ?? '').toString();
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : '';
    final last  = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    _firstNameCtrl = TextEditingController(text: first);
    _lastNameCtrl  = TextEditingController(text: last);
    _emailCtrl     = TextEditingController(text: (widget.usuario['email'] ?? '').toString());
    _areaCtrl      = TextEditingController(text: (widget.usuario['area'] ?? '').toString());
    _status        = true; // si quieres puedes pasarlo desde el map

    // cargar roles y preseleccionar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<UsersProvider>();
      await prov.fetchRoles();

      final currentRoleName = (widget.usuario['rol'] ?? '').toString().trim().toLowerCase();
      final match = prov.roles.firstWhere(
        (r) => r.name.toLowerCase() == currentRoleName,
        orElse: () => RoleOption(id: -1, name: ''),
      );
      if (match.id != -1) {
        setState(() => _roleId = match.id);
      }
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un rol')),
      );
      return;
    }

    final payload = {
      "firstName": _firstNameCtrl.text.trim(),
      "lastName":  _lastNameCtrl.text.trim(),
      "email":     _emailCtrl.text.trim(),
      "area":      _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
      "status":    _status,
      "roleId":    _roleId,
    };

    setState(() => _submitting = true);
    final id = int.parse(widget.usuario['id'].toString());
    final ok = await context.read<UsersProvider>().update(id, payload);
    setState(() => _submitting = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario actualizado')),
      );
      Navigator.pop(context, true);
    } else {
      final err = context.read<UsersProvider>().error ?? 'No se pudo actualizar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;
    final prov = context.watch<UsersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Editar usuario'), backgroundColor: primary),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text('Datos generales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Apellidos',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _areaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Área (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^\s'))],
                      ),
                      const SizedBox(height: 12),

                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security_outlined),
                        ),
                        child: prov.loadingRoles
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: _roleId,
                                decoration: const InputDecoration.collapsed(hintText: ''),
                                items: prov.roles
                                    .map((r) => DropdownMenuItem<int>(value: r.id, child: Text(r.name)))
                                    .toList(),
                                onChanged: (v) => setState(() => _roleId = v),
                                validator: (v) => v == null ? 'Selecciona un rol' : null,
                              ),
                      ),
                      if (prov.rolesError != null) ...[
                        const SizedBox(height: 8),
                        Text(prov.rolesError!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 12),

                      SwitchListTile(
                        title: const Text('Activo'),
                        value: _status,
                        onChanged: (v) => setState(() => _status = v),
                        secondary: const Icon(Icons.toggle_on_outlined),
                      ),

                      const SizedBox(height: 16),
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
                              onPressed: _submitting ? null : _guardar,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18, height: 18,
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
