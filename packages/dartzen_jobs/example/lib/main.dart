// Simple example showing descriptor registration, handler registration,
// and executing a job via `TestExecutor` for local development.

import 'package:dartzen_jobs/dartzen_jobs.dart';

// ignore_for_file: avoid_print

Future<void> main() async {
  // Initialize registry
  ZenJobs.instance = ZenJobs();

  const emailDesc =
      JobDescriptor(id: 'send_welcome_email', type: JobType.endpoint);
  const cleanupDesc = JobDescriptor(
      id: 'cleanup_temp_files',
      type: JobType.periodic,
      defaultInterval: Duration(hours: 1));

  ZenJobs.instance.register(emailDesc);
  ZenJobs.instance.register(cleanupDesc);

  // Register handlers separately
  HandlerRegistry.register(emailDesc.id, (ctx) async {
    print(
        'Sending welcome email to ${ctx.payload?['email']} (attempt=${ctx.attempt})');
  });

  HandlerRegistry.register(cleanupDesc.id, (ctx) async {
    print('Running periodic cleanup (attempt=${ctx.attempt})');
  });

  // Use TestExecutor for local simulation
  final executor = TestExecutor();
  await executor.start();

  print('Scheduling email job via TestExecutor');
  await executor.schedule(emailDesc, payload: {'email': 'user@example.com'});

  await executor.shutdown();
}
