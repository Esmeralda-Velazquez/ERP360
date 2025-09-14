import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/UsersProvider.dart';
import 'package:erpraf/widgets/app_snackbar.dart';
import 'package:erpraf/widgets/email_input.dart';
import 'package:erpraf/widgets/app_dropdown.dart';
import 'package:erpraf/widgets/PasswordFile.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _status = true;
  int? _roleId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchRoles();
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _areaCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnackBar.show(
        context,
        type: SnackType.info,
        message: "Revisa los campos en rojo",
      );
      return;
    }

    if (_roleId == null) {
      AppSnackBar.show(
        context,
        type: SnackType.warning,
        title: "Atención",
        message: "Selecciona un rol",
      );
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      AppSnackBar.show(
        context,
        type: SnackType.warning,
        title: "Atención",
        message: "Las contraseñas no coinciden",
      );
      return;
    }

    final payload = {
      "firstName": _firstNameCtrl.text.trim(),
      "lastName": _lastNameCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "area": _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
      "status": _status,
      "roleId": _roleId,
      "password": _passwordCtrl.text,
    };

    setState(() => _submitting = true);
    final ok = await context.read<UsersProvider>().create(payload);
    setState(() => _submitting = false);

    if (!mounted) return;
    if (ok) {
      AppSnackBar.show(
        context,
        type: SnackType.success,
        title: "¡Éxito!",
        message: "Usuario creado",
      );
      Navigator.pop(context, true);
    } else {
      final err =
          context.read<UsersProvider>().error ?? 'No se pudo crear el usuario';
      AppSnackBar.show(
        context,
        type: SnackType.error,
        title: "Algo salió mal contacta al administrador",
        message: err,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;
    final prov = context.watch<UsersProvider>();

    return Scaffold(
      appBar:
          AppBar(title: const Text('Crear usuario'), backgroundColor: primary),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text('Datos generales',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
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
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EmailInput(
                        controller: _emailCtrl,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: (val) => debugPrint("Escribiendo: $val"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _areaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Área (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'^\s'))
                        ],
                      ),
                      const SizedBox(height: 12),
                      prov.loadingRoles
                          ? const LinearProgressIndicator()
                          : AppDropdown<int>(
                              items: prov.roles.map((r) => r.id).toList(),
                              itemLabel: (id) =>
                                  prov.roles.firstWhere((r) => r.id == id).name,
                              value: _roleId,
                              labelText: 'Rol',
                              hintText: 'Selecciona un rol',
                              prefixIcon: Icons.security_outlined,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (v) =>
                                  v == null ? 'Selecciona un rol' : null,
                              onChanged: (v) => setState(() => _roleId = v),
                            ),
                      if (prov.rolesError != null) ...[
                        const SizedBox(height: 8),
                        Text(prov.rolesError!,
                            style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 12),
                      const Text('Seguridad',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      PasswordField(
                        controller: _passwordCtrl,
                        minLength: 14,
                        requireSpecial: true,
                        requireUpper: true,
                        requireLower: true,
                        requireDigit: true,
                      ),
                      const SizedBox(height: 12),
                      PasswordField(
                        controller: _confirmCtrl,
                        showPolicyHelper: false,
                      ),

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
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.pop(context, false),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _submitting ? null : _guardar,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_submitting
                                  ? 'Guardando...'
                                  : 'Crear usuario'),
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
