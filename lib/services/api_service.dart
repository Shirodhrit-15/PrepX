import 'package:cloud_functions/cloud_functions.dart';

class ApiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ─── Analyze Transcript via Gemini (Cloud Function) ───────────────────────

  /// Sends the transcript to Cloud Functions which calls Gemini and
  /// writes the result to Firestore.
  Future<Map<String, dynamic>> analyzeTranscript({
    required String sessionId,
    required String userId,
    required String transcript,
    required String jobRole,
    required String domain,
    required String difficulty,
  }) async {
    final callable = _functions.httpsCallable(
      'analyzeTranscript',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call({
      'sessionId': sessionId,
      'userId': userId,
      'transcript': transcript,
      'jobRole': jobRole,
      'domain': domain,
      'difficulty': difficulty,
    });

    return Map<String, dynamic>.from(result.data as Map);
  }

  // ─── Generate Interview Questions ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> generateQuestions({
    required String jobRole,
    required String domain,
    required String difficulty,
    int count = 10,
  }) async {
    final callable = _functions.httpsCallable('generateQuestions');
    final result = await callable.call({
      'jobRole': jobRole,
      'domain': domain,
      'difficulty': difficulty,
      'count': count,
    });

    final data = result.data as List;
    return data.map((q) => Map<String, dynamic>.from(q as Map)).toList();
  }

  // ─── Create Vapi Assistant (Cloud Function) ───────────────────────────────

  /// Creates a one-time Vapi assistant configured for the session.
  /// Returns the assistant ID to use for the WebSocket connection.
  Future<String> createVapiAssistant({
    required String jobRole,
    required String domain,
    required String difficulty,
    String? resumeContext,
  }) async {
    final callable = _functions.httpsCallable('createVapiAssistant');
    final result = await callable.call({
      'jobRole': jobRole,
      'domain': domain,
      'difficulty': difficulty,
      'resumeContext': resumeContext,
    });

    return (result.data as Map)['assistantId'] as String;
  }
}
