class UserModel {
  int? id;
  String displayName;
  String email;
  String password;
  String? profilePhoto;

  UserModel({
    this.id,
    required this.displayName,
    required this.email,
    required this.password,
    this.profilePhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'password': password,
      'profilePhoto': profilePhoto,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as int?,
    displayName: map['displayName'] ?? '',
    email: map['email'] ?? '',
    password: map['password'] ?? '',
    profilePhoto: map['profilePhoto'],
  );
}
