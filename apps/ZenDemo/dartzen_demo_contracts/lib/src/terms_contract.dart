/// Contract for terms and conditions content.
class TermsContract {
  /// Creates a terms contract.
  const TermsContract({required this.content, required this.contentType});

  /// Creates a terms contract from JSON.
  factory TermsContract.fromJson(Map<String, dynamic> json) => TermsContract(
    content: json['content'] as String,
    contentType: json['content_type'] as String,
  );

  /// The terms content (HTML or Markdown).
  final String content;

  /// The content MIME type.
  final String contentType;

  /// Converts this contract to JSON.
  Map<String, dynamic> toJson() => {
    'content': content,
    'content_type': contentType,
  };
}
