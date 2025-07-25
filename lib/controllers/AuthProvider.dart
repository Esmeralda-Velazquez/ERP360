import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erpraf/models/LoginRequest.dart';

class AuthProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';
  String? _token;

  String? get token => _token;
  Future<void> login(String email, String password) async {

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode(LoginRequest(email: email, password: password).toJson()),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        _token = json['token'];
        final token = json['token'];
        if (token != null) {
          _token = token;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          notifyListeners();
        } else {
          throw Exception('Token no recibido del servidor');
        }
      } else {
        throw Exception(json['message'] ?? 'Error en autenticación');
      }
    } catch (e) {
      throw Exception('Error de conexión o inesperado: $e');
    }
  }
}
