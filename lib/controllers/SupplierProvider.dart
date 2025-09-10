import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:erpraf/models/SupplierModels/Supplier_List_Response.dart';
import 'package:erpraf/models/SupplierModels/Supplier.dart';
import 'package:erpraf/models/SupplierModels/SupplierCategory.dart';

class SupplierProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';

  List<Supplier> _items = [];
  bool _loading = false;
  String? _error;

  List<Supplier> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  // === Categorías ===
  List<SupplierCategory> _categories = [];
  bool _loadingCat = false;
  String? _errorCat;

  List<SupplierCategory> get categories => _categories;
  bool get loadingCategories => _loadingCat;
  String? get categoriesError => _errorCat;

  Future<void> fetchAll() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/suppliers');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final parsed = SupplierListResponse.fromJson(json);
        _items = parsed.data;
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

  Future<void> fetchCategories() async {
    if (_loadingCat) return;
    _loadingCat = true;
    _errorCat = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/categories');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (json['data'] as List<dynamic>? ?? [])
            .map((e) => SupplierCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        _categories = list;
      } else {
        _errorCat = 'Error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      _errorCat = 'Error de conexión: $e';
    } finally {
      _loadingCat = false;
      notifyListeners();
    }
  }

  // === POST crear ===
  Future<bool> create(Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/suppliers');
    try {
      final res = await http.post(
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

  // === DELETE ===
  Future<bool> deleteById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/suppliers/$id');
    try {
      final res = await http.delete(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        _items.removeWhere((s) => s.supplierId == id);
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
  Future<bool> update(int id, Map<String, dynamic> data) async {
  final uri = Uri.parse('$_baseUrl/api/suppliers/$id');
  try {
    final res = await http.put(
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
