import 'package:dartzen_payments/dartzen_payments.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentError hierarchy', () {
    test('provider error carries metadata', () {
      const error = PaymentProviderError(
        'Provider failed',
        metadata: {'code': 'P001'},
      );
      expect(error.internalData?['code'], 'P001');
    });

    test('insufficient funds is PaymentError', () {
      const error = PaymentInsufficientFundsError();
      expect(error, isA<PaymentError>());
      expect(error.message, 'Insufficient funds');
    });
  });
}
