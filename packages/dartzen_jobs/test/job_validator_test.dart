import 'package:dartzen_jobs/src/errors.dart';
import 'package:dartzen_jobs/src/job_validator.dart';
import 'package:dartzen_jobs/src/models/job_config.dart';
import 'package:dartzen_jobs/src/models/job_definition.dart';
import 'package:dartzen_jobs/src/models/job_status.dart';
import 'package:dartzen_jobs/src/models/job_type.dart';
import 'package:test/test.dart';

void main() {
  group('JobValidator', () {
    group('validateJobExists', () {
      test('does not throw if job is registered', () {
        final registry = {
          'test-job': const JobDescriptor(
            id: 'test-job',
            type: JobType.endpoint,
          ),
        };

        // Should not throw
        JobValidator.validateJobExists('test-job', registry);
      });

      test('throws if job is not registered', () {
        final registry = <String, JobDescriptor>{};

        expect(
          () => JobValidator.validateJobExists('missing-job', registry),
          throwsA(isA<MissingDescriptorException>()),
        );
      });
    });

    group('isEnabledForExecution', () {
      late DateTime now;

      setUp(() {
        now = DateTime(2024, 1, 15, 12);
      });

      test('returns eligible=true when all conditions are met', () {
        const config = JobConfig(
          id: 'test-job',
          enabled: true,
          lastStatus: JobStatus.success,
        );

        final (eligible, reason) = JobValidator.isEnabledForExecution(
          config,
          now,
        );

        expect(eligible, isTrue);
        expect(reason, isNull);
      });

      test('returns ineligible when job is disabled', () {
        const config = JobConfig(
          id: 'test-job',
          enabled: false,
          lastStatus: JobStatus.success,
        );

        final (eligible, reason) = JobValidator.isEnabledForExecution(
          config,
          now,
        );

        expect(eligible, isFalse);
        expect(reason, contains('disabled'));
      });

      test('returns ineligible when start date is in the future', () {
        final config = JobConfig(
          id: 'test-job',
          enabled: true,
          startAt: DateTime(2024, 1, 16),
          skipDates: [],
          dependencies: [],
          lastStatus: JobStatus.success,
        );

        final (eligible, reason) = JobValidator.isEnabledForExecution(
          config,
          now,
        );

        expect(eligible, isFalse);
        expect(reason, contains('not started'));
      });

      test('returns ineligible when end date has passed', () {
        final config = JobConfig(
          id: 'test-job',
          enabled: true,
          endAt: DateTime(2024, 1, 14),
          skipDates: [],
          dependencies: [],
          lastStatus: JobStatus.success,
        );

        final (eligible, reason) = JobValidator.isEnabledForExecution(
          config,
          now,
        );

        expect(eligible, isFalse);
        expect(reason, contains('ended'));
      });

      test('returns ineligible when today is a skip date', () {
        final config = JobConfig(
          id: 'test-job',
          enabled: true,
          skipDates: [DateTime(2024, 1, 15)],
          dependencies: [],
          lastStatus: JobStatus.success,
        );

        final (eligible, reason) = JobValidator.isEnabledForExecution(
          config,
          now,
        );

        expect(eligible, isFalse);
        expect(reason, contains('skip date'));
      });

      test('returns eligible when start date is today or earlier', () {
        final config = JobConfig(
          id: 'test-job',
          enabled: true,
          startAt: DateTime(2024, 1, 15),
          skipDates: [],
          dependencies: [],
          lastStatus: JobStatus.success,
        );

        final (eligible, reason) = JobValidator.isEnabledForExecution(
          config,
          now,
        );

        expect(eligible, isTrue);
      });

      test('returns eligible when end date is today or later', () {
        final config = JobConfig(
          id: 'test-job',
          enabled: true,
          endAt: DateTime(2024, 1, 15),
          skipDates: [],
          dependencies: [],
          lastStatus: JobStatus.success,
        );

        final (eligible, reason) = JobValidator.isEnabledForExecution(
          config,
          now,
        );

        expect(eligible, isTrue);
      });
    });

    group('validateDependencies', () {
      late DateTime now;

      setUp(() {
        now = DateTime(2024, 1, 15, 12);
      });

      test('returns true when all dependencies succeeded', () {
        final successConfig = JobConfig(
          id: 'dep1',
          enabled: true,
          skipDates: [],
          dependencies: [],
          lastRun: now,
          lastStatus: JobStatus.success,
        );

        final configsById = {
          'dep1': successConfig,
          'dep2': JobConfig(
            id: 'dep2',
            enabled: true,
            skipDates: [],
            dependencies: [],
            lastRun: now,
            lastStatus: JobStatus.success,
          ),
        };

        final result = JobValidator.validateDependencies([
          'dep1',
          'dep2',
        ], configsById);

        expect(result, isTrue);
      });

      test('returns false when a dependency failed', () {
        final successConfig = JobConfig(
          id: 'dep1',
          enabled: true,
          skipDates: [],
          dependencies: [],
          lastRun: now,
          lastStatus: JobStatus.success,
        );

        final failureConfig = JobConfig(
          id: 'dep2',
          enabled: true,
          skipDates: [],
          dependencies: [],
          lastRun: now,
          lastStatus: JobStatus.failure,
        );

        final configsById = {'dep1': successConfig, 'dep2': failureConfig};

        final result = JobValidator.validateDependencies([
          'dep1',
          'dep2',
        ], configsById);

        expect(result, isFalse);
      });

      test('returns false when a dependency is missing', () {
        final successConfig = JobConfig(
          id: 'dep1',
          enabled: true,
          skipDates: [],
          dependencies: [],
          lastRun: now,
          lastStatus: JobStatus.success,
        );

        final configsById = {'dep1': successConfig};

        final result = JobValidator.validateDependencies([
          'dep1',
          'dep2',
        ], configsById);

        expect(result, isFalse);
      });

      test('returns true when there are no dependencies', () {
        final configsById = <String, JobConfig>{};

        final result = JobValidator.validateDependencies([], configsById);

        expect(result, isTrue);
      });
    });
  });
}
