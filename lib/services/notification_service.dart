import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  // Singleton instance
  factory NotificationService() => _instance;
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
      
  // Initialize notifications
  Future<void> initNotifications() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Initialize Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Initialize settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Initialize notifications plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    final androidPermissions = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
            
    final iosPermission = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
    return androidPermissions ?? false || iosPermission ?? false;
  }

  // Create notification channel for Android
  Future<void> createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'reminders_channel',
      'Reminders',
      description: 'Notifications for note reminders',
      importance: Importance.high,
    );
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Schedule a reminder notification
  Future<bool> scheduleReminder(
    String noteId,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    try {
      // Create notification details
      const androidDetails = AndroidNotificationDetails(
        'reminders_channel',
        'Reminders',
        channelDescription: 'Notifications for note reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Colors.deepPurple,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Schedule notification
      final id = int.parse(noteId.hashCode.toString().substring(0, 8));
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: noteId,
      );
      
      return true;
    } catch (e) {
      print('Error scheduling notification: $e');
      return false;
    }
  }

  // Cancel a reminder notification
  Future<bool> cancelReminder(String noteId) async {
    try {
      final id = int.parse(noteId.hashCode.toString().substring(0, 8));
      await _notificationsPlugin.cancel(id);
      return true;
    } catch (e) {
      print('Error canceling notification: $e');
      return false;
    }
  }

  // Cancel all reminder notifications
  Future<bool> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
      return true;
    } catch (e) {
      print('Error canceling all notifications: $e');
      return false;
    }
  }

  // Show an immediate notification
  Future<bool> showNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    try {
      // Create notification details
      const androidDetails = AndroidNotificationDetails(
        'reminders_channel',
        'Reminders',
        channelDescription: 'Notifications for note reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Colors.deepPurple,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Show notification
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );
      
      return true;
    } catch (e) {
      print('Error showing notification: $e');
      return false;
    }
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse notificationResponse) {
    // The payload is usually a note ID
    final payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      // Use the payload to navigate to the appropriate screen
      // This will be handled by the app's route system
    }
  }

  // Check if a reminder exists
  Future<bool> checkReminderExists(String noteId) async {
    try {
      final pendingNotifications = 
          await _notificationsPlugin.pendingNotificationRequests();
          
      final id = int.parse(noteId.hashCode.toString().substring(0, 8));
      
      return pendingNotifications.any((notification) => 
          notification.id == id);
    } catch (e) {
      print('Error checking reminder: $e');
      return false;
    }
  }
}
