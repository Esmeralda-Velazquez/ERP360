import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:erpraf/controllers/AuthProvider.dart';
import 'package:erpraf/views/LoginScreen.dart';
import 'package:erpraf/views/HomeScreen.dart';
import 'package:erpraf/controllers/SupplierProvider.dart';
import 'package:erpraf/controllers/UsersProvider.dart';
import 'package:erpraf/controllers/RolesProvider.dart';
import 'package:erpraf/controllers/CustomerProvider.dart';
import 'package:erpraf/controllers/InventoryProvider.dart';
import 'package:erpraf/controllers/MovementsProvider.dart';
import 'package:erpraf/controllers/SalesProvider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => RolesProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => MovementsProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
                ChangeNotifierProvider(
          create: (_) => AuthProvider()..loadSession(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ERP RAF',
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: const SessionChecker(),
    );
  }
}

class SessionChecker extends StatefulWidget {
  const SessionChecker({super.key});

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {
  late Widget _screen =
      const Scaffold(body: Center(child: CircularProgressIndicator()));

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    setState(() {
      _screen = isLoggedIn ? const HomeScreen() : const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _screen;
  }
}
