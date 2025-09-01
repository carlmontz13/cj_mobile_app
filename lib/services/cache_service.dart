import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static const String _userPreferencesKey = 'user_preferences';
  static const String _classCacheKey = 'class_cache';
  static const String _authCacheKey = 'auth_cache';
  static const String _settingsKey = 'app_settings';
  static const String _lastSyncKey = 'last_sync';
  static const String _searchHistoryKey = 'search_history';
  static const String _recentClassesKey = 'recent_classes';
  static const String _themePreferencesKey = 'theme_preferences';
  static const String _notificationsKey = 'notifications';
  static const String _offlineDataKey = 'offline_data';

  // Clear all cached data
  static Future<void> clearAllCache() async {
    try {
      print('CacheService: Starting cache clearing process...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all known cache keys
      await Future.wait([
        prefs.remove(_userPreferencesKey),
        prefs.remove(_classCacheKey),
        prefs.remove(_authCacheKey),
        prefs.remove(_settingsKey),
        prefs.remove(_lastSyncKey),
        prefs.remove(_searchHistoryKey),
        prefs.remove(_recentClassesKey),
        prefs.remove(_themePreferencesKey),
        prefs.remove(_notificationsKey),
        prefs.remove(_offlineDataKey),
      ]);

      // Clear all preferences (nuclear option)
      await prefs.clear();
      
      print('CacheService: All cache cleared successfully');
    } catch (e) {
      print('CacheService: Error clearing cache: $e');
      // Even if clearing fails, we should continue with logout
    }
  }

  // Clear user-specific cache
  static Future<void> clearUserCache() async {
    try {
      print('CacheService: Clearing user-specific cache...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Clear user-specific data
      await Future.wait([
        prefs.remove(_userPreferencesKey),
        prefs.remove(_classCacheKey),
        prefs.remove(_authCacheKey),
        prefs.remove(_searchHistoryKey),
        prefs.remove(_recentClassesKey),
        prefs.remove(_notificationsKey),
        prefs.remove(_offlineDataKey),
      ]);
      
      print('CacheService: User cache cleared successfully');
    } catch (e) {
      print('CacheService: Error clearing user cache: $e');
    }
  }

  // Clear class-related cache
  static Future<void> clearClassCache() async {
    try {
      print('CacheService: Clearing class cache...');
      
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.remove(_classCacheKey),
        prefs.remove(_recentClassesKey),
        prefs.remove(_searchHistoryKey),
      ]);
      
      print('CacheService: Class cache cleared successfully');
    } catch (e) {
      print('CacheService: Error clearing class cache: $e');
    }
  }

  // Clear authentication cache
  static Future<void> clearAuthCache() async {
    try {
      print('CacheService: Clearing auth cache...');
      
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.remove(_authCacheKey),
        prefs.remove(_userPreferencesKey),
      ]);
      
      print('CacheService: Auth cache cleared successfully');
    } catch (e) {
      print('CacheService: Error clearing auth cache: $e');
    }
  }

  // Save user preferences (for future use)
  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert map to string for storage
      final preferencesString = preferences.toString();
      await prefs.setString(_userPreferencesKey, preferencesString);
    } catch (e) {
      print('CacheService: Error saving user preferences: $e');
    }
  }

  // Get user preferences (for future use)
  static Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesString = prefs.getString(_userPreferencesKey);
      if (preferencesString != null) {
        // Parse string back to map (simplified implementation)
        return <String, dynamic>{}; // Placeholder for actual parsing
      }
      return null;
    } catch (e) {
      print('CacheService: Error getting user preferences: $e');
      return null;
    }
  }

  // Save class cache (for future use)
  static Future<void> saveClassCache(List<Map<String, dynamic>> classes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert list to string for storage
      final classesString = classes.toString();
      await prefs.setString(_classCacheKey, classesString);
    } catch (e) {
      print('CacheService: Error saving class cache: $e');
    }
  }

  // Get class cache (for future use)
  static Future<List<Map<String, dynamic>>?> getClassCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesString = prefs.getString(_classCacheKey);
      if (classesString != null) {
        // Parse string back to list (simplified implementation)
        return <Map<String, dynamic>>[]; // Placeholder for actual parsing
      }
      return null;
    } catch (e) {
      print('CacheService: Error getting class cache: $e');
      return null;
    }
  }

  // Save search history
  static Future<void> saveSearchHistory(List<String> searchTerms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, searchTerms);
    } catch (e) {
      print('CacheService: Error saving search history: $e');
    }
  }

  // Get search history
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      print('CacheService: Error getting search history: $e');
      return [];
    }
  }

  // Save recent classes
  static Future<void> saveRecentClasses(List<String> classIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentClassesKey, classIds);
    } catch (e) {
      print('CacheService: Error saving recent classes: $e');
    }
  }

  // Get recent classes
  static Future<List<String>> getRecentClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentClassesKey) ?? [];
    } catch (e) {
      print('CacheService: Error getting recent classes: $e');
      return [];
    }
  }

  // Save theme preferences
  static Future<void> saveThemePreferences(Map<String, dynamic> themePrefs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = themePrefs.toString();
      await prefs.setString(_themePreferencesKey, themeString);
    } catch (e) {
      print('CacheService: Error saving theme preferences: $e');
    }
  }

  // Get theme preferences
  static Future<Map<String, dynamic>?> getThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themePreferencesKey);
      if (themeString != null) {
        return <String, dynamic>{}; // Placeholder for actual parsing
      }
      return null;
    } catch (e) {
      print('CacheService: Error getting theme preferences: $e');
      return null;
    }
  }

  // Save last sync timestamp
  static Future<void> saveLastSync(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, timestamp.toIso8601String());
    } catch (e) {
      print('CacheService: Error saving last sync: $e');
    }
  }

  // Get last sync timestamp
  static Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_lastSyncKey);
      if (timestampString != null) {
        return DateTime.parse(timestampString);
      }
      return null;
    } catch (e) {
      print('CacheService: Error getting last sync: $e');
      return null;
    }
  }

  // Check if cache exists
  static Future<bool> hasCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys.isNotEmpty;
    } catch (e) {
      print('CacheService: Error checking cache existence: $e');
      return false;
    }
  }

  // Get cache size (approximate)
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int totalSize = 0;
      
      for (final key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          totalSize += value.length;
        } else if (value is List) {
          totalSize += value.length * 8; // Approximate size
        }
      }
      
      return totalSize;
    } catch (e) {
      print('CacheService: Error calculating cache size: $e');
      return 0;
    }
  }
}
