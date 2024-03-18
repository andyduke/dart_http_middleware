import 'package:http/http.dart' as http;
import 'package:http_middleware/src/http_middleware.dart';

class HttpMiddlewareClient extends http.BaseClient {
  final http.Client client;
  final List<HttpMiddleware> middleware;

  HttpMiddlewareClient(
    this.client, {
    this.middleware = const [],
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (middleware.isEmpty) {
      return send(request);
    } else {
      http.BaseRequest httpRequest = request;

      for (var handler in middleware) {
        httpRequest = await handler.onRequest(httpRequest);
      }

      http.StreamedResponse response = await client.send(httpRequest);

      for (var handler in middleware) {
        response = await handler.onResponse(response);
      }

      return response;
    }
  }
}
