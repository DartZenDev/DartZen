import 'package:dartzen_core/dartzen_core.dart';
import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:shelf/shelf.dart';

import '../zen_response_translator.dart';

/// Handler for health check requests.
class HealthHandler {
  /// Handles the health check request.
  static Response handle(Request request) {
    final format =
        request.context['transport_format'] as ZenTransportFormat? ??
        ZenTransportFormat.json;

    // Health check is a simple success result
    final result = ZenResult.ok({
      'status': 'ok',
      'timestamp': DateTime.now().toIso8601String(),
    });

    return ZenResponseTranslator.translate(
      result: result,
      requestId: 'health',
      format: format,
    );
  }
}
