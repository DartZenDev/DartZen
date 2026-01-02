/// Contract for user profile data.
class ProfileContract {
  /// Creates a profile contract.
  const ProfileContract({
    required this.userId,
    required this.displayName,
    required this.email,
    this.bio,
  });

  /// Creates a profile contract from JSON.
  factory ProfileContract.fromJson(Map<String, dynamic> json) =>
      ProfileContract(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        email: json['email'] as String,
        bio: json['bio'] as String?,
      );

  /// The user identifier.
  final String userId;

  /// The user display name.
  final String displayName;

  /// The user email.
  final String email;

  /// The user bio.
  final String? bio;

  /// Converts this contract to JSON.
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'display_name': displayName,
    'email': email,
    'bio': bio,
  };
}
