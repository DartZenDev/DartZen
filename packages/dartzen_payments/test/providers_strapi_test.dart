import 'package:dartzen_payments/dartzen_payments.dart';
import 'package:dartzen_payments/src/http_client.dart';
import 'package:dartzen_payments/src/payment_http_response.dart';
import 'package:dartzen_payments/src/strapi/strapi_mapper.dart';
import 'package:dartzen_payments/src/strapi/strapi_models.dart';
import 'package:dartzen_payments/src/strapi/strapi_payments_service.dart';
import 'package:dartzen_telemetry/dartzen_telemetry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockPaymentsHttpClient extends Mock implements PaymentsHttpClient {}

class MockTelemetryClient extends Mock implements TelemetryClient {}

class FakeTelemetryEvent extends Fake implements TelemetryEvent {}

void main() {
  group('StrapiPaymentsService', () {
    late MockPaymentsHttpClient mockClient;
    late MockTelemetryClient mockTelemetry;
    late StrapiPaymentsService service;

    const config = StrapiPaymentsConfig(
      baseUrl: 'https://strapi.example.com',
      apiToken: 'test-token',
    );

    setUpAll(() {
      registerFallbackValue(FakeTelemetryEvent());
    });

    setUp(() {
      mockClient = MockPaymentsHttpClient();
      mockTelemetry = MockTelemetryClient();
      service = StrapiPaymentsService(
        config,
        client: mockClient,
        telemetry: mockTelemetry,
      );
    });

    group('createPayment', () {
      test('returns payment on success', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2000,
          currency: 'EUR',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        const response = PaymentHttpResponse(
          id: 'req-123',
          statusCode: 200,
          data: {
            'id': 'pay-strapi-1',
            'intent_id': 'intent-1',
            'status': 'succeeded',
            'amount_minor': 2000,
            'currency': 'EUR',
            'provider_reference': 'strapi-ref-123',
          },
        );

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => response);

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        final result = await service.createPayment(intent);

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.id, 'pay-strapi-1');
        expect(result.dataOrNull?.status, PaymentStatus.completed);
        expect(result.dataOrNull?.provider, 'strapi');

        verify(() => mockTelemetry.emitEvent(any())).called(1);
      });

      test('forwards idempotency key in request payload', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2000,
          currency: 'EUR',
          idempotencyKey: 'idem-unique-123',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 200,
            data: {
              'id': 'pay-1',
              'intent_id': 'intent-1',
              'status': 'succeeded',
              'amount_minor': 2000,
              'currency': 'EUR',
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        await service.createPayment(intent);

        verify(
          () => mockClient.post(
            any(),
            any(that: containsPair('idempotency_key', 'idem-unique-123')),
            headers: any(named: 'headers'),
          ),
        ).called(1);
      });

      test('includes description and metadata when provided', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2000,
          currency: 'EUR',
          idempotencyKey: 'idem-1',
          description: 'Order payment',
          metadata: {'orderId': '12345'},
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 200,
            data: {
              'id': 'pay-1',
              'intent_id': 'intent-1',
              'status': 'succeeded',
              'amount_minor': 2000,
              'currency': 'EUR',
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        await service.createPayment(intent);

        final capturedPayload =
            verify(
                  () => mockClient.post(
                    any(),
                    captureAny(),
                    headers: any(named: 'headers'),
                  ),
                ).captured.last
                as Map<String, dynamic>;

        expect(capturedPayload['description'], 'Order payment');
        expect(capturedPayload['metadata'], {'orderId': '12345'});
      });

      test('returns error on 400 invalid amount', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2000,
          currency: 'EUR',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 400,
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
          amountMinor: 2000,
          currency: 'EUR',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 402,
            error: 'Insufficient funds',
          ),
        );

        final result = await service.createPayment(intent);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentInsufficientFundsError>());
      });

      test('returns error on 404', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2000,
          currency: 'EUR',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 404,
            error: 'Not found',
          ),
        );

        final result = await service.createPayment(intent);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentNotFoundError>());
      });

      test('returns error on 409 state conflict', () async {
        final intent = PaymentIntent.create(
          id: 'intent-1',
          amountMinor: 2000,
          currency: 'EUR',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 409,
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
          amountMinor: 2000,
          currency: 'EUR',
          idempotencyKey: 'idem-1',
        ).dataOrNull!;

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 500,
            error: 'Server error',
          ),
        );

        final result = await service.createPayment(intent);

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentProviderError>());
      });
    });

    group('confirmPayment', () {
      test('returns confirmed payment on success', () async {
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 200,
            data: {
              'id': 'pay-1',
              'intent_id': 'intent-1',
              'status': 'completed',
              'amount_minor': 2000,
              'currency': 'EUR',
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        final result = await service.confirmPayment('pay-1');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.status, PaymentStatus.completed);
      });

      test('returns error on 404', () async {
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 404,
            error: 'Payment not found',
          ),
        );

        final result = await service.confirmPayment('invalid-id');

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<PaymentNotFoundError>());
      });

      test('sends confirmation data to endpoint', () async {
        final confirmationData = {'verified': true};

        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 200,
            data: {
              'id': 'pay-1',
              'intent_id': 'intent-1',
              'status': 'completed',
              'amount_minor': 2000,
              'currency': 'EUR',
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

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
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 200,
            data: {
              'id': 'pay-1',
              'intent_id': 'intent-1',
              'status': 'refunded',
              'amount_minor': 2000,
              'currency': 'EUR',
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        final result = await service.refundPayment('pay-1');

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.status, PaymentStatus.refunded);
      });

      test('returns error on 404', () async {
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 404,
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
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 200,
            data: {
              'id': 'pay-1',
              'intent_id': 'intent-1',
              'status': 'refunded',
              'amount_minor': 2000,
              'currency': 'EUR',
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        await service.refundPayment('pay-1', reason: 'Cancellation');

        verify(
          () => mockClient.post(
            any(),
            any(that: containsPair('reason', 'Cancellation')),
            headers: any(named: 'headers'),
          ),
        ).called(1);
      });

      test('sends null when no reason provided', () async {
        when(
          () => mockClient.post(any(), any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => const PaymentHttpResponse(
            id: 'req-123',
            statusCode: 200,
            data: {
              'id': 'pay-1',
              'intent_id': 'intent-1',
              'status': 'refunded',
              'amount_minor': 2000,
              'currency': 'EUR',
            },
          ),
        );

        when(() => mockTelemetry.emitEvent(any())).thenAnswer((_) async {});

        await service.refundPayment('pay-1');

        final capturedArgs = verify(
          () => mockClient.post(
            any(),
            captureAny(),
            headers: any(named: 'headers'),
          ),
        ).captured.last;

        expect(capturedArgs, isNull);
      });
    });

    group('StrapiPaymentMapper', () {
      test('maps Strapi succeeded response to payment', () {
        const mapper = StrapiPaymentMapper();
        final model = StrapiPaymentModel(
          id: 'pay-123',
          intentId: 'intent-456',
          status: 'succeeded',
          amountMinor: 3000,
          currency: 'GBP',
          providerReference: 'strapi-ref-789',
          createdAt: DateTime.now().toUtc(),
        );

        final payment = mapper.toDomain(model: model);

        expect(payment.id, 'pay-123');
        expect(payment.intentId, 'intent-456');
        expect(payment.provider, 'strapi');
        expect(payment.status, PaymentStatus.completed);
        expect(payment.providerReference, 'strapi-ref-789');
      });

      test('maps Strapi pending response', () {
        const mapper = StrapiPaymentMapper();
        final model = StrapiPaymentModel(
          id: 'pay-123',
          intentId: 'intent-456',
          status: 'pending',
          amountMinor: 3000,
          currency: 'GBP',
          createdAt: DateTime.now().toUtc(),
        );

        final payment = mapper.toDomain(model: model);

        expect(payment.status, PaymentStatus.pending);
      });

      test('maps Strapi processing response', () {
        const mapper = StrapiPaymentMapper();
        final model = StrapiPaymentModel(
          id: 'pay-123',
          intentId: 'intent-456',
          status: 'processing',
          amountMinor: 3000,
          currency: 'GBP',
          createdAt: DateTime.now().toUtc(),
        );

        final payment = mapper.toDomain(model: model);

        expect(payment.status, PaymentStatus.initiated);
      });

      test('maps Strapi failed response', () {
        const mapper = StrapiPaymentMapper();
        final model = StrapiPaymentModel(
          id: 'pay-123',
          intentId: 'intent-456',
          status: 'failed',
          amountMinor: 3000,
          currency: 'GBP',
          createdAt: DateTime.now().toUtc(),
        );

        final payment = mapper.toDomain(model: model);

        expect(payment.status, PaymentStatus.failed);
      });

      test('maps Strapi refunded response', () {
        const mapper = StrapiPaymentMapper();
        final model = StrapiPaymentModel(
          id: 'pay-123',
          intentId: 'intent-456',
          status: 'refunded',
          amountMinor: 3000,
          currency: 'GBP',
          createdAt: DateTime.now().toUtc(),
        );

        final payment = mapper.toDomain(model: model);

        expect(payment.status, PaymentStatus.refunded);
      });
    });

    group('close', () {
      test('closes owned client when created internally', () {
        final internalService = StrapiPaymentsService(
          config,
          telemetry: mockTelemetry,
        );

        expect(internalService.close, returnsNormally);
      });

      test('does not close client when injected', () {
        final injectedService = StrapiPaymentsService(
          config,
          client: mockClient,
          telemetry: mockTelemetry,
        );

        expect(injectedService.close, returnsNormally);
      });
    });
  });
}
