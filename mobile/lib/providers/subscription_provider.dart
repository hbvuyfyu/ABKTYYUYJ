import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  Map<String, dynamic>? _activeSubscription;
  int _dailyUsed = 0;
  int _dailyLimit = 0;
  bool _isLoading = false;

  Map<String, dynamic>? get activeSubscription => _activeSubscription;
  int get dailyUsed => _dailyUsed;
  int get dailyLimit => _dailyLimit;
  bool get isLoading => _isLoading;
  bool get hasActive => _activeSubscription != null;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/users/profile');
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        _activeSubscription = data['subscription'] as Map<String, dynamic>?;
        _dailyUsed = (data['dailyOperationsUsed'] as int?) ?? 0;
        _dailyLimit = (data['dailyOperationsLimit'] as int?) ?? 0;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }
}
