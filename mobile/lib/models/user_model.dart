class UserModel {
  final String id;
  final String email;
  final String? name;
  final String role;
  final DateTime? createdAt;

  UserModel({required this.id, required this.email, this.name, required this.role, this.createdAt});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'] ?? 'USER',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  bool get isAdmin => role == 'ADMIN';
}
