class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'customer' | 'driver'

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isCustomer => role == 'customer';
  bool get isDriver => role == 'driver';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email, role: $role)';
}