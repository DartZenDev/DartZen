/// Token for cancelling async AI operations.
final class CancelToken {
  /// Creates a cancel token.
  CancelToken();

  bool _isCancelled = false;

  /// Whether this token has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Cancels the operation.
  void cancel() {
    _isCancelled = true;
  }
}
