import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class ConfigService {
  static final Map<String, dynamic> _cache = {};

  Future<List<String>> getDefaultUserGoals() async {
    return AppConstants.defaultUserGoals;
  }

  Future<List<String>> getEmotionFactors() async {
    return AppConstants.emotionFactors;
  }

  Future<List<Map<String, dynamic>>> getMoodLevels() async {
    return [
      {'level': 1, 'emoji': '😞', 'label': 'Very Poor'},
      {'level': 2, 'emoji': '😕', 'label': 'Poor'},
      {'level': 3, 'emoji': '😐', 'label': 'Okay'},
      {'level': 4, 'emoji': '🙂', 'label': 'Good'},
      {'level': 5, 'emoji': '😄', 'label': 'Excellent'},
    ];
  }

  Future<Map<String, dynamic>> getAppSettings() async {
    return _getDefaultSettings();
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'minPasswordLength': AppConstants.minPasswordLength,
      'enableSocialLogin': true,
      'enablePushNotifications': true,
      'streakReminderTime': '20:00',
      'maxMoodEntriesPerDay': 10,
    };
  }

  Future<T> getCachedConfig<T>(String key, Future<T> Function() fetcher) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }
    final value = await fetcher();
    _cache[key] = value;
    return value;
  }

  void clearCache() {
    _cache.clear();
    debugPrint('ConfigService cache cleared');
  }
}
