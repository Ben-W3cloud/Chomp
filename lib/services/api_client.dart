import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/env.dart';

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// Thin HTTP wrapper shared by every service. Owns the session token
/// (issued by OUR backend after GitHub OAuth — never the raw GitHub
/// token) and attaches it to every request.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'chomp_session_token';

  Future<String?> get sessionToken => _storage.read(key: _sessionKey);
  Future<void> setSessionToken(String token) =>
      _storage.write(key: _sessionKey, value: token);
  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  Uri _uri(String path) => Uri.parse('${Env.apiBaseUrl}$path');

  Future<Map<String, String>> _authHeaders() async {
    final token = await sessionToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: await _authHeaders());
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_uri(path),
        headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }

  /// Opens a Server-Sent Events connection — used only by [ScanEngine]
  /// for the live "Scan Again" phase log.
  Future<http.StreamedResponse> openStream(String path) async {
    final request = http.Request('POST', _uri(path));
    request.headers.addAll(await _authHeaders());
    request.headers['Accept'] = 'text/event-stream';
    final client = http.Client();
    return client.send(request);
  }
}
