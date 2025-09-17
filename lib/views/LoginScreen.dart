import 'package:erpraf/controllers/AuthProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:erpraf/views/HomeScreen.dart';
import 'package:erpraf/widgets/PasswordFile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erpraf/widgets/nice_dialogs.dart';
import 'package:erpraf/widgets/email_input.dart';
import 'package:erpraf/widgets/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(flex: 1, child: columnLeft()),
          Expanded(flex: 1, child: Center(child: columnRight(context))),
        ],
      ),
    );
  }

  Widget columnRight(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 100,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            const SizedBox(height: 30),
            EmailInput(
              controller: _emailController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (val) => debugPrint("Escribiendo: $val"),
            ),
            const SizedBox(height: 20),
            PasswordField(
              controller: _passwordController,
              showPolicyHelper: false,
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1E3A5F),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Inicia sesión',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                NiceDialogs.showInfo(
                  context,
                  title: 'Recuperar contraseña',
                  message:
                      'Funcionalidad en desarrollo.\nPor favor contacta al administrador.',
                  buttonText: 'Entendido',
                  icon: Icons.info,
                  accentColor: const Color.fromARGB(255, 60, 61, 135),
                );
              },
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
            const SizedBox(height: 20),
            const Text(
              '©2025 All Rights Reserved.\nERP System by DR',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget columnLeft() {
    return Container(
      color: const Color(0xFF17496B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "BIENVENIDO",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 45,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Gestión empresarial inteligente",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 350,
              child: Image.asset('assets/illustration.png'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnackBar.show(
        context,
        type: SnackType.info,
        message: "Revisa los campos en rojo",
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      AppSnackBar.show(
        context,
        type: SnackType.warning,
        title: "Atención",
        message: "La contraseña es requerida",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);
      await authService.login(email, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);

      AppSnackBar.show(
        context,
        type: SnackType.success,
        title: "¡Éxito!",
        message: "Inicio de sesión exitoso",
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      AppSnackBar.show(
        context,
        type: SnackType.error,
        title: "No se pudo iniciar sesión",
        message: e.message,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        type: SnackType.error,
        title: "Error",
        message: "Ocurrió un problema inesperado: $e",
      );
    }
  }
}
