/// Represents the lifecycle state of an identity.
enum IdentityLifecycleState {
  /// The identity is active and can perform actions.
  active,

  /// The identity is temporarily suspended.
  suspended,

  /// The identity is pending verification (email, phone, etc.).
  verificationPending,

  /// The identity has been deactivated or soft-deleted.
  deactivated,

  /// The identity is locked due to security concerns.
  locked;

  /// Creates an [IdentityLifecycleState] from a string.
  ///
  /// Returns [IdentityLifecycleState.deactivated] if the string is unknown
  /// to ensure safe fallbacks.
  factory IdentityLifecycleState.fromJson(String json) =>
      IdentityLifecycleState.values.firstWhere(
        (e) => e.name == json,
        orElse: () => IdentityLifecycleState.deactivated,
      );

  /// Converts this state to its string representation.
  String toJson() => name;
}
