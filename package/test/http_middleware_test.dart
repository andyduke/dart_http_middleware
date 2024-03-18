import 'package:http_middleware/http_middleware.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

class HttpRequestInfo /*with ChangeNotifier*/ {
  final http.BaseRequest request;

  http.StreamedResponse? get response => _response;
  http.StreamedResponse? _response;
  set response(http.StreamedResponse? newValue) {
    if (_response != newValue) {
      _response = newValue;
      // notifyListeners();
    }
  }

  HttpRequestInfo({
    required this.request,
    http.StreamedResponse? response,
  }) : _response = response;

  @override
  bool operator ==(covariant HttpRequestInfo other) => request.hashCode == other.request.hashCode;

  @override
  int get hashCode => request.hashCode;

  @override
  String toString() => '''HttpRequestInfo:
  request: $request
  response: $response
''';
}

class HttpLogController /*with ChangeNotifier*/ {
  final Set<HttpRequestInfo> _log = {};

  HttpLogController();

  Set<HttpRequestInfo> get log => UnmodifiableSetView(_log);

  void addRequest(http.BaseRequest request) {
    _log.add(HttpRequestInfo(request: request));
    // notifyListeners();
  }

  void addResponse(http.StreamedResponse response) {
    final request = _log.firstWhereOrNull((info) => info.request == response.request);
    if (request != null) {
      request.response = response;
      // notifyListeners();
    } else {
      throw Exception('[HttpLogController] Request "${response.request}" for response not found.');
    }
  }
}

class HttpLogInterceptor extends HttpMiddleware {
  final HttpLogController log;

  HttpLogInterceptor({
    required this.log,
  });

  @override
  Future<http.BaseRequest> onRequest(http.BaseRequest request) async {
    log.addRequest(request);
    return request;
  }

  @override
  Future<http.StreamedResponse> onResponse(http.StreamedResponse response) async {
    log.addResponse(response);
    return response;
  }
}

void main() {
  test('Simple test', () async {
    final httpLog = HttpLogController();
    final client = HttpMiddlewareClient(
      http.Client(),
      middleware: [HttpLogInterceptor(log: httpLog)],
    );

    var response = await client.get(Uri.parse('https://httpbin.org/get'));

    expect(response.statusCode, equals(200));
    expect(httpLog.log.length, equals(1));

    print('${httpLog.log}');
  });

  test('Request & Response log', () async {
    final httpLog = HttpLogController();
    final client = HttpMiddlewareClient(
      http.Client(),
      middleware: [HttpLogInterceptor(log: httpLog)],
    );

    var request = http.Request('get', Uri.parse('https://httpbin.org/delay/1'));
    var responseFuture = client.send(request);

    expect(httpLog.log.length, equals(1));
    expect(httpLog.log.first.request, equals(request));
    expect(httpLog.log.first.response, isNull);

    var response = await responseFuture;

    expect(response.statusCode, equals(200));
    expect(httpLog.log.length, equals(1));
    expect(httpLog.log.first.request, equals(request));
    expect(httpLog.log.first.response, equals(response));

    print('${httpLog.log}');
  });
}
