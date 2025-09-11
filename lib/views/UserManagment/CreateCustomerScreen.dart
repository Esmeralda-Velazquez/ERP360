import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/controllers/CustomerProvider.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _status = true;
  bool _submitting = false;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final ok = await context.read<CustomerProvider>().create({
      "firstName": _firstCtrl.text.trim(),
      "lastName":  _lastCtrl.text.trim(),
      "phoneNumber": _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      "email": _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      "status": _status
    });
    setState(() => _submitting = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente creado')));
      Navigator.pop(context, true);
    } else {
      final err = context.read<CustomerProvider>().error ?? 'No se pudo crear';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blueGrey.shade900;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cliente'), backgroundColor: primary),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstCtrl,
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
                              controller: _lastCtrl,
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
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null;
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(t)) return 'Correo inválido';
                          return null;
                        },
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
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_outlined),
                              label: Text(_submitting ? 'Guardando...' : 'Crear cliente'),
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
