import 'package:dartzen_identity/dartzen_identity.dart';
import 'package:test/test.dart';

void main() {
  group('AuthorityContract.fromJson', () {
    test('handles missing roles/capabilities', () {
      final contract = AuthorityContract.fromJson(const {});
      expect(contract.roles, isEmpty);
      expect(contract.capabilities, isEmpty);
    });
    test('handles null roles/capabilities', () {
      final contract = AuthorityContract.fromJson(const {
        'roles': null,
        'capabilities': null,
      });
      expect(contract.roles, isEmpty);
      expect(contract.capabilities, isEmpty);
    });
  });
}
