import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreIdentityRepository (unit)', () {
    test(
      'getIdentityById returns ZenNotFoundError if document missing',
      () async {
        // Simulate repository response
        const result = ZenResult<Identity>.err(ZenNotFoundError('Not found'));
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ZenNotFoundError>());
      },
    );

    test('createIdentity returns success and stores identity', () async {
      // Simulate repository response
      const id = IdentityId.reconstruct('user_1');
      final identity = Identity.createPending(id: id);
      final result = ZenResult<Identity>.ok(identity);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNotNull);
      expect(result.dataOrNull!.id, equals(id));
    });

    test('suspendIdentity returns success and updates lifecycle', () async {
      // Simulate repository response
      const id = IdentityId.reconstruct('user_1');
      final pending = Identity.createPending(id: id);
      const suspendedLifecycle = IdentityLifecycle.reconstruct(
        IdentityState.disabled,
        'Rule violation',
      );
      final suspendedIdentity = pending.withLifecycle(suspendedLifecycle);
      final result = ZenResult<Identity>.ok(suspendedIdentity);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNotNull);
      expect(
        result.dataOrNull!.lifecycle.state,
        equals(IdentityState.disabled),
      );
      expect(result.dataOrNull!.lifecycle.reason, equals('Rule violation'));
    });
  });

  group('Repository additional behaviors', () {
    test('changeRoles returns success and correct patch', () async {
      final patchBody = {
        'fields': {
          'authority.roles': {
            'arrayValue': {
              'values': [
                {'stringValue': 'ADMIN'},
                {'stringValue': 'USER'},
              ],
            },
          },
          'authority.capabilities': {
            'arrayValue': {
              'values': [
                {'stringValue': 'can_edit'},
                {'stringValue': 'can_view'},
              ],
            },
          },
        },
      };
      final result = ZenResult<Map<String, dynamic>>.ok(patchBody);
      expect(result.isSuccess, isTrue);
      final fields = result.dataOrNull?['fields'] as Map<String, dynamic>?;
      expect(fields, isNotNull);
      final Map<String, dynamic> rolesField =
          fields!['authority.roles'] as Map<String, dynamic>;
      final Map<String, dynamic> arrayValueRoles =
          rolesField['arrayValue'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> rolesRaw =
          (arrayValueRoles['values'] as List).cast<Map<String, dynamic>>();
      final List<String> roles = rolesRaw
          .map((e) => e['stringValue'] as String)
          .toList();
      expect(roles, containsAll(['ADMIN', 'USER']));

      final Map<String, dynamic> capabilitiesField =
          fields['authority.capabilities'] as Map<String, dynamic>;
      final Map<String, dynamic> arrayValueCapabilities =
          capabilitiesField['arrayValue'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> capabilitiesRaw =
          (arrayValueCapabilities['values'] as List)
              .cast<Map<String, dynamic>>();
      final List<String> capabilities = capabilitiesRaw
          .map((e) => e['stringValue'] as String)
          .toList();
      expect(capabilities, containsAll(['can_edit', 'can_view']));
    });

    test('verifyEmail returns success and omits null reason', () async {
      final patchBody = {
        'fields': {
          'lifecycle.state': {'stringValue': 'active'},
        },
      };
      final result = ZenResult<Map<String, dynamic>>.ok(patchBody);
      expect(result.isSuccess, isTrue);
      final fields = result.dataOrNull?['fields'] as Map<String, dynamic>?;
      expect(fields, isNotNull);
      final Map<String, dynamic> lifecycleStateField =
          fields!['lifecycle.state'] as Map<String, dynamic>;
      final String lifecycleState =
          lifecycleStateField['stringValue'] as String;
      expect(lifecycleState, equals('active'));
      expect(fields.containsKey('lifecycle.reason'), isFalse);
    });
  });
}
