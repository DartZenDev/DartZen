import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_firestore/dartzen_firestore.dart';

import '../dartzen_jobs.dart' show JobDescriptor;
import 'models/job_config.dart';
import 'models/job_definition.dart' show JobDescriptor;
import 'models/job_status.dart';

/// Repository for managing job configuration and runtime state in Firestore.
///
/// [JobStore] acts as the bridge between the execution system and the database.
/// It provides methods to fetch [JobConfig] objects and persist execution
/// results (last run time, status, retries).
///
/// Jobs are stored in the `jobs` collection. Each document ID corresponds
/// to the [JobDescriptor.id].
class JobStore {
  /// The Firestore collection used for storing job configuration and state.
  static const String collection = 'jobs';

  final FirestoreRestClient _client;

  /// Creates a [JobStore].
  ///
  /// [client] allows injecting a specific Firestore instance, primarily for testing.
  /// Defaults to [FirestoreConnection.client].
  JobStore({FirestoreRestClient? client})
    : _client = client ?? FirestoreConnection.client;

  /// Fetches the configuration for a specific job from Firestore.
  ///
  /// Returns [ZenNotFoundError] if the job configuration document does not exist.
  Future<ZenResult<JobConfig>> getJobConfig(String jobId) async {
    try {
      final doc = await _client.getDocument('$collection/$jobId');

      if (!doc.exists) {
        return ZenResult.err(
          ZenNotFoundError('Job configuration not found for: $jobId'),
        );
      }

      return ZenResult.ok(_mapToJobConfig(doc.id, doc.data!));
    } catch (e) {
      return ZenResult.err(ZenUnknownError('Failed to fetch job config: $e'));
    }
  }

  /// Updates the runtime state of a job in Firestore.
  ///
  /// This method uses the `state.` prefix to update nested fields in the document.
  /// Only non-null parameters are included in the update.
  Future<ZenResult<void>> updateJobState(
    String jobId, {
    DateTime? lastRun,
    DateTime? nextRun,
    JobStatus? lastStatus,
    int? currentRetries,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (lastRun != null) updates['state.lastRun'] = lastRun.toIso8601String();
      if (nextRun != null) updates['state.nextRun'] = nextRun.toIso8601String();
      if (lastStatus != null) {
        updates['state.status'] = lastStatus.toStorageString();
      }
      if (currentRetries != null) updates['state.retries'] = currentRetries;

      if (updates.isEmpty) return const ZenResult.ok(null);

      await _client.patchDocument('$collection/$jobId', updates);
      return const ZenResult.ok(null);
    } catch (e) {
      return ZenResult.err(ZenUnknownError('Failed to update job state: $e'));
    }
  }

  /// Retrieves all periodic jobs that are currently enabled.
  ///
  /// This method performs a structured Firestore query to find documents
  /// where `type == 'periodic'` and `enabled == true`.
  Future<ZenResult<List<JobConfig>>> getEnabledPeriodicJobs() async {
    try {
      final query = {
        'from': [
          {'collectionId': collection},
        ],
        'where': {
          'compositeFilter': {
            'op': 'AND',
            'filters': [
              {
                'fieldFilter': {
                  'field': {'fieldPath': 'type'},
                  'op': 'EQUAL',
                  'value': {'stringValue': 'periodic'},
                },
              },
              {
                'fieldFilter': {
                  'field': {'fieldPath': 'enabled'},
                  'op': 'EQUAL',
                  'value': {'booleanValue': true},
                },
              },
            ],
          },
        },
      };

      final results = await _client.runStructuredQuery(query);

      final configs = <JobConfig>[];
      for (final dynamic row in results) {
        if (row is! Map<String, dynamic>) continue;
        final doc = row['document'];
        if (doc is Map<String, dynamic>) {
          final id = (doc['name'] as String).split('/').last;
          final fields = doc['fields'] as Map<String, dynamic>? ?? {};
          configs.add(_mapToJobConfig(id, _flattenFirestoreFields(fields)));
        }
      }
      return ZenResult.ok(configs);
    } catch (e) {
      return ZenResult.err(
        ZenUnknownError('Failed to fetch periodic jobs: $e'),
      );
    }
  }

  Map<String, dynamic> _flattenFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (value.containsKey('stringValue')) {
          result[key] = value['stringValue'];
        } else if (value.containsKey('booleanValue')) {
          result[key] = value['booleanValue'];
        } else if (value.containsKey('integerValue')) {
          result[key] = int.tryParse(value['integerValue'].toString());
        } else if (value.containsKey('doubleValue')) {
          result[key] = double.tryParse(value['doubleValue'].toString());
        } else if (value.containsKey('timestampValue')) {
          result[key] = value['timestampValue'];
        } else if (value.containsKey('arrayValue')) {
          final arrayValue = value['arrayValue'] as Map<String, dynamic>;
          final values = arrayValue['values'] as List? ?? [];
          result[key] = values.map((v) {
            final val = v as Map<String, dynamic>;
            return val['stringValue'] ??
                val['integerValue'] ??
                val['timestampValue'] ??
                val['booleanValue'];
          }).toList();
        } else if (value.containsKey('mapValue')) {
          final mapValue = value['mapValue'] as Map<String, dynamic>;
          result[key] = _flattenFirestoreFields(
            mapValue['fields'] as Map<String, dynamic>? ?? {},
          );
        }
      }
    });
    return result;
  }

  JobConfig _mapToJobConfig(String id, Map<String, dynamic> data) {
    final state = data['state'] as Map<String, dynamic>? ?? {};
    return JobConfig(
      id: id,
      enabled: data['enabled'] as bool? ?? false,
      startAt: _parseDate(data['startAt']),
      endAt: _parseDate(data['endAt']),
      skipDates:
          (data['skipDates'] as List?)
              ?.map(_parseDate)
              .whereType<DateTime>()
              .toList() ??
          [],
      dependencies: (data['dependencies'] as List?)?.cast<String>() ?? [],
      priority: (data['priority'] as num?)?.toInt() ?? 0,
      maxRetries: (data['maxRetries'] as num?)?.toInt() ?? 3,
      interval: data['interval'] != null
          ? Duration(seconds: (data['interval'] as num).toInt())
          : null,
      cron: data['cron'] as String?,
      lastRun: _parseDate(state['lastRun']),
      nextRun: _parseDate(state['nextRun']),
      lastStatus: JobStatus.fromStorageString(state['status'] as String?),
      currentRetries: (state['retries'] as num?)?.toInt() ?? 0,
      group: data['group'] as String?,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is ZenTimestamp) return value.value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    // Handle Firestore timestampValue format directly if it leaks
    if (value is Map<String, dynamic> && value.containsKey('timestampValue')) {
      return DateTime.tryParse(value['timestampValue'] as String);
    }
    return null;
  }
}
