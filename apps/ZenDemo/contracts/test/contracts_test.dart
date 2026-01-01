import 'package:test/test.dart';
import 'package:zen_demo_contracts/zen_demo_contracts.dart';

void main() {
  group('PingContract', () {
    test('serializes to JSON correctly', () {
      const contract = PingContract(
        message: 'Server is alive',
        timestamp: '2025-12-31T12:00:00Z',
      );

      final json = contract.toJson();

      expect(json['message'], 'Server is alive');
      expect(json['timestamp'], '2025-12-31T12:00:00Z');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'message': 'Server is alive',
        'timestamp': '2025-12-31T12:00:00Z',
      };

      final contract = PingContract.fromJson(json);

      expect(contract.message, 'Server is alive');
      expect(contract.timestamp, '2025-12-31T12:00:00Z');
    });
  });

  group('ProfileContract', () {
    test('serializes to JSON correctly', () {
      const contract = ProfileContract(
        userId: 'user-123',
        displayName: 'Test User',
        email: 'demo@example.com',
        bio: 'Test bio',
      );

      final json = contract.toJson();

      expect(json['user_id'], 'user-123');
      expect(json['display_name'], 'Test User');
      expect(json['email'], 'demo@example.com');
      expect(json['bio'], 'Test bio');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'user_id': 'user-123',
        'display_name': 'Test User',
        'email': 'demo@example.com',
        'bio': 'Test bio',
      };

      final contract = ProfileContract.fromJson(json);

      expect(contract.userId, 'user-123');
      expect(contract.displayName, 'Test User');
      expect(contract.email, 'demo@example.com');
      expect(contract.bio, 'Test bio');
    });
  });

  group('TermsContract', () {
    test('serializes to JSON correctly', () {
      const contract = TermsContract(
        content: '<h1>Terms</h1>',
        contentType: 'text/html',
      );

      final json = contract.toJson();

      expect(json['content'], '<h1>Terms</h1>');
      expect(json['content_type'], 'text/html');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'content': '<h1>Terms</h1>',
        'content_type': 'text/html',
      };

      final contract = TermsContract.fromJson(json);

      expect(contract.content, '<h1>Terms</h1>');
      expect(contract.contentType, 'text/html');
    });
  });

  group('WebSocketMessageContract', () {
    test('serializes to JSON correctly', () {
      const contract = WebSocketMessageContract(
        type: 'echo',
        payload: 'Hello',
      );

      final json = contract.toJson();

      expect(json['type'], 'echo');
      expect(json['payload'], 'Hello');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'type': 'echo',
        'payload': 'Hello',
      };

      final contract = WebSocketMessageContract.fromJson(json);

      expect(contract.type, 'echo');
      expect(contract.payload, 'Hello');
    });
  });
}
