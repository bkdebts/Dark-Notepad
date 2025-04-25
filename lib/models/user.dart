import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isAnonymous;
  final String? deviceId;
  final Map<String, dynamic> settings;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    this.isAnonymous = false,
    this.deviceId,
    Map<String, dynamic>? settings,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastLoginAt = lastLoginAt ?? DateTime.now(),
        settings = settings ?? defaultSettings;

  // Default app settings
  static Map<String, dynamic> get defaultSettings => {
        'appLockEnabled': false,
        'biometricEnabled': false,
        'autoSaveEnabled': true,
        'cloudSyncEnabled': true,
        'notificationsEnabled': true,
        'fontSize': 16.0,
        'fontFamily': 'Roboto',
        'theme': 'dark',
        'sortBy': 'modified',
        'sortDirection': 'descending',
      };

  // Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAnonymous: data['isAnonymous'] ?? false,
      deviceId: data['deviceId'],
      settings: data['settings'] ?? defaultSettings,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isAnonymous': isAnonymous,
      'deviceId': deviceId,
      'settings': settings,
    };
  }

  // Create a copy of this user with optional fields updated
  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
    String? deviceId,
    Map<String, dynamic>? settings,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isAnonymous: isAnonymous,
      deviceId: deviceId ?? this.deviceId,
      settings: settings ?? Map<String, dynamic>.from(this.settings),
    );
  }

  // Update a specific setting
  AppUser updateSetting(String key, dynamic value) {
    final newSettings = Map<String, dynamic>.from(settings);
    newSettings[key] = value;
    return copyWith(settings: newSettings);
  }

  // Get a setting with optional default value
  T getSetting<T>(String key, T defaultValue) {
    return settings[key] as T? ?? defaultValue;
  }
}
