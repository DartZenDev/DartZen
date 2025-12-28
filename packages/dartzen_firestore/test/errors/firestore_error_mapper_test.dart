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
      expect(
        error.internalData?['errorCode'],
        equals(FirestoreErrorCodes.permissionDenied),
      );
    });

    test('maps not-found to ZenNotFoundError', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
      );

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenNotFoundError>());
    });

    test('maps already-exists to ZenConflictError', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
      );

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenConflictError>());
    });

    test('maps unavailable to ZenUnknownError with metadata', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenUnknownError>());
      expect(
        error.internalData?['errorCode'],
        equals(FirestoreErrorCodes.unavailable),
      );
    });

    test('maps deadline-exceeded to ZenUnknownError with metadata', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
      );

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenUnknownError>());
      expect(
        error.internalData?['errorCode'],
        equals(FirestoreErrorCodes.timeout),
      );
    });

    test('maps unknown FirebaseException code to operation-failed', () {
      final exception = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'some-random-code',
      );

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenUnknownError>());
      expect(
        error.internalData?['errorCode'],
        equals(FirestoreErrorCodes.operationFailed),
      );
    });

    test('maps non-Firebase exception to unknown error', () {
      final exception = Exception('Something went wrong');

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenUnknownError>());
      expect(
        error.internalData?['originalError'],
        equals('Exception: Something went wrong'),
      );
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
