import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  bool get isLoggedIn => _token != null && _userId != null;

  // Helpers
  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  T? _pick<T>(Map<String, dynamic>? j, List<List<String>> paths) {
    if (j == null) return null;
    for (final path in paths) {
      dynamic cur = j;
      for (final key in path) {
        if (cur is Map<String, dynamic> && cur.containsKey(key)) {
          cur = cur[key];
        } else {
          cur = null;
          break;
        }
      }
      if (cur is T) return cur as T;
    }
    return null;
  }

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

      Map<String, dynamic>? json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        json = null;
      }

      final ok = (json?['success'] == true) || (json?['ok'] == true);

      if (response.statusCode == 200 && ok) {
        // token puede venir en: token, data.token, result.token
        final tok = _pick<String>(json, [
          ['token'],
          ['data', 'token'],
          ['result', 'token'],
        ]);

        // userId puede venir en: userId, data.userId, user.id
        final rawUserId = _pick<dynamic>(json, [
          ['userId'],
          ['data', 'userId'],
          ['user', 'id'],
          ['result', 'userId'],
        ]);
        final uid = _asInt(rawUserId);

        if (tok == null || uid == null) {
          throw AuthException('Respuesta de login incompleta (token/usuario).');
        }

        _token = tok;
        _userId = uid;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setInt('userId', _userId!);

        notifyListeners();
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException(json?['message'] ?? 'Usuario o contraseña incorrectos');
      }

      throw AuthException(
        json?['message'] ?? 'Error del servidor (${response.statusCode}). Inténtalo de nuevo.',
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    _token = null;
    _userId = null;
    notifyListeners();
  }
}
