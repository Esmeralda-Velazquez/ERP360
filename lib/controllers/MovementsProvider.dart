import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:erpraf/models/inventory/movement_item.dart';

class MovementsProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';

  bool _loading = false;
  String? _error;
  int _page = 1;
  int _pageSize = 50;
  int _total = 0;

  List<MovementItem> _items = [];
  double entradas = 0, salidas = 0, ajustes = 0, balance = 0;

  bool get loading => _loading;
  String? get error => _error;
  List<MovementItem> get items => _items;
  int get total => _total;
  int get page => _page;
  int get pageSize => _pageSize;

  Future<void> fetch({
    int? productId,
    String? type,
    DateTime? from,
    DateTime? to,
    int? userId,
    int page = 1,
    int pageSize = 50,
    String sort = 'desc',
  }) async {
    if (_loading) return;
    _loading = true; _error = null; notifyListeners();
    try {
      final qp = <String, String>{
        'page': '$page',
        'pageSize': '$pageSize',
        'sort': sort,
      };
      if (productId != null) qp['productId'] = '$productId';
      if (userId != null) qp['userId'] = '$userId';
      if (type != null && type.isNotEmpty) qp['type'] = type;
      if (from != null) qp['from'] = from.toIso8601String();
      if (to != null) qp['to'] = to.toIso8601String();

      final uri = Uri.parse('$_baseUrl/api/movements').replace(queryParameters: qp);
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _page = j['page'] ?? page;
        _pageSize = j['pageSize'] ?? pageSize;
        _total = j['total'] ?? 0;

        final totals = (j['totals'] as Map<String, dynamic>?);
        entradas = (totals?['entradas'] ?? 0).toDouble();
        salidas  = (totals?['salidas'] ?? 0).toDouble();
        ajustes  = (totals?['ajustes'] ?? 0).toDouble();
        balance  = (totals?['balance'] ?? 0).toDouble();

        _items = (j['data'] as List? ?? [])
            .map((e) => MovementItem.fromJson(e as Map<String, dynamic>))
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
  // controllers/movements_provider.dart
Future<bool> createMovement({
  required int productId,
  required String type,   // 'IN' | 'OUT' | 'ADJ'
  required String amount, // texto, ex: "10"
  DateTime? date,
  int? userId,            // opcional si todavía no hay JWT
}) async {
  final uri = Uri.parse('$_baseUrl/api/movements');
  try {
    final body = {
      "productId": productId,
      "type": type,
      "amount": amount,
      if (date != null) "date": date.toIso8601String(),
      if (userId != null) "userId": userId,
    };
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      // recargar lista con filtros actuales (si quieres conservarlos guárdalos en el provider)
      await fetch();
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
