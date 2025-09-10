import 'Supplier.dart';

class SupplierListResponse {
  final bool ok;
  final int count;
  final List<Supplier> data;

  SupplierListResponse({required this.ok, required this.count, required this.data});

  factory SupplierListResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['data'] as List<dynamic>? ?? [])
        .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
        .toList();
    return SupplierListResponse(
      ok: j['ok'] as bool? ?? false,
      count: j['count'] as int? ?? list.length,
      data: list,
    );
  }
}
