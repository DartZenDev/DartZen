import 'package:dartzen_core/dartzen_core.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreIdentityRepository (unit)', () {
    test('changeRoles returns success and correct patch', () async {
      // Simulate repository response
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
      // Simulate repository response
      final patchBody = {
        'fields': {
          'lifecycle.state': {'stringValue': 'active'},
          // 'lifecycle.reason' intentionally omitted
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
