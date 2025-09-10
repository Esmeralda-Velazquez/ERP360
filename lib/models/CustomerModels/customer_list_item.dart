class CustomerListItem {
  final int id;
  final String fullName;
  final String? phone;
  final String? email;
  final bool status;

  CustomerListItem({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.status,
  });

  factory CustomerListItem.fromJson(Map<String, dynamic> j) => CustomerListItem(
        id: j['id'] as int,
        fullName: j['fullName'] as String? ?? '',
        phone: j['phoneNumber'] as String?,
        email: j['email'] as String?,
        status: j['status'] as bool? ?? true,
      );
}
