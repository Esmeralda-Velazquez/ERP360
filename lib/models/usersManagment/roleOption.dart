class RoleOption {
  final int id;
  final String name;

  RoleOption({required this.id, required this.name});

  factory RoleOption.fromJson(Map<String, dynamic> j) =>
      RoleOption(id: j['roleId'] as int, name: j['roleName'] as String? ?? '');
}
