import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log when a question is asked
  Future<void> logQuestionAsked(String questionType) async {
    try {
      await _analytics.logEvent(
        name: 'question_asked',
        parameters: {
          'type': questionType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Analytics error in logQuestionAsked: $e');
    }
  }

  // Log when an answer is generated
  Future<void> logAnswerGenerated(String questionType, int responseTime) async {
    try {
      await _analytics.logEvent(
        name: 'answer_generated',
        parameters: {
          'type': questionType,
          'response_time': responseTime,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Analytics error in logAnswerGenerated: $e');
    }
  }

  // Log which RAG service was used
  Future<void> logRagServiceUsed(String serviceName) async {
    try {
      await _analytics.logEvent(
        name: 'rag_service_used',
        parameters: {
          'service': serviceName,
        },
      );
    } catch (e) {
      print('Analytics error in logRagServiceUsed: $e');
    }
  }
}
