import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:erpraf/models/CustomerModels/customer_list_item.dart';
import 'package:erpraf/models/CustomerModels/customer_option.dart';

class CustomerProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';

  // Estados de carga separados
  bool _loadingList = false;
  bool _loadingOptions = false;

  String? _error;

  // Datos
  List<CustomerListItem> _items = [];
  List<CustomerOption> _options = [];

  // Getters públicos
  bool get loading => _loadingList;
  bool get optionsLoading => _loadingOptions;
  String? get error => _error;

  List<CustomerListItem> get items => _items;
  List<CustomerOption> get options => _options;

  // === Traer todos los clientes (lista principal) ===
  Future<void> fetchAll({String? q}) async {
    if (_loadingList) return;
    _loadingList = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/customers').replace(
        queryParameters: {
          if ((q ?? '').trim().isNotEmpty) 'q': q!.trim(),
        },
      );

      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _items = (json['data'] as List<dynamic>? ?? [])
            .map((e) => CustomerListItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
    } finally {
      _loadingList = false;
      notifyListeners();
    }
  }

  // === Crear cliente ===
  Future<bool> create(Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/customers');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        await fetchAll();
        return true;
      }
      _error = 'Error ${res.statusCode}: ${res.body}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return false;
    }
  }

  // === Actualizar cliente ===
  Future<bool> update(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/customers/$id');
    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        await fetchAll();
        return true;
      }
      _error = 'Error ${res.statusCode}: ${res.body}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return false;
    }
  }

  // === Eliminar cliente ===
  Future<bool> deleteById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/customers/$id');
    try {
      final res = await http.delete(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        _items.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
      _error = 'Error ${res.statusCode}: ${res.body}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return false;
    }
  }

  // === Traer opciones (combo/dropdown) ===
  Future<void> fetchOptions({String? q}) async {
    if (_loadingOptions) return;
    _loadingOptions = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/api/customers/options').replace(
        queryParameters: (q != null && q.trim().isNotEmpty)
            ? {'q': q.trim()}
            : null,
      );

      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _options = (j['data'] as List? ?? [])
            .map((e) => CustomerOption.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      _error = 'Error conexión: $e';
    } finally {
      _loadingOptions = false;
      notifyListeners();
    }
  }
}
