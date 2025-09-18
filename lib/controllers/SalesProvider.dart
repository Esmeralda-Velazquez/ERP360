import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:erpraf/models/sales/sale_models.dart';
import 'package:erpraf/models/sales/sale_detail.dart';


class SalesProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5001';

  bool _loading = false;
  String? _error;
  List<SaleSummary> _items = [];
  int _total = 0;

  bool get loading => _loading;
  String? get error => _error;
  List<SaleSummary> get items => _items;
  int get total => _total;

  Future<void> fetchAll({
    String? q,
    int? customerId,
    int? userId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 50,
    bool includeCancelled = false,
  }) async {
    if (_loading) return;
    _loading = true; _error = null; notifyListeners();
    try {
      final qp = <String, String>{
        'page': '$page',
        'pageSize': '$pageSize',
        if (includeCancelled) 'includeCancelled': 'true',
      };
      if (q != null && q.trim().isNotEmpty) qp['q'] = q.trim();
      if (customerId != null) qp['customerId'] = '$customerId';
      if (userId != null) qp['userId'] = '$userId';
      if (from != null) qp['from'] = from.toIso8601String();
      if (to != null) qp['to'] = to.toIso8601String();

      final uri = Uri.parse('$_baseUrl/api/sales').replace(queryParameters: qp);
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _total = j['total'] ?? 0;
        final list = (j['data'] as List? ?? [])
            .map((e) => SaleSummary.fromJson(e as Map<String, dynamic>))
            .toList();
        _items = list;
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<(bool ok, int? id)> create(CreateSaleRequest req) async {
    final uri = Uri.parse('$_baseUrl/api/sales');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        return (true, j['id'] as int?);
      } else {
        _error = 'Error ${res.statusCode}: ${res.body}';
        notifyListeners();
        return (false, null);
      }
    } catch (e) {
      _error = 'Error conexión: $e';
      notifyListeners();
      return (false, null);
    }
  }

  Future<bool> cancel(int id) async {
    final uri = Uri.parse('$_baseUrl/api/sales/$id/cancel');
    try {
      final res = await http.patch(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        _items.removeWhere((s) => s.saleId == id);
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
  Future<(bool ok, SaleDetail? data)> fetchById(int id) async {
  final uri = Uri.parse('$_baseUrl/api/sales/details/$id');
  try {
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      print(  "Respuesta JSON: $j"); 
      final map = (j['data'] ?? j) as Map<String, dynamic>;
      final detail = SaleDetail.fromJson(map);
      

      return (true, detail);
    } else {
      _error = 'Error ${res.statusCode}: ${res.body}';
      notifyListeners();
      return (false, null);
    }
  } catch (e) {
    _error = 'Error conexión: $e';
    notifyListeners();
    return (false, null);
  }
  }
    Future<bool> emailReceipt(int saleId, {required String toEmail}) async {
    final uri = Uri.parse('$_baseUrl/api/sales/$saleId/email');
    try {
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'toEmail': toEmail}),
      );

      Map<String, dynamic>? j;
      try {
        j = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {
        j = null;
      }

      final isOkJson = (j?['ok'] == true) || (j?['success'] == true);

      if (res.statusCode == 200 && (isOkJson || j != null)) {
        return true;
      } else {
        _error = j?['message'] ??
            'Error ${res.statusCode}: ${res.body.isEmpty ? 'sin contenido' : res.body}';
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
