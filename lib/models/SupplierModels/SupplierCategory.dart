class SupplierCategory {
  final int id;
  final String name;

  SupplierCategory({required this.id, required this.name});

  factory SupplierCategory.fromJson(Map<String, dynamic> j) => SupplierCategory(
        id: j['categorySupplierId'] as int,
        name: j['categoryName'] as String? ?? '',
      );
}
