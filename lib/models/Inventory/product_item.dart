class ProductItem {
  final int id;
  final String name;
  final String? category;
  final String? brand;
  final String? size;
  final String? color;
  final String? price;   // viene como string del backend
  final double stock;    // enteros en DB; double aquí para mostrar y formatear
  final double stockMin; // idem
  final bool status;

  // Atajo opcional para legibilidad
  bool get isActive => status;

  const ProductItem({
    required this.id,
    required this.name,
    this.category,
    this.brand,
    this.size,
    this.color,
    this.price,
    required this.stock,
    required this.stockMin,
    this.status = true,
  });

  factory ProductItem.fromJson(Map<String, dynamic> j) => ProductItem(
        id: j['id'] as int,
        name: (j['name'] as String?) ?? '',
        category: j['category'] as String?,
        brand: j['brand'] as String?,
        size: j['size'] as String?,
        color: j['color'] as String?,
        price: j['price'] as String?,
        stock: (j['stock'] is num)
            ? (j['stock'] as num).toDouble()
            : double.tryParse('${j['stock']}') ?? 0.0,
        stockMin: (j['stockMin'] is num)
            ? (j['stockMin'] as num).toDouble()
            : double.tryParse('${j['stockMin']}') ?? 0.0,
        status: _parseBoolFlexible(j['status']),
      );

  static bool _parseBoolFlexible(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = (v?.toString().trim().toLowerCase()) ?? '';
    if (s.isEmpty) return true; // default true si no viene
    return s == 'true' || s == '1' || s == 'yes' || s == 'y';
  }

  ProductItem copyWith({
    int? id,
    String? name,
    String? category,
    String? brand,
    String? size,
    String? color,
    String? price,
    double? stock,
    double? stockMin,
    bool? status,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      color: color ?? this.color,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      stockMin: stockMin ?? this.stockMin,
      status: status ?? this.status,
    );
  }
}
