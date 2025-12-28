import 'package:dartzen_infrastructure_identity/src/l10n/infrastructure_identity_messages.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:test/test.dart';

/// Tests for [InfrastructureIdentityMessages] to ensure all localized messages
/// can be constructed and used without errors.
///
/// This addresses the requirement to verify message localization usage.
void main() {
  group('InfrastructureIdentityMessages', () {
    late ZenLocalizationService localization;
    late InfrastructureIdentityMessages messages;

    setUp(() {
      localization = ZenLocalizationService(
        config: const ZenLocalizationConfig(),
      );
      messages = InfrastructureIdentityMessages(
        localization: localization,
        language: 'en',
      );
    });

    group('resolvingIdentity', () {
      test('constructs message without error', () {
        expect(
          () => messages.resolvingIdentity(
            subject: 'hashed-123',
            providerId: 'google.com',
          ),
          returnsNormally,
        );
      });

      test('handles special characters in parameters', () {
        final message = messages.resolvingIdentity(
          subject: 'hash-with-special!@#',
          providerId: 'provider.co.uk',
        );

        expect(message, isNotEmpty);
        expect(message, isNot(contains('null')));
      });
    });

    group('resolutionFailed', () {
      test('returns meaningful error message', () {
        final message = messages.resolutionFailed(
          subject: 'hashed-456',
          providerId: 'github.com',
        );

        expect(message, contains('failed'));
        expect(message, contains('hashed-456'));
        expect(message, contains('github.com'));
      });

      test('message is user-centric and actionable', () {
        final message = messages.resolutionFailed(
          subject: 'test-hash',
          providerId: 'test-provider',
        );

        // Verify it's not just a technical error dump
        expect(message.toLowerCase(), contains('failed'));
        expect(message, isNot(contains('null')));
        expect(message, isNot(contains('undefined')));
      });
    });

    group('loadingIdentity', () {
      test('includes both identityId and subject', () {
        final message = messages.loadingIdentity(
          identityId: 'id-789',
          subject: 'hashed-789',
        );

        expect(message, contains('id-789'));
        expect(message, contains('hashed-789'));
        expect(message, isNotEmpty);
      });
    });

    group('identityLoaded', () {
      test('returns success message with identityId', () {
        final message = messages.identityLoaded(identityId: 'id-success');

        expect(message, contains('success'));
        expect(message, contains('id-success'));
      });
    });

    group('identityLoadFailed', () {
      test('returns clear failure message', () {
        final message = messages.identityLoadFailed(identityId: 'id-fail');

        expect(message, contains('fail'));
        expect(message, contains('id-fail'));
        expect(message, isNot(isEmpty));
      });
    });

    group('creatingIdentity', () {
      test('includes subject and providerId', () {
        final message = messages.creatingIdentity(
          subject: 'new-hash',
          providerId: 'azure.com',
        );

        expect(message, contains('new-hash'));
        expect(message, contains('azure.com'));
        expect(message, contains('creat'));
      });
    });

    group('identityCreated', () {
      test('returns success message', () {
        final message = messages.identityCreated(identityId: 'new-id');

        expect(message, contains('success'));
        expect(message, contains('new-id'));
      });
    });

    group('identityCreationFailed', () {
      test('returns clear error message', () {
        final message = messages.identityCreationFailed(subject: 'fail-hash');

        expect(message, contains('fail'));
        expect(message, contains('fail-hash'));
      });
    });

    group('mappingFailed', () {
      test('returns generic mapping failure message', () {
        final message = messages.mappingFailed();

        expect(message, contains('fail'));
        expect(message, contains('mapping'));
        expect(message, isNot(isEmpty));
      });

      test('does not include PII parameters', () {
        final message = messages.mappingFailed();

        // Mapping failed should be generic without exposing details
        expect(message, isNot(contains('subject')));
        expect(message, isNot(contains('email')));
      });
    });

    group('message consistency', () {
      test('all success messages use consistent terminology', () {
        final loaded = messages.identityLoaded(identityId: 'test');
        final created = messages.identityCreated(identityId: 'test');

        // Both should indicate success
        expect(loaded.toLowerCase(), contains('success'));
        expect(created.toLowerCase(), contains('success'));
      });

      test('all failure messages use consistent terminology', () {
        final loadFail = messages.identityLoadFailed(identityId: 'test');
        final createFail = messages.identityCreationFailed(subject: 'test');
        final resolveFail = messages.resolutionFailed(
          subject: 'test',
          providerId: 'test',
        );

        // All should indicate failure
        expect(loadFail.toLowerCase(), contains('fail'));
        expect(createFail.toLowerCase(), contains('fail'));
        expect(resolveFail.toLowerCase(), contains('fail'));
      });
    });

    group('parameter interpolation', () {
      test('all parameterized messages handle empty strings', () {
        // Should not crash with empty strings
        expect(
          () => messages.resolvingIdentity(subject: '', providerId: ''),
          returnsNormally,
        );
        expect(
          () => messages.loadingIdentity(identityId: '', subject: ''),
          returnsNormally,
        );
        expect(
          () => messages.creatingIdentity(subject: '', providerId: ''),
          returnsNormally,
        );
      });

      test('messages handle long parameter values', () {
        final longString = 'a' * 500;
        final message = messages.resolvingIdentity(
          subject: longString,
          providerId: 'provider',
        );

        expect(message, isNotEmpty);
        expect(message, contains('provider'));
      });
    });
  });
}
