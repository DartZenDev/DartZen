import 'package:dartzen_jobs/src/job_store.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:mocktail/mocktail.dart';

class MockJobStore extends Mock implements JobStore {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

class MockTelemetryEvent extends Mock implements TelemetryEvent {}
