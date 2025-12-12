// ignore_for_file: avoid_print

import 'package:dartzen_server_transport/dartzen_server_transport.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() async {
  final handler = const Pipeline()
      .addMiddleware(transportMiddleware())
      .addMiddleware(logRequests())
      .addHandler(_handleRequest);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Server running on http://${server.address.host}:${server.port}');
  print(
    'Try: curl -X POST http://localhost:8080 -H "Content-Type: application/json" -d \'{"name":"Alice"}\'',
  );
}

Response _handleRequest(Request request) {
  final format = request.context['transport_format'] as ZenTransportFormat;
  final data = request.context['decoded_data'];

  print('Received data: $data');
  print('Format: ${format.value}');

  return zenResponse(200, {
    'message': 'Hello from DartZen!',
    'received': data,
    'format': format.value,
    'timestamp': DateTime.now().toIso8601String(),
  });
}
