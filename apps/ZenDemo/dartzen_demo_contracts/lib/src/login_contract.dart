/// Login request contract.
class LoginRequestContract {
  /// Email address.
  final String email;

  /// Password.
  final String password;

  /// Creates a [LoginRequestContract].
  const LoginRequestContract({required this.email, required this.password});

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {'email': email, 'password': password};

  /// Creates from JSON.
  factory LoginRequestContract.fromJson(Map<String, dynamic> json) =>
      LoginRequestContract(
        email: json['email'] as String,
        password: json['password'] as String,
      );
}

/// Login response contract.
class LoginResponseContract {
  /// Firebase ID token.
  final String idToken;

  /// User ID.
  final String userId;

  /// Creates a [LoginResponseContract].
  const LoginResponseContract({required this.idToken, required this.userId});

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {'idToken': idToken, 'userId': userId};

  /// Creates from JSON.
  factory LoginResponseContract.fromJson(Map<String, dynamic> json) =>
      LoginResponseContract(
        idToken: json['idToken'] as String,
        userId: json['userId'] as String,
      );
}
