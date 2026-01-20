import 'package:dartzen_payments/dartzen_payments.dart';
import 'package:dartzen_payments/src/adyen/adyen_mapper.dart';
import 'package:dartzen_payments/src/adyen/adyen_models.dart';
import 'package:dartzen_payments/src/adyen/adyen_payments_service.dart';
import 'package:dartzen_payments/src/http_client.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockPaymentsHttpClient extends Mock implements PaymentsHttpClient {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

class FakeTelemetryEvent extends Fake implements TelemetryEvent {}

void main() {
  group('AdyenPaymentsService', () {
    late MockPaymentsHttpClient mockClient;
    late MockTelemetryClient mockTelemetry;
    late AdyenPaymentsService service;

    const config = AdyenPaymentsConfig(
      baseUrl: 'https://api.adyen.com',
      apiKey: 'test-key',
      merchantAccount: 'test-merchant',
    );

    setUpAll(() {
      registerFallbackValue(FakeTelemetryEvent());
    });

    setUp(() {
      mockClient = MockPaymentsHttpClient();
      mockTelemetry = MockTelemetryClient();
      service = AdyenPaymentsService(
        config,
        client: mockClient,
        telemetry: mockTelemetry,
      );
    });

    group('createPayment', () {
      test('returns payment on success', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 1000,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        const response = ZenResponse(
          id: 'req-123',
          status: 200,
          data: {
            'paymentId': 'pay-adyen-1',
            'intentId': 'intent-1',
            'resultCode': 'Authorised',
            'amount': {'value': 1000, 'currency': 'USD'},
            'pspReference': 'psp-123',
          },
        );

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => response);

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        final result = await service.createPayment(intent);

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.id, 'pay-adyen-1');
        expect(result.dataOrNull?.status, PaymentStatus.confirmed);
        expect(result.dataOrNull?.provider, 'adyen');

        verify(() => mockTelemetry.emitEvent(any())).called(1);
      });

      test('returns error on 400 invalid amount', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 1000,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 400,
            error: 'Invalid amount',
          ),
        );

        final result = await service.createPayment(intent);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentInvalidAmountError>());
      });

      test('returns error on 402 insufficient funds', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 1000,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 402,
            error: 'Insufficient funds',
          ),
        );

        final result = await service.createPayment(intent);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentInsufficientFundsError>());
      });

      test('returns error on 404 payment not found', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 1000,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 404,
            error: 'Payment not found',
          ),
        );

        final result = await service.createPayment(intent);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentNotFoundError>());
      });

      test('returns error on 409 state conflict', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 1000,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 409,
            error: 'Invalid state',
          ),
        );

        final result = await service.createPayment(intent);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentStateError>());
      });

      test('returns generic provider error on 500', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 1000,
          currency: 'USD',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 500,
            error: 'Server error',
          ),
        );

        final result = await service.createPayment(intent);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentProviderError>());
      });

      test('includes idempotency key in request headers', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 1000,
          currency: 'USD',
          idempotencyKey: 'idem-abc123',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 200,
            data: {
              'paymentId': 'pay-1',
              'intentId': 'intent-1',
              'resultCode': 'Authorised',
              'amount': {'value': 1000, 'currency': 'USD'},
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        await service.createPayment(intent);

        verify(
          () => mockClient.post(
            any(),
            any(),
            headers: captureAny(named: 'headers'),
          ),
        ).called(1);
      });
    });

    group('confirmPayment', () {
      test('returns payment on success', () async {
        const response = ZenResponse(
          id: 'req-123',
          status: 200,
          data: {
            'paymentId': 'pay-1',
            'intentId': 'intent-1',
            'resultCode': 'Captured',
            'amount': {'value': 1000, 'currency': 'USD'},
          },
        );

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => response);

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        final result = await service.confirmPayment('pay-1');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.status, PaymentStatus.completed);
      });

      test('returns error on 404', () async {
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 404,
            error: 'Payment not found',
          ),
        );

        final result = await service.confirmPayment('invalid-id');

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentNotFoundError>());
      });

      test('includes confirmation data in request', () async {
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 200,
            data: {
              'paymentId': 'pay-1',
              'intentId': 'intent-1',
              'resultCode': 'Captured',
              'amount': {'value': 1000, 'currency': 'USD'},
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        final confirmationData = {'threeDSData': 'abc123'};
        await service.confirmPayment(
          'pay-1',
          confirmationData: confirmationData,
        );

        verify(
          () => mockClient.post(
            any(),
            confirmationData,
            headers: any(named: 'headers'),
          ),
        ).called(1);
      });
    });

    group('refundPayment', () {
      test('returns refunded payment on success', () async {
        const response = ZenResponse(
          id: 'req-123',
          status: 200,
          data: {
            'paymentId': 'pay-1',
            'intentId': 'intent-1',
            'resultCode': 'Refunded',
            'amount': {'value': 1000, 'currency': 'USD'},
          },
        );

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => response);

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        final result = await service.refundPayment('pay-1');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.status, PaymentStatus.refunded);
      });

      test('returns error on 404', () async {
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 404,
            error: 'Payment not found',
          ),
        );

        final result = await service.refundPayment('invalid-id');

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentNotFoundError>());
      });

      test('includes reason in request when provided', () async {
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const ZenResponse(
            id: 'req-123',
            status: 200,
            data: {
              'paymentId': 'pay-1',
              'intentId': 'intent-1',
              'resultCode': 'Refunded',
              'amount': {'value': 1000, 'currency': 'USD'},
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        await service.refundPayment('pay-1', reason: 'Customer request');

        verify(
          () => mockClient.post(
            any(),
            any(that: containsPair('reason', 'Customer request')),
            headers: any(named: 'headers'),
          ),
        ).called(1);
      });
    });

    group('AdyenPaymentMapper', () {
      test('maps Adyen successful response to payment', () {
        const mapper = AdyenPaymentMapper();
        final model = AdyenPaymentModel(
          paymentId: 'pay-123',
          intentId: 'intent-456',
          resultCode: 'Authorised',
          amountMinor: 5000,
          currency: 'EUR',
          pspReference: 'psp-abc',
          createdAt: DateTime.now().toUtc(),
        );

        final payment = mapper.toDomain(model);

        expect(payment.id, 'pay-123');
        expect(payment.intentId, 'intent-456');
        expect(payment.provider, 'adyen');
        expect(payment.status, PaymentStatus.confirmed);
        expect(payment.providerReference, 'psp-abc');
      });

      test('maps Adyen pending response', () {
        const mapper = AdyenPaymentMapper();
        final model = AdyenPaymentModel(
          paymentId: 'pay-123',
          intentId: 'intent-456',
          resultCode: 'Pending',
          amountMinor: 5000,
          currency: 'EUR',
          createdAt: DateTime.now().toUtc(),
        );

        final payment = mapper.toDomain(model);

        expect(payment.status, PaymentStatus.pending);
      });

      test('maps Adyen declined response', () {
        const mapper = AdyenPaymentMapper();
        final model = AdyenPaymentModel(
          paymentId: 'pay-123',
          intentId: 'intent-456',
          resultCode: 'Refused',
          amountMinor: 5000,
          currency: 'EUR',
          createdAt: DateTime.now().toUtc(),
        );

        final payment = mapper.toDomain(model);

        expect(payment.status, PaymentStatus.failed);
      });
    });

    group('close', () {
      test('closes owned client when created internally', () {
        final internalService = AdyenPaymentsService(
          config,
          telemetry: mockTelemetry,
        );

        expect(internalService.close, returnsNormally);
      });

      test('does not close client when injected', () {
        final injectedService = AdyenPaymentsService(
          config,
          client: mockClient,
          telemetry: mockTelemetry,
        );

        expect(injectedService.close, returnsNormally);
      });
    });
  });
}
