import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register(String email, String password, String? name) async {
    final res = await ApiService.post('/auth/register', {
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
    }, auth: false);
    if (res['success'] == true && res['data'] != null) {
      final token = res['data']['token'] as String?;
      if (token != null) await ApiService.saveToken(token);
      return res['data'] as Map<String, dynamic>;
    }
    // Return the full response so caller can read the message
    return res;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    }, auth: false);
    if (res['success'] == true && res['data'] != null) {
      final token = res['data']['token'] as String?;
      if (token != null) await ApiService.saveToken(token);
      return res['data'] as Map<String, dynamic>;
    }
    // Return the full response so caller can read the message
    return res;
  }

  static Future<UserModel?> getMe() async {
    try {
      final res = await ApiService.get('/auth/me');
      if (res['success'] == true && res['data'] != null) {
        return UserModel.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  static Future<void> logout() async {
    await ApiService.deleteToken();
  }
}
