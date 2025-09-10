class UserListItem {
  final int userId;
  final String fullName;
  final String? area;
  final bool status;
  final String email;
  final String role;
  final List<String> permissions;

  UserListItem({
    required this.userId,
    required this.fullName,
    this.area,
    required this.status,
    required this.email,
    required this.role,
    required this.permissions,
  });

  factory UserListItem.fromJson(Map<String, dynamic> j) => UserListItem(
        userId: j['userId'] as int,
        fullName: j['fullName'] as String? ?? '',
        area: j['area'] as String?,
        status: j['status'] as bool? ?? true,
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? '',
        permissions: (j['permissions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
