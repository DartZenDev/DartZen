// Simple example showing descriptor registration, handler registration,
// and executing a job via the single public `ZenJobsExecutor` entry point.

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
    defaultInterval: Duration(hours: 1),
  );

  final jobs = ZenJobsExecutor.development();
  jobs.register(emailDesc);
  jobs.register(cleanupDesc);

  // Register handlers separately
  jobs.registerHandler(emailDesc.id, (ctx) async {
    print(
      'Sending welcome email to ${ctx.payload?['email']} '
      '(attempt=${ctx.attempt})',
    );
  });

  jobs.registerHandler(cleanupDesc.id, (ctx) async {
    print('Running periodic cleanup (attempt=${ctx.attempt})');
  });

  await jobs.start();

  print('Scheduling email job via development executor');
  await jobs.schedule(emailDesc, payload: {'email': 'user@example.com'});

  await jobs.shutdown();
}
