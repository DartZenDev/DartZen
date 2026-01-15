/// Stable payment lifecycle states.
enum PaymentStatus {
  /// Payment intent created but not yet initiated with provider.
  pending,

  /// Payment initiated with provider and awaiting confirmation.
  initiated,

  /// Payment confirmed/authorized by provider.
  confirmed,

  /// Payment fully captured/settled.
  completed,

  /// Payment failed or was declined.
  failed,

  /// Payment refunded after completion.
  refunded,
}
