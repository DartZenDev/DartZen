import 'package:dartzen_payments/src/payment_http_response.dart';
import 'package:test/test.dart';

void main() {
  test('isSuccess and isError flags and toString', () {
    const ok = PaymentHttpResponse(id: '1', statusCode: 200, data: {'a': 1});
    expect(ok.isSuccess, isTrue);
    expect(ok.isError, isFalse);

    const err = PaymentHttpResponse(id: '2', statusCode: 404, error: 'not');
    expect(err.isSuccess, isFalse);
    expect(err.isError, isTrue);

    expect(ok.toString(), contains('PaymentHttpResponse'));
  });

  test('deep equality and hashCode for nested maps', () {
    const a = PaymentHttpResponse(
      id: 'x',
      statusCode: 200,
      data: {
        'k': {'n': 1},
      },
    );
    const b = PaymentHttpResponse(
      id: 'x',
      statusCode: 200,
      data: {
        'k': {'n': 1},
      },
    );
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });
}
