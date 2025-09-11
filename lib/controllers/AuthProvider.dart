import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erpraf/models/LoginRequest.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';
  String? _token;
  int? _userId;

  String? get token => _token;
  int? get userId => _userId;

  Future<void> login(String email, String password) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/users/login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(LoginRequest(email: email, password: password).toJson()),
          )
          .timeout(const Duration(seconds: 12));

      // Intenta parsear JSON con seguridad
      Map<String, dynamic>? json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        json = null;
      }

      if (response.statusCode == 200 && (json?['success'] == true)) {
        _token = json?['token'];
        _userId = json?['userId'];

        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString('token', _token!);
        if (_userId != null) await prefs.setInt('userId', _userId!);

        notifyListeners();
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException(json?['message'] ?? 'Usuario o contraseña incorrectos');
      }

      throw AuthException(
        json?['message'] ??
            'Error del servidor (${response.statusCode}). Inténtalo de nuevo.',
      );
    } on SocketException {
      throw AuthException('Sin conexión a Internet. Verifica tu red.');
    } on HttpException {
      throw AuthException('Error de comunicación con el servidor.');
    } on FormatException {
      throw AuthException('Respuesta inválida del servidor.');
    } on TimeoutException {
      throw AuthException('Tiempo de espera agotado. Inténtalo más tarde.');
    } catch (e) {
      throw AuthException('Error inesperado: $e');
    }
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getInt('userId');
    notifyListeners();
  }
}
