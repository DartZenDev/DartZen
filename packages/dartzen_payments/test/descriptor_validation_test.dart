import 'package:dartzen_payments/dartzen_payments.dart'
    show PaymentDescriptor, PaymentOperation, MissingDescriptorException;
import 'package:dartzen_payments/src/descriptor_helpers.dart';
import 'package:test/test.dart';

void main() {
  test('ensureValidDescriptor throws on null or empty id', () {
    expect(
      () => ensureValidDescriptor(null),
      throwsA(isA<MissingDescriptorException>()),
    );
    expect(
      () => ensureValidDescriptor(
        const PaymentDescriptor(id: '', operation: PaymentOperation.charge),
      ),
      throwsA(isA<MissingDescriptorException>()),
    );
  });

  test('ensureValidDescriptor accepts valid descriptor', () {
    expect(
      () => ensureValidDescriptor(
        const PaymentDescriptor(id: 'x', operation: PaymentOperation.charge),
      ),
      returnsNormally,
    );
  });
}
