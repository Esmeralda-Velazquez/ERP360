class SaleRow {
  final int productId;
  final String productName;
  String quantity;   
  String price;      
  String? discount;  

  SaleRow({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.discount,
  });

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "quantity": quantity,
        "price": price,
        if (discount != null && discount!.isNotEmpty) "discount": discount
      };
}

class CreateSaleRequest {
  String? paymentMethod;
  String? totalAmount;
  String? iva;
  DateTime? date;
  int? customerId;
  int? userId;
  List<SaleRow> items;

  CreateSaleRequest({
    this.paymentMethod,
    this.totalAmount,
    this.iva,
    this.date,
    this.customerId,
    this.userId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        "paymentMethod": paymentMethod,
        "totalAmount": totalAmount,
        "iva": iva,
        "date": date?.toIso8601String(),
        "customerId": customerId,
        "userId": userId,
        "items": items.map((e) => e.toJson()).toList()
      };
}

class SaleSummary {
  final int saleId;
  final String? paymentMethod;
  final String? totalAmount;
  final String? iva;
  final DateTime date;
  final bool status;
  final int? customerId;
  final String? customerName;
  final int? userId;
  final String? userName;

  SaleSummary({
    required this.saleId,
    this.paymentMethod,
    this.totalAmount,
    this.iva,
    required this.date,
    required this.status,
    this.customerId,
    this.customerName,
    this.userId,
    this.userName,
  });

  factory SaleSummary.fromJson(Map<String, dynamic> j) => SaleSummary(
        saleId: j['saleId'],
        paymentMethod: j['paymentMethod'],
        totalAmount: j['totalAmount'],
        iva: j['iva'],
        date: DateTime.parse(j['date']),
        status: j['status'] == true,
        customerId: j['customerId'],
        customerName: j['customerName'],
        userId: j['userId'],
        userName: j['userName'],
      );
}
