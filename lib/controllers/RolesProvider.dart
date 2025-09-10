import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:erpraf/models/usersManagment/role_list_item.dart';
import 'package:erpraf/models/usersManagment/permission_option.dart';

class RolesProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';

  bool _loading = false;
  String? _error;
  List<RoleListItem> _items = [];

  // Permisos (para checklist)
  bool _loadingPerms = false;
  String? _permsError;
  List<PermissionOption> _perms = [];

  bool get loading => _loading;
  String? get error => _error;
  List<RoleListItem> get items => _items;

  bool get loadingPerms => _loadingPerms;
  String? get permsError => _permsError;
  List<PermissionOption> get permissions => _perms;

  Future<void> fetchAll({String? q}) async {
    if (_loading) return;
    _loading = true; _error = null; notifyListeners();
    try {
      final uri = Uri.parse('$_baseUrl/api/roles')
          .replace(queryParameters: { if (q != null && q.trim().isNotEmpty) 'q': q.trim(), 'includeInactive': 'true' });
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _items = (json['data'] as List<dynamic>? ?? [])
            .map((e) => RoleListItem.fromJson(e as Map<String, dynamic>))
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

  Future<void> fetchPermissions() async {
    if (_loadingPerms) return;
    _loadingPerms = true; _permsError = null; notifyListeners();
    try {
      // endpoint simple para listar permisos (crea si no existe): GET /api/permissions
      final uri = Uri.parse('$_baseUrl/api/permissions');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _perms = (json['data'] as List<dynamic>? ?? [])
            .map((e) => PermissionOption.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _permsError = 'Error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      _permsError = 'Error de conexión: $e';
    } finally {
      _loadingPerms = false; notifyListeners();
    }
  }

  Future<bool> createRole({
    required String name,
    required bool status,
    required List<int> permissionIds,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/roles');
    final body = jsonEncode({
      "roleName": name,
      "status": status,
      "permissionIds": permissionIds,
    });
    try {
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
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

  Future<bool> updateRole({
    required int id,
    required String name,
    required bool status,
    required List<int> permissionIds,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/roles/$id');
    final body = jsonEncode({
      "roleName": name,
      "status": status,
      "permissionIds": permissionIds,
    });
    try {
      final res = await http.put(uri, headers: {'Content-Type': 'application/json'}, body: body);
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
    final uri = Uri.parse('$_baseUrl/api/roles/$id');
    try {
      final res = await http.delete(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        _items.removeWhere((r) => r.id == id);
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
}
