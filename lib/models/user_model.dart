import 'health_profile.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final HealthProfile? healthProfile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.healthProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      healthProfile: json['healthProfile'] != null
          ? HealthProfile.fromJson(json['healthProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    if (healthProfile != null) 'healthProfile': healthProfile!.toJson(),
  };

  UserModel copyWith({String? name, HealthProfile? healthProfile}) => UserModel(
    id: id,
    email: email,
    name: name ?? this.name,
    healthProfile: healthProfile ?? this.healthProfile,
  );
}
