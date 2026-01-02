import 'package:dartzen_demo_contracts/dartzen_demo_contracts.dart';
import 'package:test/test.dart';

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
      final json = {'content': '<h1>Terms</h1>', 'content_type': 'text/html'};

      final contract = TermsContract.fromJson(json);

      expect(contract.content, '<h1>Terms</h1>');
      expect(contract.contentType, 'text/html');
    });
  });

  group('WebSocketMessageContract', () {
    test('serializes to JSON correctly', () {
      const contract = WebSocketMessageContract(type: 'echo', payload: 'Hello');

      final json = contract.toJson();

      expect(json['type'], 'echo');
      expect(json['payload'], 'Hello');
    });

    test('deserializes from JSON correctly', () {
      final json = {'type': 'echo', 'payload': 'Hello'};

      final contract = WebSocketMessageContract.fromJson(json);

      expect(contract.type, 'echo');
      expect(contract.payload, 'Hello');
    });
  });

  group('LoginRequestContract', () {
    test('serializes to JSON correctly', () {
      const contract = LoginRequestContract(
        email: 'user@example.com',
        password: 'secret123',
      );

      final json = contract.toJson();

      expect(json['email'], 'user@example.com');
      expect(json['password'], 'secret123');
    });

    test('deserializes from JSON correctly', () {
      final json = {'email': 'user@example.com', 'password': 'secret123'};

      final contract = LoginRequestContract.fromJson(json);

      expect(contract.email, 'user@example.com');
      expect(contract.password, 'secret123');
    });
  });

  group('LoginResponseContract', () {
    test('serializes to JSON correctly', () {
      const contract = LoginResponseContract(
        idToken: 'token-xyz',
        userId: 'user-456',
      );

      final json = contract.toJson();

      expect(json['idToken'], 'token-xyz');
      expect(json['userId'], 'user-456');
    });

    test('deserializes from JSON correctly', () {
      final json = {'idToken': 'token-xyz', 'userId': 'user-456'};

      final contract = LoginResponseContract.fromJson(json);

      expect(contract.idToken, 'token-xyz');
      expect(contract.userId, 'user-456');
    });
  });

  group('ProfileContract', () {
    test('deserializes from JSON without bio', () {
      final json = {
        'user_id': 'user-123',
        'display_name': 'Test User',
        'email': 'demo@example.com',
        'bio': null,
      };

      final contract = ProfileContract.fromJson(json);

      expect(contract.bio, isNull);
    });

    test('toJson includes null bio when bio is null', () {
      const contract = ProfileContract(
        userId: 'user-123',
        displayName: 'Test User',
        email: 'demo@example.com',
      );

      final json = contract.toJson();

      expect(json['bio'], isNull);
    });
  });

  group('ProfileSummaryContract', () {
    test('serializes to JSON correctly with all fields', () {
      const contract = ProfileSummaryContract(
        id: 'summary-123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
      );

      final json = contract.toJson();

      expect(json['id'], 'summary-123');
      expect(json['email'], 'test@example.com');
      expect(json['display_name'], 'Test User');
      expect(json['photo_url'], 'https://example.com/photo.jpg');
    });

    test('deserializes from JSON correctly with all fields', () {
      final json = {
        'id': 'summary-123',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'photo_url': 'https://example.com/photo.jpg',
      };

      final contract = ProfileSummaryContract.fromJson(json);

      expect(contract.id, 'summary-123');
      expect(contract.email, 'test@example.com');
      expect(contract.displayName, 'Test User');
      expect(contract.photoUrl, 'https://example.com/photo.jpg');
    });

    test('serializes to JSON correctly with optional fields as null', () {
      const contract = ProfileSummaryContract(
        id: 'summary-123',
        email: 'test@example.com',
      );

      final json = contract.toJson();

      expect(json['id'], 'summary-123');
      expect(json['email'], 'test@example.com');
      expect(json['display_name'], isNull);
      expect(json['photo_url'], isNull);
    });

    test('deserializes from JSON correctly with optional fields as null', () {
      final json = {
        'id': 'summary-123',
        'email': 'test@example.com',
        'display_name': null,
        'photo_url': null,
      };

      final contract = ProfileSummaryContract.fromJson(json);

      expect(contract.id, 'summary-123');
      expect(contract.email, 'test@example.com');
      expect(contract.displayName, isNull);
      expect(contract.photoUrl, isNull);
    });
  });
}
