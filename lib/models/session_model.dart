import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { pending, active, completed, failed }

class SessionModel {
  final String sessionId;
  final String userId;
  final String jobRole;
  final String domain; // 'technical' | 'hr' | 'behavioral' | 'mixed'
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final String? vapiCallId;
  final SessionStatus status;
  final int durationSeconds;
  final DateTime createdAt;
  final DateTime? endedAt;

  SessionModel({
    required this.sessionId,
    required this.userId,
    required this.jobRole,
    required this.domain,
    required this.difficulty,
    this.vapiCallId,
    this.status = SessionStatus.pending,
    this.durationSeconds = 0,
    required this.createdAt,
    this.endedAt,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      sessionId: doc.id,
      userId: data['userId'] ?? '',
      jobRole: data['jobRole'] ?? '',
      domain: data['domain'] ?? 'mixed',
      difficulty: data['difficulty'] ?? 'medium',
      vapiCallId: data['vapiCallId'],
      status: SessionStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'pending'),
        orElse: () => SessionStatus.pending,
      ),
      durationSeconds: data['durationSeconds'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'jobRole': jobRole,
        'domain': domain,
        'difficulty': difficulty,
        'vapiCallId': vapiCallId,
        'status': status.name,
        'durationSeconds': durationSeconds,
        'createdAt': FieldValue.serverTimestamp(),
        'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      };

  SessionModel copyWith({
    String? vapiCallId,
    SessionStatus? status,
    int? durationSeconds,
    DateTime? endedAt,
  }) {
    return SessionModel(
      sessionId: sessionId,
      userId: userId,
      jobRole: jobRole,
      domain: domain,
      difficulty: difficulty,
      vapiCallId: vapiCallId ?? this.vapiCallId,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
