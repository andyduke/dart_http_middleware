import 'package:http/http.dart' as http;

abstract class HttpMiddleware {
  Future<http.BaseRequest> onRequest(http.BaseRequest request);

  Future<http.StreamedResponse> onResponse(http.StreamedResponse response);
}
