import 'dart:async';
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

  /// ----- Vistas derivadas: Activos / Inactivos -----
  List<UserListItem> get activeItems => _items.where(_isActive).toList();
  List<UserListItem> get inactiveItems => _items.where((u) => !_isActive(u)).toList();

  bool _isActive(UserListItem u) {
    // Compatibilidad: status string o bool
    // Compatibilidad: status string o bool
    if (u.status is String) {
      final status = (u.status as String).toLowerCase().trim();
      if (status.isNotEmpty) {
        return status == 'activo' || status == 'active' || status == '1';
      }
    } else    return u.status == true;
  
    // fallback (por si no trae nada): considéralos activos
    return true;
  }

  /// ----- Carga de usuarios -----
  Future<void> fetchAll({String? q, int page = 1, int pageSize = 50}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/users').replace(queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      });

      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _items = (json['data'] as List<dynamic>? ?? [])
            .map((e) => UserListItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
      }
    } on TimeoutException {
      _error = 'Tiempo de espera agotado al cargar usuarios.';
    } catch (e) {
      _error = 'Error de conexión: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ----- Carga de roles -----
  Future<void> fetchRoles() async {
    if (_loadingRoles) return;
    _loadingRoles = true;
    _rolesError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/roles/options');
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _roles = (json['data'] as List<dynamic>? ?? [])
            .map((e) => RoleOption.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _rolesError = 'Error ${res.statusCode}: ${res.body}';
      }
    } on TimeoutException {
      _rolesError = 'Tiempo de espera agotado al cargar roles.';
    } catch (e) {
      _rolesError = 'Error de conexión: $e';
    } finally {
      _loadingRoles = false;
      notifyListeners();
    }
  }

  /// ----- Actualizar usuario -----
  Future<bool> update(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/users/$id');
    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(data),
      );

      if (res.statusCode == 200) {
        // Refresca lista para mantener consistencia
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

  /// ----- Eliminar usuario (o baja lógica si tu API así lo maneja) -----
  Future<bool> deleteById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/users/$id');
    try {
      final res = await http.delete(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
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

  /// ----- Crear usuario -----
  Future<bool> create(Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/users');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(data),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
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

  /// ----- Activar usuario (para moverlo a la lista de activos) -----
  ///
  /// Intenta varias convenciones comunes de API. Ajusta la que aplique y
  /// elimina el resto si quieres.
  Future<bool> activateById(int id) async {
    // 1) POST /api/users/{id}/activate
    final uriActivatePost = Uri.parse('$_baseUrl/api/users/$id/activate');

    try {
      var res = await http.post(
        uriActivatePost,
        headers: {'Accept': 'application/json'},
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        _setActiveLocal(id, true);
        return true;
      }

      // 2) PATCH /api/users/{id} body: {"isActive": true}
      final uriPatch = Uri.parse('$_baseUrl/api/users/$id');
      res = await http.patch(
        uriPatch,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'isActive': true, 'status': 'activo'}),
      );

      if (res.statusCode == 200) {
        _setActiveLocal(id, true);
        return true;
      }

      // 3) PUT /api/users/{id}/status  body: {"status":"activo"}
      final uriStatus = Uri.parse('$_baseUrl/api/users/$id/status');
      res = await http.put(
        uriStatus,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'status': 'activo'}),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        _setActiveLocal(id, true);
        return true;
      }

      _error = 'No se pudo activar (HTTP ${res.statusCode}): ${res.body}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return false;
    }
  }

  /// (Opcional) Desactivar usuario para mandarlo a la lista de inactivos
  Future<bool> deactivateById(int id) async {
    // Si tu flujo de "eliminar" realmente es baja lógica, puedes usar esto;
    // si no lo necesitas, bórralo.
    final uriDeactivatePost = Uri.parse('$_baseUrl/api/users/$id/deactivate');

    try {
      var res = await http.post(
        uriDeactivatePost,
        headers: {'Accept': 'application/json'},
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        _setActiveLocal(id, false);
        return true;
      }

      // PATCH /api/users/{id} body: {"isActive": false}
      final uriPatch = Uri.parse('$_baseUrl/api/users/$id');
      res = await http.patch(
        uriPatch,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'isActive': false, 'status': 'inactivo'}),
      );

      if (res.statusCode == 200) {
        _setActiveLocal(id, false);
        return true;
      }

      // PUT /api/users/{id}/status {"status":"inactivo"}
      final uriStatus = Uri.parse('$_baseUrl/api/users/$id/status');
      res = await http.put(
        uriStatus,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'status': 'inactivo'}),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        _setActiveLocal(id, false);
        return true;
      }

      _error = 'No se pudo desactivar (HTTP ${res.statusCode}): ${res.body}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return false;
    }
  }

  void _setActiveLocal(int id, bool active) {
    final i = _items.indexWhere((u) => u.userId == id);
    if (i == -1) return;

    final original = _items[i];

    final patched = original.copyWith(
      status: active ? true : false,
    );

    _items[i] = patched;
    notifyListeners();
  }
}
