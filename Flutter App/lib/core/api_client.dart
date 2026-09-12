import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'app_constants.dart';
import 'api_error_parser.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      baseUrl = baseUrl ?? AppConstants.baseUrl;

  final http.Client _httpClient;
  final String baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: _jsonHeaders(headers),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeMapResponse(response);
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.get(
      _uri(path, queryParameters),
      headers: _jsonHeaders(headers),
    );
    return _decodeResponse(response);
  }

  Future<Uint8List> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.get(
      _uri(path, queryParameters),
      headers: _jsonHeaders(headers),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromDetails(
        ApiErrorParser.parse(
          body: response.body,
          statusCode: response.statusCode,
        ),
      );
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.put(
      _uri(path),
      headers: _jsonHeaders(headers),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decodeMapResponse(response);
  }

  Future<dynamic> delete(String path, {Map<String, String>? headers}) async {
    final response = await _httpClient.delete(
      _uri(path),
      headers: _jsonHeaders(headers),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> sendMultipart(
    String path, {
    required String method,
    required Map<String, String> fields,
    Map<String, String>? headers,
    Uint8List? fileBytes,
    String? fileName,
    String fileField = 'imageFile',
    String? contentType,
  }) async {
    final request = http.MultipartRequest(method, _uri(path))
      ..headers.addAll(headers ?? const <String, String>{})
      ..fields.addAll(fields);

    if (fileBytes != null && fileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
          contentType: contentType == null
              ? null
              : MediaType.parse(contentType),
        ),
      );
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeMapResponse(response);
  }

  Map<String, String> _jsonHeaders(Map<String, String>? headers) {
    return <String, String>{'Content-Type': 'application/json', ...?headers};
  }

  Map<String, dynamic> _decodeMapResponse(http.Response response) {
    final decoded = _decodeResponse(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(message: 'Unexpected response format.');
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromDetails(
        ApiErrorParser.parse(
          body: response.body,
          statusCode: response.statusCode,
        ),
      );
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      return response.body;
    }
  }

  String normalizeImageUrl(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return '';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final normalized = value.replaceAll('\\', '/');
    if (normalized.startsWith('/')) {
      return '$baseUrl$normalized';
    }
    return '$baseUrl/$normalized';
  }
}
