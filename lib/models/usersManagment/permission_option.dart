class PermissionOption {
  final int id;
  final String name;

  PermissionOption({required this.id, required this.name});

  factory PermissionOption.fromJson(Map<String, dynamic> j) => PermissionOption(
        id: j['permissionId'] as int,
        name: j['permissionName'] as String? ?? '',
      );
}
