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

  // ========= LISTA DE ROLES =========
  Future<void> fetchAll({String? q}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final qp = <String, String>{'includeInactive': 'true'};
      if (q != null && q.trim().isNotEmpty) qp['q'] = q.trim();

      final uri = Uri.parse('$_baseUrl/api/roles').replace(queryParameters: qp);
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
      _loading = false;
      notifyListeners();
    }
  }

  // ========= PERMISOS =========
  Future<void> fetchPermissions() async {
    if (_loadingPerms) return;
    _loadingPerms = true;
    _permsError = null;
    notifyListeners();
    try {
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
      _loadingPerms = false;
      notifyListeners();
    }
  }

  // ========= CREAR / ACTUALIZAR =========
  Future<bool> createRole({
    required String name,
    required bool status,
    required List<int> permissionIds,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/roles');
    final body = jsonEncode({
      "roleName": name.trim(),
      "status": status,
      "permissionIds": permissionIds,
    });
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
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

  Future<bool> updateRole({
    required int id,
    required String name,
    required bool status,
    required List<int> permissionIds,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/roles/$id');
    final body = jsonEncode({
      "roleName": name.trim(),
      "status": status,
      "permissionIds": permissionIds,
    });
    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
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

  // ========= ELIMINAR (con manejo de 409) =========
  Future<DeleteResult> deleteById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/roles/$id');
    try {
      final res =
          await http.delete(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        // Éxito: quitamos de la lista local
        _items.removeWhere((r) => r.id == id);
        notifyListeners();
        return DeleteResult(success: true);
      }

      // Conflicto: intentar parsear el payload enriquecido
      if (res.statusCode == 409) {
        try {
          final Map<String, dynamic> j = jsonDecode(res.body);
          final code = (j['code'] ?? '').toString();
          final msg = j['message']?.toString();
          final userCountRaw = j['userCount'];
          final userCount =
              userCountRaw is int ? userCountRaw : int.tryParse('$userCountRaw') ?? 0;

          if (code == 'ROLE_IN_USE') {
            return DeleteResult(
              success: false,
              conflict: true,
              message: msg ?? 'Rol en uso',
              userCount: userCount,
            );
          }
          return DeleteResult(success: false, message: msg ?? 'Conflicto');
        } catch (_) {
          // Si no se puede parsear, devuelve error genérico
          return DeleteResult(
            success: false,
            message: 'Conflicto ${res.statusCode}: ${res.body}',
          );
        }
      }

      // Otros códigos
      return DeleteResult(
        success: false,
        message: 'Error ${res.statusCode}: ${res.body}',
      );
    } catch (e) {
      return DeleteResult(success: false, message: 'Error conexión: $e');
    }
  }

  // ========= REASIGNAR Y ELIMINAR =========
  Future<bool> reassignAndDelete({
    required int oldRoleId,
    required int newRoleId,
    bool deleteOld = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/roles/$oldRoleId/reassign');
    final body = jsonEncode({
      "newRoleId": newRoleId,
      "deleteOld": deleteOld,
      // "softDeleteIfNotDeleteOld": true, // si lo quieres configurable
    });

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        // Refrescamos lista (puede haber desaparecido el rol viejo)
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

  // ========= ALTERNATIVAS (roles destino) =========
  Future<List<RoleOption>> fetchAlternatives(int excludeId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/roles/options')
          .replace(queryParameters: {'includeInactive': 'false'});

      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final Map<String, dynamic> j = jsonDecode(res.body);
        final list = (j['data'] as List<dynamic>? ?? [])
            .map((e) => RoleOption.fromJson(e as Map<String, dynamic>))
            .where((r) => r.id != excludeId)
            .toList();
        return list;
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return [];
    }
  }
}

// =========================
// Tipos auxiliares locales
// =========================

class DeleteResult {
  final bool success;
  final bool conflict;
  final int? userCount;
  final String? message;

  DeleteResult({
    required this.success,
    this.conflict = false,
    this.userCount,
    this.message,
  });
}

class RoleOption {
  final int id;
  final String name;

  RoleOption({required this.id, required this.name});

  factory RoleOption.fromJson(Map<String, dynamic> j) {
    // API: { roleId, roleName }
    final rid = j['roleId'] ?? j['RoleId'];
    final rname = j['roleName'] ?? j['RoleName'];

    return RoleOption(
      id: rid is int ? rid : int.tryParse('$rid') ?? 0,
      name: (rname ?? '').toString(),
    );
  }
}
