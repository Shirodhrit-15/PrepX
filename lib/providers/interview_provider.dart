import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';
import '../models/result_model.dart';
import '../services/firestore_service.dart';
import '../services/vapi_service.dart';
import '../services/api_service.dart';

enum InterviewPhase { idle, setup, connecting, active, analyzing, done, error }

class InterviewProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final VapiService _vapiService = VapiService();
  final ApiService _apiService = ApiService();
  final _uuid = const Uuid();

  InterviewPhase _phase = InterviewPhase.idle;
  SessionModel? _currentSession;
  ResultModel? _currentResult;
  String? _errorMessage;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Live transcript buffer for UI display
  final List<Map<String, String>> _liveTranscript = [];

  InterviewPhase get phase => _phase;
  SessionModel? get currentSession => _currentSession;
  ResultModel? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;
  int get elapsedSeconds => _elapsedSeconds;
  List<Map<String, String>> get liveTranscript =>
      List.unmodifiable(_liveTranscript);

  String get formattedDuration {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Start Interview ──────────────────────────────────────────────────────

  Future<void> startInterview({
    required String userId,
    required String jobRole,
    required String domain,
    required String difficulty,
    String? resumeUrl,
  }) async {
    _setPhase(InterviewPhase.connecting);
    _liveTranscript.clear();
    _elapsedSeconds = 0;
    _errorMessage = null;

    final sessionId = _uuid.v4();

    try {
      // 1. Create Firestore session record
      final session = SessionModel(
        sessionId: sessionId,
        userId: userId,
        jobRole: jobRole,
        domain: domain,
        difficulty: difficulty,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createSession(session);
      _currentSession = session;

      // 2. Start Vapi voice call
      await _vapiService.startInterview(
        jobRole: jobRole,
        domain: domain,
        difficulty: difficulty,
        resumeContext: resumeUrl,
      );

      // 3. Listen to Vapi events
      _vapiService.statusStream.listen(_onVapiStatus);
      _vapiService.messages.listen(_onVapiMessage);

      // 4. Update session status to active
      await _firestoreService.updateSessionStatus(
        sessionId,
        SessionStatus.active,
      );
      _currentSession = _currentSession!.copyWith(status: SessionStatus.active);

      _setPhase(InterviewPhase.active);
      _startTimer();
    } catch (e) {
      _errorMessage = e.toString();
      _setPhase(InterviewPhase.error);
      await _firestoreService.updateSessionStatus(
        sessionId,
        SessionStatus.failed,
      );
    }
  }

  // ─── End Interview ────────────────────────────────────────────────────────

  Future<void> endInterview() async {
    if (_currentSession == null) return;
    _stopTimer();
    _setPhase(InterviewPhase.analyzing);

    try {
      // 1. Stop Vapi
      await _vapiService.stopInterview();

      final sessionId = _currentSession!.sessionId;
      final transcript = _vapiService.buildTranscriptString();

      // 2. Update session as completed
      await _firestoreService.updateSessionStatus(
        sessionId,
        SessionStatus.completed,
        durationSeconds: _elapsedSeconds,
      );

      // 3. Call Cloud Function → Gemini for analysis
      final analysisData = await _apiService.analyzeTranscript(
        sessionId: sessionId,
        userId: _currentSession!.userId,
        transcript: transcript,
        jobRole: _currentSession!.jobRole,
        domain: _currentSession!.domain,
        difficulty: _currentSession!.difficulty,
      );

      // 4. Cloud Function already wrote to Firestore — just read the result
      _currentResult = await _firestoreService.getResult(sessionId);

      _setPhase(InterviewPhase.done);
    } catch (e) {
      _errorMessage = e.toString();
      _setPhase(InterviewPhase.error);
    }
  }

  // ─── Vapi Event Handlers ──────────────────────────────────────────────────

  void _onVapiStatus(VapiCallStatus status) {
    if (status == VapiCallStatus.ended && _phase == InterviewPhase.active) {
      endInterview();
    } else if (status == VapiCallStatus.error) {
      _errorMessage = 'Voice connection lost.';
      _setPhase(InterviewPhase.error);
      _stopTimer();
    }
  }

  void _onVapiMessage(VapiMessage msg) {
    if (msg.type == 'transcript' && msg.content != null) {
      _liveTranscript.add({
        'role': msg.role ?? 'unknown',
        'text': msg.content!,
      });
      notifyListeners();
    } else if (msg.type == 'call-start' && msg.content != null) {
      // Save vapiCallId to Firestore
      _firestoreService.updateSession(_currentSession!.sessionId, {
        'vapiCallId': msg.content,
      });
    }
  }

  // ─── Timer ────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  void reset() {
    _stopTimer();
    _vapiService.dispose();
    _phase = InterviewPhase.idle;
    _currentSession = null;
    _currentResult = null;
    _errorMessage = null;
    _elapsedSeconds = 0;
    _liveTranscript.clear();
    notifyListeners();
  }

  void _setPhase(InterviewPhase p) {
    _phase = p;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    _vapiService.dispose();
    super.dispose();
  }
}
