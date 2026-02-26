import 'package:dartzen_ui_admin/src/admin/zen_admin_client.dart';
import 'package:dartzen_ui_admin/src/state/admin_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements ZenAdminClient {}

void main() {
  group('zenAdminClientProvider', () {
    test('throws when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Riverpod wraps the UnimplementedError in a ProviderException.
      expect(
        () => container.read(zenAdminClientProvider),
        throwsA(isA<Object>()),
      );
    });

    test('returns overridden client when provided', () {
      final mockClient = _MockClient();
      final container = ProviderContainer(
        overrides: [zenAdminClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      expect(container.read(zenAdminClientProvider), same(mockClient));
    });
  });
}
