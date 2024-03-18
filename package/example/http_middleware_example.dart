import 'package:http/http.dart' as http;
import 'package:http_middleware/http_middleware.dart';

class HttpTrace extends HttpMiddleware {
  HttpTrace();

  @override
  Future<http.BaseRequest> onRequest(http.BaseRequest request) async {
    print('Request: $request');
    return request;
  }

  @override
  Future<http.StreamedResponse> onResponse(http.StreamedResponse response) async {
    print('''Response:
  ${response.statusCode} ${response.reasonPhrase}
  Headers:
    ${response.headers}
  Content length: ${response.contentLength} bytes
''');
    return response;
  }
}

Future<void> main() async {
  final client = HttpMiddlewareClient(
    http.Client(),
    middleware: [HttpTrace()],
  );

  var response = await client.get(Uri.parse('https://httpbin.org/get'));
  print('Response body: ${response.body}');
}
