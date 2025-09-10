class RoleListItem {
  final int id;
  final String name;
  final bool status;
  final List<String> permissions;

  RoleListItem({
    required this.id,
    required this.name,
    required this.status,
    required this.permissions,
  });

  factory RoleListItem.fromJson(Map<String, dynamic> j) => RoleListItem(
        id: j['roleId'] as int,
        name: j['roleName'] as String? ?? '',
        status: j['status'] as bool? ?? true,
        permissions: (j['permissions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
