import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../data/islamic_facts_data.dart';

class ReadingTrackerService {
  static const String _readingSessionsKey = 'reading_sessions';
  static const String _lastReminderKey = 'last_reminder_sent';
  
  // Track when user starts reading a surah
  static Future<void> startReadingSession(int surahNumber, String surahName) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    final sessionData = {
      'surah_number': surahNumber,
      'surah_name': surahName,
      'start_time': now.toIso8601String(),
      'last_verse': 1,
      'completed': false,
    };
    
    await prefs.setString('current_session', 
        sessionData.entries.map((e) => '${e.key}:${e.value}').join('|'));
    
    print("Started reading session: Surah $surahNumber - $surahName");
  }
  
  // Track progress (called when user scrolls/jumps to verses)
  static Future<void> updateProgress(int verseNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final currentSession = prefs.getString('current_session');
    
    if (currentSession != null) {
      final data = Map.fromEntries(
        currentSession.split('|').map((e) => e.split(':')).map((e) => MapEntry(e[0], e[1]))
      );
      
      data['last_verse'] = verseNumber.toString();
      data['last_activity'] = DateTime.now().toIso8601String();
      
      await prefs.setString('current_session',
          data.entries.map((e) => '${e.key}:${e.value}').join('|'));
      
      print("Updated progress: verse $verseNumber");
    }
  }
  
  // Mark surah as completed
  static Future<void> completeSurah() async {
    final prefs = await SharedPreferences.getInstance();
    final currentSession = prefs.getString('current_session');
    
    if (currentSession != null) {
      final data = Map.fromEntries(
        currentSession.split('|').map((e) => e.split(':')).map((e) => MapEntry(e[0], e[1]))
      );
      
      data['completed'] = 'true';
      data['completion_time'] = DateTime.now().toIso8601String();
      
      // Save to completed sessions
      final completedSessions = prefs.getStringList('completed_sessions') ?? [];
      completedSessions.add(currentSession);
      await prefs.setStringList('completed_sessions', completedSessions);
      
      // Clear current session
      await prefs.remove('current_session');
      
      print("Completed surah: ${data['surah_name']}");
    }
  }
  
  // End reading session (when user leaves screen)
  static Future<void> endReadingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final currentSession = prefs.getString('current_session');
    
    if (currentSession != null) {
      final data = Map.fromEntries(
        currentSession.split('|').map((e) => e.split(':')).map((e) => MapEntry(e[0], e[1]))
      );
      
      final startTime = DateTime.parse(data['start_time']!);
      final duration = DateTime.now().difference(startTime);
      
      // If they read for less than 2 minutes, don't set reminder
      if (duration.inMinutes < 2) {
        await prefs.remove('current_session');
        return;
      }
      
      // Save incomplete session for reminder
      data['end_time'] = DateTime.now().toIso8601String();
      data['duration_minutes'] = duration.inMinutes.toString();
      
      final incompleteSessions = prefs.getStringList('incomplete_sessions') ?? [];
      incompleteSessions.add(data.entries.map((e) => '${e.key}:${e.value}').join('|'));
      await prefs.setStringList('incomplete_sessions', incompleteSessions);
      
      await prefs.remove('current_session');
      
      // Schedule reminder
      _scheduleReadingReminder(data);
      
      print("Ended reading session: ${data['surah_name']}, read for ${duration.inMinutes} minutes");
    }
  }
  
  // Schedule reminder notification
  static Future<void> _scheduleReadingReminder(Map<String, String> sessionData) async {
    final prefs = await SharedPreferences.getInstance();
    final lastReminder = prefs.getString(_lastReminderKey);
    final now = DateTime.now();
    
    // Don't send more than one reminder per day
    if (lastReminder != null) {
      final lastReminderDate = DateTime.parse(lastReminder);
      if (now.difference(lastReminderDate).inHours < 24) {
        return;
      }
    }
    
    // Schedule reminder for tomorrow at 2 PM
    final reminderTime = DateTime(now.year, now.month, now.day + 1, 14, 0);
    
    final surahName = sessionData['surah_name']!;
    final lastVerse = sessionData['last_verse']!;
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 777777, // Reading reminder ID
          channelKey: 'reading_reminders_channel',
          title: 'Continue Your Spiritual Journey 📖',
          body: 'You were reading $surahName (verse $lastVerse). Continue where you left off!',
          notificationLayout: NotificationLayout.BigText,
          largeIcon: 'resource://drawable/ic_notification',
          wakeUpScreen: false,
        ),
        schedule: NotificationCalendar.fromDate(
          date: reminderTime,
          allowWhileIdle: true,
        ),
      );
      
      await prefs.setString(_lastReminderKey, now.toIso8601String());
      print("Scheduled reading reminder for $surahName at $reminderTime");
      
    } catch (e) {
      print("Failed to schedule reading reminder: $e");
    }
  }
  
  static Future<Map<String, dynamic>?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final currentSession = prefs.getString('current_session');
    
    if (currentSession != null) {
      return Map.fromEntries(
        currentSession.split('|').map((e) => e.split(':')).map((e) => MapEntry(e[0], e[1]))
      );
    }
    return null;
  }
}
