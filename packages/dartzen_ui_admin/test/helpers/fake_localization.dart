import 'package:dartzen_localization/dartzen_localization.dart';

/// A minimal fake [ZenLocalizationService] for testing.
///
/// Returns the value from the provided [map] for a given key,
/// or the raw key if no entry is found.
class FakeLocalization implements ZenLocalizationService {
  /// The key-to-translation map.
  final Map<String, String> map;

  /// Creates a [FakeLocalization] backed by [map].
  FakeLocalization(this.map);

  @override
  String translate(
    String key, {
    required String language,
    String? module,
    Map<String, dynamic> params = const {},
  }) => map[key] ?? key;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
