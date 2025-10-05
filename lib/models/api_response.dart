class ApiResponse {
  final int statusCode;
  final dynamic data;
  final Map<String, String> headers;
  ApiResponse({required this.statusCode, required this.data, required this.headers});
}
