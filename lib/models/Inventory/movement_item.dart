class MovementItem {
  final int id;
  final String type;         // IN / OUT / ADJ
  final String amount;       // viene como string (BD varchar)
  final DateTime date;
  final int productId;
  final String productName;
  final int? userId;
  final String? userName;

  MovementItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.productId,
    required this.productName,
    this.userId,
    this.userName,
  });

  factory MovementItem.fromJson(Map<String, dynamic> j) => MovementItem(
        id: j['movementId'] ?? j['movement_id'] ?? j['id'],
        type: j['type'] ?? '',
        amount: j['amount']?.toString() ?? '0',
        date: DateTime.parse(j['date']),
        productId: j['productId'] ?? j['product_id'],
        productName: j['productName'] ?? j['product_name'] ?? '',
        userId: j['userId'],
        userName: j['userName'],
      );
}
