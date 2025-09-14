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
    required this.email,
    required this.role,
    required this.status,
    this.area,
    List<String>? permissions,
  }) : permissions = permissions ?? const [];

  factory UserListItem.fromJson(Map<String, dynamic> j) {
    return UserListItem(
      userId: (j['userId'] ?? j['UserId']) as int,
      fullName: (j['fullName'] ?? j['FullName'] ?? '').toString(),
      area: (j['area'] ?? j['Area'])?.toString(),
      status: (j['status'] ?? j['Status'] ?? false) as bool,
      email: (j['email'] ?? j['Email'] ?? '').toString(),
      role: (j['role'] ?? j['Role'] ?? '').toString(),
      permissions: ((j['permissions'] ?? j['Permissions']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  UserListItem copyWith({
    int? userId,
    String? fullName,
    String? area,
    bool? status,
    String? email,
    String? role,
    List<String>? permissions,
  }) {
    return UserListItem(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      area: area ?? this.area,
      status: status ?? this.status,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
    );
  }
}
