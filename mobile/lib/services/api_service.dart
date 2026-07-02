import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static const _storage  = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _timeout  = Duration(seconds: 30);

  static Future<String?> getToken()              => _storage.read(key: _tokenKey);
  static Future<void>    saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  static Future<void>    deleteToken()           => _storage.delete(key: _tokenKey);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── Core: single request with timeout ───────────────────────────────────────
  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() fn, {
    int maxRetries = 2,
  }) async {
    Exception? lastErr;
    for (int i = 0; i <= maxRetries; i++) {
      try {
        final res = await fn().timeout(_timeout);
        return _parse(res);
      } on TimeoutException catch (e) {
        lastErr = e;
        if (i < maxRetries) await Future.delayed(Duration(milliseconds: 700 * (i + 1)));
      } on SocketException catch (e) {
        lastErr = e;
        if (i < maxRetries) await Future.delayed(Duration(milliseconds: 700 * (i + 1)));
      } on HandshakeException catch (e) {
        // SSL errors — don't retry
        return {'success': false, 'message': 'خطأ في الاتصال الآمن (SSL)', '_statusCode': 0};
      } catch (e) {
        return {'success': false, 'message': 'خطأ غير متوقع: $e', '_statusCode': 0};
      }
    }
    final msg = lastErr is TimeoutException
        ? 'انتهت مهلة الاتصال، تحقق من الإنترنت وأعد المحاولة'
        : 'لا يوجد اتصال بالإنترنت';
    return {'success': false, 'message': msg, '_statusCode': 0};
  }

  static Map<String, dynamic> _parse(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return {...data, '_statusCode': res.statusCode};
    } catch (_) {
      return {
        'success': false,
        'message': 'استجابة غير صالحة من السيرفر (${res.statusCode})',
        '_statusCode': res.statusCode,
      };
    }
  }

  // ── Public methods ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    final h = await _headers(auth: auth);
    return _send(() => http.get(Uri.parse('${AppConfig.apiUrl}$path'), headers: h));
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final h = await _headers(auth: auth);
    return _send(
      () => http.post(Uri.parse('${AppConfig.apiUrl}$path'), headers: h, body: jsonEncode(body)),
      maxRetries: 1,
    );
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final h = await _headers(auth: auth);
    return _send(
      () => http.put(Uri.parse('${AppConfig.apiUrl}$path'), headers: h, body: jsonEncode(body)),
      maxRetries: 1,
    );
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final h = await _headers(auth: auth);
    return _send(
      () => http.patch(Uri.parse('${AppConfig.apiUrl}$path'), headers: h, body: jsonEncode(body)),
      maxRetries: 1,
    );
  }

  static Future<Map<String, dynamic>> delete(String path, {bool auth = true}) async {
    final h = await _headers(auth: auth);
    return _send(() => http.delete(Uri.parse('${AppConfig.apiUrl}$path'), headers: h));
  }
}
