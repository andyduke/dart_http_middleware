# HttpMiddleware

Makes it possible to add several middleware handlers to the [HTTP client](https://pub.dev/packages/http), for example to log requests and responses.

## Usage

An example of implementing a log of HTTP requests and responses:
```dart
class HttpRequestInfo with ChangeNotifier {
  final http.BaseRequest request;

  http.StreamedResponse? get response => _response;
  http.StreamedResponse? _response;
  set response(http.StreamedResponse? newValue) {
    if (_response != newValue) {
      _response = newValue;
      notifyListeners();
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

class HttpLogController with ChangeNotifier {
  final Set<HttpRequestInfo> _log = {};

  HttpLogController();

  Set<HttpRequestInfo> get log => UnmodifiableSetView(_log);

  void addRequest(http.BaseRequest request) {
    _log.add(HttpRequestInfo(request: request));
    notifyListeners();
  }

  void addResponse(http.StreamedResponse response) {
    final request = _log.firstWhereOrNull((info) => info.request == response.request);
    if (request != null) {
      request.response = response;
      notifyListeners();
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
```

...an example of using this HTTP request and response logger:
```dart
final httpLog = HttpLogController();
final client = HttpMiddlewareClient(
  http.Client(),
  middleware: [
    HttpLogInterceptor(log: httpLog),
  ],
);

var response = await client.get(Uri.parse('https://httpbin.org/get'));

print('${httpLog.log}');
```
