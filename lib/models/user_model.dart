class UserModel {
  final String id;
  final String email;
  final String username;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
  });

  Map<String, dynamic> toMap() => {
        'email': email,
        'username': username,
        'createdAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      };

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] as String,
      username: map['username'] as String,
    );
  }
}
