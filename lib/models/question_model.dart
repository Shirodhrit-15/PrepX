import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String questionId;
  final String domain;
  final String level; // 'easy' | 'medium' | 'hard'
  final String text;
  final List<String> tags;
  final String? hint;

  QuestionModel({
    required this.questionId,
    required this.domain,
    required this.level,
    required this.text,
    required this.tags,
    this.hint,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      questionId: doc.id,
      domain: data['domain'] ?? '',
      level: data['level'] ?? 'medium',
      text: data['text'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      hint: data['hint'],
    );
  }

  Map<String, dynamic> toMap() => {
        'domain': domain,
        'level': level,
        'text': text,
        'tags': tags,
        'hint': hint,
      };
}
