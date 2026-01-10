// ignore_for_file: avoid_print

import 'package:dartzen_firestore/dartzen_firestore.dart';
import 'package:dartzen_jobs/dartzen_jobs.dart';

/// Example demonstrating dartzen_jobs usage with local simulation.
Future<void> main() async {
  print('\n=== dartzen_jobs Example ===\n');

  // 1. Initialize dependencies
  // We use Firestore simulation mode for this example
  final firestoreConfig = FirestoreConfig(projectId: 'dev-project');

  try {
    await FirestoreConnection.initialize(firestoreConfig);
    print(
        '✅ Firestore initialized (Mode: ${firestoreConfig.isProduction ? "PROD" : "EMULATOR"})');
  } catch (e) {
    print('❌ Firestore init failed: $e');
    print('💡 Ensure simulated/emulator environment is ready.');
    // Proceeding might fail if Firestore is needed, but we simulate triggers mostly here.
  }

  // 2. Initialize ZenJobs
  // The serviceUrl matches where your server would be running.
  ZenJobs.instance = ZenJobs(
    projectId: 'dev-project',
    locationId: 'us-central1',
    queueId: 'default',
    serviceUrl: 'https://myservice.run.app',
  );
  print('✅ ZenJobs initialized\n');

  // 3. Define and Register Jobs

  // A. Endpoint Job (triggered manually)
  final emailJob = JobDefinition(
    id: 'send_email',
    type: JobType.endpoint,
    handler: (context) async {
      print(
          '📧 sending email to ${context.payload?['email']} (Attempt: ${context.attempt})');
      await Future<void>.delayed(
          const Duration(milliseconds: 100)); // Simulate work
    },
  );

  // B. Periodic Job (interval based)
  final cleanupJob = JobDefinition(
    id: 'cleanup_temp',
    type: JobType.periodic,
    defaultInterval: const Duration(minutes: 60),
    handler: (context) async {
      print('🧹 Cleaning up temporary files...');
    },
  );

  ZenJobs.instance.register(emailJob);
  ZenJobs.instance.register(cleanupJob);
  print('✅ Jobs registered: ${emailJob.id}, ${cleanupJob.id}\n');

  // 4. Trigger an Endpoint Job
  print('--- Triggering Endpoint Job ---');
  // This simulates enqueuing a task in Cloud Tasks.
  // In DEV mode (default here unless DZ_ENV=prd), it just logs the intent.
  await ZenJobs.instance.trigger(
    'send_email',
    payload: {'email': 'user@example.com'},
  );

  // 5. Simulate Handling a Request (Webhook)
  // This mimics what happens when Cloud Tasks actually calls your endpoint.
  print('\n--- Simulating Webhook Execution ---');
  final webhookBody = {
    'jobId': 'send_email',
    'payload': {'email': 'user@example.com'},
  };

  print('Incoming POST request: $webhookBody');
  final status = await ZenJobs.instance.handleRequest(webhookBody);
  print('Job execution status: $status ${status == 200 ? "OK" : "ERROR"}');

  print('\n=== Example Complete ===\n');
}
