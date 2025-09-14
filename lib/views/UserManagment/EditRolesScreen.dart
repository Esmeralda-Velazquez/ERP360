import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/RolesProvider.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

class EditRolesScreen extends StatefulWidget {
  final Map<String, dynamic> roles; // {id, nombreRol, status, permisos}
  const EditRolesScreen({super.key, required this.roles});

  @override
  State<EditRolesScreen> createState() => _EditRolesScreenState();
}

class _EditRolesScreenState extends State<EditRolesScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _status = true;
  final Set<int> _selectedPerms = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: (widget.roles['nombreRol'] ?? '').toString());
    _status = (widget.roles['status'] == true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<RolesProvider>();
      await prov.fetchPermissions();

      final List<String> currentNames =
          (widget.roles['permisos'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();
      final ids = prov.permissions
          .where((p) =>
              currentNames.any((n) => n.toLowerCase() == p.name.toLowerCase()))
          .map((p) => p.id);
      setState(() => _selectedPerms.addAll(ids));
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await context.read<RolesProvider>().updateRole(
          id: int.parse(widget.roles['id'].toString()),
          name: _nameCtrl.text.trim(),
          status: _status,
          permissionIds: _selectedPerms.toList(),
        );
    setState(() => _submitting = false);

    if (!mounted) return;
    if (ok) {
      AppSnackBar.show(
        context,
        type: SnackType.success,
        title: 'Exito',
        message: 'Rol actualizado',
      );
      Navigator.pop(context, true);
    } else {
      final err =
          context.read<RolesProvider>().error ?? 'No se pudo actualizar el rol';
      AppSnackBar.show(
        context,
        type: SnackType.error,
        title: 'Error',
        message: err,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RolesProvider>();
    final perms = prov.permissions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar rol'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del rol',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      /*
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Activo'),
                        value: _status,
                        onChanged: (v) => setState(() => _status = v),
                        secondary: const Icon(Icons.toggle_on_outlined),
                      ),
                      const SizedBox(height: 12),
*/
                      const Text('Permisos',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (prov.loadingPerms) const LinearProgressIndicator(),
                      if (prov.permsError != null)
                        Text(prov.permsError!,
                            style: const TextStyle(color: Colors.red)),
                      if (!prov.loadingPerms)
                        ...perms.map((p) => CheckboxListTile(
                              value: _selectedPerms.contains(p.id),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedPerms.add(p.id);
                                  } else {
                                    _selectedPerms.remove(p.id);
                                  }
                                });
                              },
                              title: Text(p.name),
                              controlAffinity: ListTileControlAffinity.leading,
                            )),
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
                                backgroundColor: Colors.blueGrey.shade900,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _submitting ? null : _guardar,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_outlined),
                              label: Text(_submitting
                                  ? 'Guardando...'
                                  : 'Guardar cambios'),
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
