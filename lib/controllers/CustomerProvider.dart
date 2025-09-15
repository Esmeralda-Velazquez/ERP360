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

  // Conveniencia para segmentar en UI
  List<CustomerListItem> get activeItems =>
      _items.where((c) => c.status == true).toList();

  List<CustomerListItem> get inactiveItems =>
      _items.where((c) => c.status == false).toList();

  // === Traer todos los clientes (lista principal) ===
  // Por default traemos activos + inactivos para poder segmentar en la vista
  Future<void> fetchAll({String? q, bool includeInactive = true}) async {
    if (_loadingList) return;
    _loadingList = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'includeInactive': includeInactive.toString(),
        if ((q ?? '').trim().isNotEmpty) 'q': q!.trim(),
      };

      final uri = Uri.parse('$_baseUrl/api/customers').replace(
        queryParameters: params,
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

  // === Activar cliente ===
  Future<bool> activateById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/customers/$id/activate');
    try {
      final res = await http.put(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        // Actualizamos la lista en memoria sin otra llamada si quieres ser optimista:
        final idx = _items.indexWhere((c) => c.id == id);
        if (idx != -1) {
          final current = _items[idx];
          _items[idx] = CustomerListItem(
            id: current.id,
            fullName: current.fullName,
            phone: current.phone,
            email: current.email,
            status: true,
            createdAt: current.createdAt,
          );
          notifyListeners();
        } else {
          // Si no está en memoria, recargamos
          await fetchAll();
        }
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

  // === (Opcional) Desactivar cliente ===
  Future<bool> deactivateById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/customers/$id/deactivate');
    try {
      final res = await http.put(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final idx = _items.indexWhere((c) => c.id == id);
        if (idx != -1) {
          final current = _items[idx];
          _items[idx] = CustomerListItem(
            id: current.id,
            fullName: current.fullName,
            phone: current.phone,
            email: current.email,
            status: false,
            createdAt: current.createdAt,
          );
          notifyListeners();
        } else {
          await fetchAll();
        }
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
        queryParameters:
            (q != null && q.trim().isNotEmpty) ? {'q': q.trim()} : null,
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
