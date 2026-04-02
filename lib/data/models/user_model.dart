import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phoneNumber,
    super.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] as String?)?.trim() ?? '';
    final lastName = (json['last_name'] as String?)?.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final profile = json['profile'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'].toString(),
      name: fullName.isEmpty ? 'Utilisateur' : fullName,
      email: (json['email'] as String?) ?? '',
      phoneNumber: profile?['phone_number'] as String?,
    );
  }
}
