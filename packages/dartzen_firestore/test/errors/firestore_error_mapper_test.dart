import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLocalizationLoader extends ZenLocalizationLoader {
  @override
  Future<String> load(String path) async => '{}';
}

void main() {
  late ZenLocalizationService localization;
  late FirestoreMessages messages;

  setUp(() async {
    localization = ZenLocalizationService(
      config: const ZenLocalizationConfig(isProduction: false),
      loader: MockLocalizationLoader(),
    );
    // Note: We don't loadModuleMessages here because we want to test with a dummy set
    messages = FirestoreMessages(localization, 'en');
  });

  group('FirestoreErrorMapper', () {
    test('maps permission-denied to ZenUnauthorizedError', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenUnauthorizedError>());
    });

    test('preserves original error in internalData', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error.internalData?['originalError'], equals(exception));
    });
  });
}
