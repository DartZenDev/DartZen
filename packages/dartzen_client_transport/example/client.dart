// ignore_for_file: avoid_print

import 'package:dartzen_client_transport/dartzen_client_transport.dart';
import 'package:dartzen_core/dartzen_core.dart';

void main() async {
  // Create client
  final client = ZenClient(baseUrl: 'http://localhost:8080');

  try {
    // POST request
    ZenLogger.instance.info('Creating user...');
    final user = await client.post('/api/users', {
      'name': 'Alice',
      'email': 'alice@example.com',
    });
    ZenLogger.instance.info('Created: $user');

    // GET request
    ZenLogger.instance.info('\nFetching users...');
    final users = await client.get('/api/users');
    ZenLogger.instance.info('Users: $users');

    // PUT request
    ZenLogger.instance.info('\nUpdating user...');
    final updated = await client.put('/api/users/1', {'name': 'Alice Updated'});
    ZenLogger.instance.info('Updated: $updated');

    // DELETE request
    ZenLogger.instance.info('\nDeleting user...');
    await client.delete('/api/users/1');
    ZenLogger.instance.info('Deleted successfully');
  } catch (e) {
    ZenLogger.instance.error('Error: $e');
  } finally {
    client.close();
  }
}
