import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:math';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;
  String? _deviceId;
  String? _deviceModel;

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Only initialize if on supported platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        _analytics = FirebaseAnalytics.instance;
        await _analytics!.setAnalyticsCollectionEnabled(true);
        
        // Get or generate persistent device ID
        await _initDeviceIdentifiers();
        
        // Set user properties
        if (_deviceId != null) {
          await _analytics!.setUserId(id: _deviceId);
        }
        
        if (_deviceModel != null) {
          await _analytics!.setUserProperty(name: 'device_model', value: _deviceModel);
        }
        
        // Log initialization success
        await logEvent(name: 'app_initialized', parameters: {
          'device_id': _deviceId ?? 'unknown',
          'device_model': _deviceModel ?? 'unknown',
          'initialization_time': DateTime.now().toIso8601String(),
        });
        
        print('Firebase Analytics initialized successfully');
        print('Device ID: $_deviceId');
        print('Device Model: $_deviceModel');
        
        _initialized = true;
      } catch (e) {
        print('Failed to initialize Firebase Analytics: $e');
      }
    } else {
      print('Firebase Analytics not supported on this platform');
    }
  }

  // Get or generate a persistent device ID
  Future<void> _initDeviceIdentifiers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('device_id');
      
      if (_deviceId == null) {
        // Generate a new ID if we don't have one stored
        _deviceId = _generateDeviceId();
        await prefs.setString('device_id', _deviceId!);
      }
      
      // Try to get device model from user agent or fallback
      _deviceModel = Platform.isAndroid 
          ? 'Android Device' 
          : Platform.isIOS 
              ? 'iOS Device' 
              : 'Unknown Device';
    } catch (e) {
      print('Error getting device identifiers: $e');
    }
  }

  // Generate a pseudo-random device ID
  String _generateDeviceId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return 'device_${DateTime.now().millisecondsSinceEpoch}_' + 
        List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Log events with error handling
  Future<void> logEvent({required String name, Map<String, dynamic>? parameters}) async {
    if (_analytics != null) {
      try {
        // Add device identifiers to all events if not already present
        final eventParams = <String, dynamic>{};
        if (parameters != null) {
          eventParams.addAll(parameters);
        }
        
        if (!eventParams.containsKey('device_id') && _deviceId != null) {
          eventParams['device_id'] = _deviceId;
        }
        
        await _analytics!.logEvent(
          name: name,
          parameters: Map<String, Object>.from(eventParams), // Updated line
        );
        print('Successfully logged event: $name');
      } catch (e) {
        print('Failed to log event $name: $e');
      }
    }
  }

  // Log screen views with error handling
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    if (_analytics != null) {
      try {
        await _analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
        );
        print('Successfully logged screen view: $screenName');
      } catch (e) {
        print('Failed to log screen view $screenName: $e');
      }
    }
  }

  // User engagement tracking
  Future<void> logQuestionAsked(String source) async {
    await logEvent(
      name: 'question_asked',
      parameters: {
        'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // App feature usage
  Future<void> logFeatureUsed(String featureName) async {
    await logEvent(
      name: 'feature_used',
      parameters: {
        'feature': featureName,
      },
    );
  }
  
  // Heartbeat event to ensure device reporting
  Future<void> logHeartbeat() async {
    await logEvent(
      name: 'heartbeat',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Log when an answer is generated
  Future<void> logAnswerGenerated(String questionType, int responseTime) async {
    await logEvent(
      name: 'answer_generated',
      parameters: {
        'type': questionType,
        'response_time': responseTime,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Log which RAG service was used
  Future<void> logRagServiceUsed(String serviceName) async {
    await logEvent(
      name: 'rag_service_used',
      parameters: {
        'service': serviceName,
      },
    );
  }
}