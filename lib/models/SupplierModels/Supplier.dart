class Supplier {
  final int supplierId;
  final String supplierName;
  final String? phoneNumber;
  final String? paymentMethod;
  final String? address;
  final bool status;
  final DateTime? registrationDate;
  final String? category; // viene del include/DTO

  Supplier({
    required this.supplierId,
    required this.supplierName,
    this.phoneNumber,
    this.paymentMethod,
    this.address,
    required this.status,
    this.registrationDate,
    this.category,
  });

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
        supplierId: j['supplierId'] as int,
        supplierName: j['supplierName'] as String? ?? '',
        phoneNumber: j['phoneNumber'] as String?,
        paymentMethod: j['paymentMethod'] as String?,
        address: j['address'] as String?,
        status: j['status'] as bool? ?? true,
        registrationDate: j['registrationDate'] != null
            ? DateTime.tryParse(j['registrationDate'].toString())
            : null,
        category: j['category'] as String?,
      );
}
