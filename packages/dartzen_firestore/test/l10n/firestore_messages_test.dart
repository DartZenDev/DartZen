import 'package:dartzen_firestore/src/l10n/firestore_messages.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:test/test.dart';

class _FakeLocalization implements ZenLocalizationService {
  @override
  String translate(
    String key, {
    required String language,
    String? module,
    Map<String, dynamic>? params,
  }) {
    if (params != null && params.containsKey('host')) {
      return 'emulator ${params['host']}:${params['port']}';
    }
    return 'translated:$key';
  }

  // Unused - provide minimal stub implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FirestoreMessages', () {
    final loc = _FakeLocalization();
    final msgs = FirestoreMessages(loc, 'en');

    test('basic accessors return translated keys', () {
      expect(msgs.permissionDenied(), contains('translated:'));
      expect(msgs.notFound(), contains('translated:'));
      expect(msgs.operationFailed(), contains('translated:'));
      expect(msgs.unknown(), contains('translated:'));
      // additional basic accessors
      expect(msgs.timeout(), contains('translated:'));
      expect(msgs.unavailable(), contains('translated:'));
      expect(msgs.corruptedData(), contains('translated:'));
    });

    test('emulatorConnection formats params', () {
      final s = msgs.emulatorConnection('127.0.0.1', 8085);
      expect(s, contains('127.0.0.1'));
      expect(s, contains('8085'));
    });

    test(
      'productionConnection and emulatorUnavailable return translations',
      () {
        expect(msgs.productionConnection(), contains('translated:'));
        final u = msgs.emulatorUnavailable('host.local', 9090);
        expect(u, contains('host.local'));
        expect(u, contains('9090'));
      },
    );
  });
}
