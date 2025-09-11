class SaleDetailItem {
  final int productId;
  final String productName;
  final String quantity;
  final String price;
  final String? discount;

  SaleDetailItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.discount,
  });

  factory SaleDetailItem.fromJson(Map<String, dynamic> j) => SaleDetailItem(
        productId: j['productId'],
        productName: j['productName'] ?? '',
        quantity: j['quantity'] ?? '0',
        price: j['price'] ?? '0',
        discount: j['discount'],
      );
}

class SaleDetail {
  final int saleId;
  final DateTime date;
  final bool status;
  final String? paymentMethod;
  final String? subtotal;
  final String? iva;
  final String? totalAmount;

  // cliente
  final int? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  // usuario
  final int? userId;
  final String? userName;

  final List<SaleDetailItem> items;

  SaleDetail({
    required this.saleId,
    required this.date,
    required this.status,
    this.paymentMethod,
    this.subtotal,
    this.iva,
    this.totalAmount,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.userId,
    this.userName,
    required this.items,
  });

  factory SaleDetail.fromJson(Map<String, dynamic> j) => SaleDetail(
        saleId: j['saleId'],
        date: DateTime.parse(j['date']),
        status: j['status'] == true,
        paymentMethod: j['paymentMethod'],
        subtotal: j['subtotal'] ?? j['subTotal'],
        iva: j['iva'],
        totalAmount: j['totalAmount'],
        customerId: j['customerId'],
        customerName: j['customerName'],
        customerEmail: j['customerEmail'],
        customerPhone: j['customerPhone'],
        userId: j['userId'],
        userName: j['userName'],
        items: (j['items'] as List? ?? [])
            .map((e) => SaleDetailItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
