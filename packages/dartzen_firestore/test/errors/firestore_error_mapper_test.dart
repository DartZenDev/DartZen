import 'dart:convert';

import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class MockLocalizationLoader extends ZenLocalizationLoader {
  @override
  @override
  Future<String> load(String path) async => jsonEncode({
    'firestore.error.permission_denied': 'Permission denied',
    'firestore.error.not_found': 'Document not found',
    'firestore.error.timeout': 'Operation timed out',
    'firestore.error.unavailable': 'Firestore service unavailable',
    'firestore.error.corrupted_data': 'Corrupted or invalid data',
    'firestore.error.operation_failed': 'Firestore operation failed',
    'firestore.error.unknown': 'Unknown Firestore error',
  });
}

void main() {
  late ZenLocalizationService localization;
  late FirestoreMessages messages;

  setUp(() async {
    localization = ZenLocalizationService(
      config: const ZenLocalizationConfig(isProduction: false),
      loader: MockLocalizationLoader(),
    );
    await localization.loadModuleMessages(
      'firestore',
      'en',
      modulePath: 'lib/src/l10n',
    );
    messages = FirestoreMessages(localization, 'en');
  });

  group('FirestoreErrorMapper', () {
    test('maps 403 ClientException to ZenUnauthorizedError', () {
      final exception = http.ClientException('Error 403: Forbidden');

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

    test('maps 404 ClientException to ZenNotFoundError', () {
      final exception = http.ClientException('Error 404: Not Found');

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenNotFoundError>());
    });

    test('maps 409 ClientException to ZenConflictError', () {
      final exception = http.ClientException('Error 409: Already Exists');

      final error = FirestoreErrorMapper.mapException(
        exception,
        StackTrace.current,
        messages,
      );

      expect(error, isA<ZenConflictError>());
    });

    test(
      'maps 503 ClientException to ZenUnknownError with unavailable code',
      () {
        final exception = http.ClientException(
          'Error 503: Service Unavailable',
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
      },
    );

    test('maps generic ClientException to operation-failed', () {
      final exception = http.ClientException('Network Error');

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

    test('maps non-HTTP exception to unknown error', () {
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
  });
}
