import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _BaseRequestFake extends Fake implements http.BaseRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(_BaseRequestFake());
  });
}
