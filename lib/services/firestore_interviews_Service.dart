// Add these methods to your existing FirestoreService class
// in lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interview_model.dart'; // adjust path as needed

// ─── inside FirestoreService class ───────────────────────────────────────────

final FirebaseFirestore _db = FirebaseFirestore.instance;

/// Fetch all interviews for a specific user (one-time)
Future<List<InterviewModel>> getUserInterviews(String userId) async {
  final snap = await _db
      .collection('interviews')
      .where('userId', isEqualTo: userId)
      .where('finalized', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .get();

  return snap.docs.map((d) => InterviewModel.fromFirestore(d)).toList();
}

/// Real-time stream of user interviews
Stream<List<InterviewModel>> watchUserInterviews(String userId) {
  return _db
      .collection('interviews')
      .where('userId', isEqualTo: userId)
      .where('finalized', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => InterviewModel.fromFirestore(d)).toList());
}

/// Fetch a single interview by document ID
Future<InterviewModel?> getInterview(String interviewId) async {
  final doc = await _db.collection('interviews').doc(interviewId).get();
  if (!doc.exists) return null;
  return InterviewModel.fromFirestore(doc);
}

/// Create a new interview document
Future<String> createInterview(InterviewModel interview) async {
  final ref = await _db.collection('interviews').add(interview.toMap());
  return ref.id;
}

/// Mark interview as finalized
Future<void> finalizeInterview(String interviewId) async {
  await _db
      .collection('interviews')
      .doc(interviewId)
      .update({'finalized': true});
}

/// Delete an interview
Future<void> deleteInterview(String interviewId) async {
  await _db.collection('interviews').doc(interviewId).delete();
}
