import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewModel {
  final String id;
  final String userId;
  final String role;
  final String type; // 'technical' | 'hr' | 'behavioral'
  final String level; // 'Junior' | 'Mid-level' | 'Senior'
  final List<String> techstack;
  final List<String> questions;
  final String coverImage;
  final bool finalized;
  final DateTime createdAt;

  const InterviewModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.type,
    required this.level,
    required this.techstack,
    required this.questions,
    required this.coverImage,
    required this.finalized,
    required this.createdAt,
  });

  factory InterviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InterviewModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      role: d['role'] ?? '',
      type: d['type'] ?? 'technical',
      level: d['level'] ?? 'Mid-level',
      techstack: List<String>.from(d['techstack'] ?? []),
      questions: List<String>.from(d['questions'] ?? []),
      coverImage: d['coverImage'] ?? '',
      finalized: d['finalized'] ?? false,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(d['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'role': role,
        'type': type,
        'level': level,
        'techstack': techstack,
        'questions': questions,
        'coverImage': coverImage,
        'finalized': finalized,
        'createdAt': createdAt.toIso8601String(),
      };
}
