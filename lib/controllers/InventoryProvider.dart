import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:erpraf/models/inventory/product_item.dart';

class InventoryProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';

  bool _loading = false;
  String? _error;
  List<ProductItem> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  List<ProductItem> get items => _items;

  // Future<void> fetchAll({String? q}) async {
  //   if (_loading) return;
  //   _loading = true; _error = null; notifyListeners();
  //   try {
  //     final uri = Uri.parse('$_baseUrl/api/products')
  //         .replace(queryParameters: { if (q != null && q.trim().isNotEmpty) 'q': q.trim() });
  //     final res = await http.get(uri, headers: {'Accept': 'application/json'});
  //     if (res.statusCode == 200) {
  //       final json = jsonDecode(res.body) as Map<String, dynamic>;
  //       _items = (json['data'] as List<dynamic>? ?? [])
  //           .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
  //           .toList();
  //     } else {
  //       _error = 'Error ${res.statusCode}: ${res.body}';
  //     }
  //   } catch (e) {
  //     _error = 'Error de conexión: $e';
  //   } finally {
  //     _loading = false; notifyListeners();
  //   }
  // }

  // inventory_provider.dart (añade o ajusta)

  Future<void> fetchAll({String? q, bool includeInactive = false}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
      if (includeInactive) params['includeInactive'] = 'true';

      final uri =
          Uri.parse('$_baseUrl/api/products').replace(queryParameters: params);
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _items = (json['data'] as List<dynamic>? ?? [])
            .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
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

// Soft delete (desactivar)
  Future<bool> deactivate(int id) async {
    final uri = Uri.parse('$_baseUrl/api/products/$id/deactivate');
    try {
      final res =
          await http.patch(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        // quítalo de la lista actual de activos
        _items.removeWhere((p) => p.id == id);
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

// (opcional) reactivar
  Future<bool> activate(int id) async {
    final uri = Uri.parse('$_baseUrl/api/products/$id/activate');
    try {
      final res =
          await http.patch(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        await fetchAll(includeInactive: false);
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

  Future<bool> update(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/products/$id');
    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        // refrescamos lista para ver cambios
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
    final uri = Uri.parse('$_baseUrl/api/products/$id');
    try {
      final res =
          await http.delete(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        _items.removeWhere((p) => p.id == id);
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
    final uri = Uri.parse('$_baseUrl/api/products');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        // refresca para que aparezca el nuevo
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
}
