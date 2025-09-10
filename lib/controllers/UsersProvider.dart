import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:erpraf/models/usersManagment/user_list_item.dart';
import 'package:erpraf/models/usersManagment/roleOption.dart';

class UsersProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';

  bool _loading = false;
  String? _error;
  List<UserListItem> _items = [];

  // Roles
  bool _loadingRoles = false;
  String? _rolesError;
  List<RoleOption> _roles = [];

  bool get loading => _loading;
  String? get error => _error;
  List<UserListItem> get items => _items;

  bool get loadingRoles => _loadingRoles;
  String? get rolesError => _rolesError;
  List<RoleOption> get roles => _roles;

  Future<void> fetchAll({String? q, int page = 1, int pageSize = 50}) async {
    if (_loading) return;
    _loading = true; _error = null; notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/api/users').replace(queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      });
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _items = (json['data'] as List<dynamic>? ?? [])
            .map((e) => UserListItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> fetchRoles() async {
    if (_loadingRoles) return;
    _loadingRoles = true; _rolesError = null; notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/api/roles/options');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _roles = (json['data'] as List<dynamic>? ?? [])
            .map((e) => RoleOption.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _rolesError = 'Error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      _rolesError = 'Error de conexión: $e';
    } finally {
      _loadingRoles = false; notifyListeners();
    }
  }

  Future<bool> update(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/users/$id');
    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        await fetchAll();
        return true;
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/users/$id');
    try {
      final res = await http.delete(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        _items.removeWhere((u) => u.userId == id);
        notifyListeners();
        return true;
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return false;
    }
  }
  Future<bool> create(Map<String, dynamic> data) async {
  final uri = Uri.parse('$_baseUrl/api/users');
  try {
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      await fetchAll(); // refresca la lista
      return true;
    } else {
      _error = 'Error ${res.statusCode}: ${res.body}';
      notifyListeners();
      return false;
    }
  } catch (e) {
    _error = 'Error conexión: $e';
    notifyListeners();
    return false;
  }
}

}
