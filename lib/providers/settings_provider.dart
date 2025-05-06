import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  // Default settings
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _cloudSyncEnabled = true;
  bool _autoSaveEnabled = true;
  bool _notificationsEnabled = true;
  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  
  // Getters
  bool get appLockEnabled => _appLockEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get cloudSyncEnabled => _cloudSyncEnabled;
  bool get autoSaveEnabled => _autoSaveEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  
  // Constructor
  SettingsProvider() {
    loadSettings();
  }
  
  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _appLockEnabled = prefs.getBool(AppConstants.keyAppLockEnabled) ?? false;
      _biometricEnabled = prefs.getBool(AppConstants.keyBiometricEnabled) ?? false;
      _cloudSyncEnabled = prefs.getBool(AppConstants.keyCloudSyncEnabled) ?? true;
      _autoSaveEnabled = prefs.getBool(AppConstants.keyAutoSyncEnabled) ?? true;
      _notificationsEnabled = prefs.getBool(AppConstants.keyRemindersEnabled) ?? true;
      _fontSize = prefs.getDouble(AppConstants.keyFontSize) ?? 16.0;
      _fontFamily = prefs.getString(AppConstants.keyFontFamily) ?? 'Roboto';
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }
  
  // Save settings to SharedPreferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyAppLockEnabled, _appLockEnabled);
      await prefs.setBool(AppConstants.keyBiometricEnabled, _biometricEnabled);
      await prefs.setBool(AppConstants.keyCloudSyncEnabled, _cloudSyncEnabled);
      await prefs.setBool(AppConstants.keyAutoSyncEnabled, _autoSaveEnabled);
      await prefs.setBool(AppConstants.keyRemindersEnabled, _notificationsEnabled);
      await prefs.setDouble(AppConstants.keyFontSize, _fontSize);
      await prefs.setString(AppConstants.keyFontFamily, _fontFamily);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
  
  // Update app lock settings
  void setAppLock(bool enabled) {
    _appLockEnabled = enabled;
    if (!enabled) {
      _biometricEnabled = false;
    }
    saveSettings();
    notifyListeners();
  }
  
  // Update biometric settings
  void setBiometric(bool enabled) {
    _biometricEnabled = enabled;
    saveSettings();
    notifyListeners();
  }
  
  // Update cloud sync settings
  void setCloudSync(bool enabled) {
    _cloudSyncEnabled = enabled;
    saveSettings();
    notifyListeners();
  }
  
  // Update auto save settings
  void setAutoSave(bool enabled) {
    _autoSaveEnabled = enabled;
    saveSettings();
    notifyListeners();
  }
  
  // Update notifications settings
  void setNotifications(bool enabled) {
    _notificationsEnabled = enabled;
    saveSettings();
    notifyListeners();
  }
  
  // Update font size settings
  void setFontSize(double size) {
    _fontSize = size;
    saveSettings();
    notifyListeners();
  }
  
  // Update font family settings
  void setFontFamily(String family) {
    _fontFamily = family;
    saveSettings();
    notifyListeners();
  }
} 