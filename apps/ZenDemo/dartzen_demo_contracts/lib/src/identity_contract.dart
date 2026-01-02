/// Summary contract representing a lightweight identity snapshot for UI.
///
/// This is intentionally distinct from `dartzen_identity` domain contracts and
/// should be used only for presentation summaries.
class ProfileSummaryContract {
  /// Creates a profile summary contract.
  const ProfileSummaryContract({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// User ID.
  final String id;

  /// Email address.
  final String email;

  /// Display name.
  final String? displayName;

  /// Photo URL.
  final String? photoUrl;

  /// Creates an instance from JSON.
  factory ProfileSummaryContract.fromJson(Map<String, dynamic> json) =>
      ProfileSummaryContract(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String?,
        photoUrl: json['photo_url'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'photo_url': photoUrl,
  };
}
