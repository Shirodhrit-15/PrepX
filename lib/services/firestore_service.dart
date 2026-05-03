import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/result_model.dart';
import '../models/question_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ──────────────────────────────────────────────────────────

  CollectionReference get _users => _db.collection('users');
  CollectionReference get _sessions => _db.collection('sessions');
  CollectionReference get _results => _db.collection('results');
  CollectionReference get _questions => _db.collection('questions');

  // ─── Users ────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Realtime stream for user profile changes (sidebar stats, avatar, etc.)
  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    // Soft delete — only removes auth linkage in Firestore
    await _users.doc(uid).update({'deletedAt': FieldValue.serverTimestamp()});
  }

  /// Increment session count and recalculate avg score atomically
  Future<void> updateUserStats(String uid, int newScore) async {
    await _db.runTransaction((tx) async {
      final ref = _users.doc(uid);
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>;
      final prevTotal = data['totalSessions'] ?? 0;
      final prevAvg = (data['avgScore'] ?? 0.0).toDouble();
      final newTotal = prevTotal + 1;
      final newAvg = ((prevAvg * prevTotal) + newScore) / newTotal;
      tx.update(ref, {
        'totalSessions': newTotal,
        'avgScore': double.parse(newAvg.toStringAsFixed(1)),
      });
    });
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────

  Future<String> createSession(SessionModel session) async {
    final ref = _sessions.doc(session.sessionId);
    await ref.set(session.toMap());
    return session.sessionId;
  }

  Future<SessionModel?> getSession(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromFirestore(doc);
  }

  /// Realtime updates during live interview (status changes, vapiCallId)
  Stream<SessionModel?> watchSession(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SessionModel.fromFirestore(doc);
    });
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> data) async {
    await _sessions.doc(sessionId).update(data);
  }

  Future<void> updateSessionStatus(
    String sessionId,
    SessionStatus status, {
    String? vapiCallId,
    int? durationSeconds,
  }) async {
    final update = <String, dynamic>{'status': status.name};
    if (vapiCallId != null) update['vapiCallId'] = vapiCallId;
    if (durationSeconds != null) update['durationSeconds'] = durationSeconds;
    if (status == SessionStatus.completed || status == SessionStatus.failed) {
      update['endedAt'] = FieldValue.serverTimestamp();
    }
    await _sessions.doc(sessionId).update(update);
  }

  /// All sessions for a user, most recent first
  Future<List<SessionModel>> getUserSessions(String userId, {int limit = 20}) async {
    final query = await _sessions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return query.docs.map(SessionModel.fromFirestore).toList();
  }

  Stream<List<SessionModel>> watchUserSessions(String userId) {
    return _sessions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(SessionModel.fromFirestore).toList());
  }

  // ─── Results ──────────────────────────────────────────────────────────────

  Future<void> saveResult(ResultModel result) async {
    await _results.doc(result.sessionId).set(result.toMap());
    // Also update user stats
    await updateUserStats(result.userId, result.overallScore);
  }

  Future<ResultModel?> getResult(String sessionId) async {
    final doc = await _results.doc(sessionId).get();
    if (!doc.exists) return null;
    return ResultModel.fromFirestore(doc);
  }

  Stream<ResultModel?> watchResult(String sessionId) {
    return _results.doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ResultModel.fromFirestore(doc);
    });
  }

  Future<List<ResultModel>> getUserResults(String userId, {int limit = 20}) async {
    final query = await _results
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return query.docs.map(ResultModel.fromFirestore).toList();
  }

  // ─── Questions ────────────────────────────────────────────────────────────

  Future<List<QuestionModel>> getQuestions({
    required String domain,
    required String level,
    int limit = 10,
  }) async {
    final query = await _questions
        .where('domain', isEqualTo: domain)
        .where('level', isEqualTo: level)
        .limit(limit)
        .get();
    return query.docs.map(QuestionModel.fromFirestore).toList();
  }

  Future<void> seedQuestion(QuestionModel question) async {
    await _questions.doc(question.questionId).set(question.toMap());
  }
}
