// ignore_for_file: avoid_print

import 'package:dartzen_client_transport/dartzen_client_transport.dart';

void main() async {
  // Create client
  final client = ZenClient(baseUrl: 'http://localhost:8080');

  try {
    // POST request
    print('Creating user...');
    final user = await client.post('/api/users', {
      'name': 'Alice',
      'email': 'alice@example.com',
    });
    print('Created: $user');

    // GET request
    print('\nFetching users...');
    final users = await client.get('/api/users');
    print('Users: $users');

    // PUT request
    print('\nUpdating user...');
    final updated = await client.put('/api/users/1', {'name': 'Alice Updated'});
    print('Updated: $updated');

    // DELETE request
    print('\nDeleting user...');
    await client.delete('/api/users/1');
    print('Deleted successfully');
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
