class ProductItem {
  final int id;
  final String name;
  final String? category;
  final String? brand;
  final String? size;
  final String? color;
  final String? price;
  final double stock;
  final double stockMin;

  ProductItem({
    required this.id,
    required this.name,
    this.category,
    this.brand,
    this.size,
    this.color,
    this.price,
    required this.stock,
    required this.stockMin,
  });

  factory ProductItem.fromJson(Map<String, dynamic> j) => ProductItem(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        category: j['category'] as String?,
        brand: j['brand'] as String?,
        size: j['size'] as String?,
        color: j['color'] as String?,
        price: j['price'] as String?,
        stock: (j['stock'] as num?)?.toDouble() ?? 0,
        stockMin: (j['stockMin'] as num?)?.toDouble() ?? 0,
      );
}
