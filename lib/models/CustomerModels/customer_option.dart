class CustomerOption {
  final int id;
  final String name;

  CustomerOption({required this.id, required this.name});

  factory CustomerOption.fromJson(Map<String, dynamic> j) => CustomerOption(
        id: j['id'] ?? j['customerId'] ?? j['customer_id'],
        name: j['name'] ??
            '${j['firstName'] ?? ''} ${j['lastName'] ?? ''}'.trim(),
      );
}
