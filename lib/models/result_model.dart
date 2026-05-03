import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionResult {
  final String question;
  final String answer;
  final int score; // 0-10
  final String feedback;
  final String idealAnswer;

  QuestionResult({
    required this.question,
    required this.answer,
    required this.score,
    required this.feedback,
    required this.idealAnswer,
  });

  factory QuestionResult.fromMap(Map<String, dynamic> map) => QuestionResult(
        question: map['question'] ?? '',
        answer: map['answer'] ?? '',
        score: map['score'] ?? 0,
        feedback: map['feedback'] ?? '',
        idealAnswer: map['idealAnswer'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'question': question,
        'answer': answer,
        'score': score,
        'feedback': feedback,
        'idealAnswer': idealAnswer,
      };
}

class ResultModel {
  final String sessionId;
  final String userId;
  final int overallScore; // 0-100
  final String transcript;
  final List<QuestionResult> questionResults;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> generalFeedback;
  final Map<String, int> categoryScores; // {'communication': 80, 'technical': 70, ...}
  final DateTime createdAt;

  ResultModel({
    required this.sessionId,
    required this.userId,
    required this.overallScore,
    required this.transcript,
    required this.questionResults,
    required this.strengths,
    required this.improvements,
    required this.generalFeedback,
    required this.categoryScores,
    required this.createdAt,
  });

  factory ResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResultModel(
      sessionId: doc.id,
      userId: data['userId'] ?? '',
      overallScore: data['overallScore'] ?? 0,
      transcript: data['transcript'] ?? '',
      questionResults: ((data['questionResults'] as List?) ?? [])
          .map((q) => QuestionResult.fromMap(q as Map<String, dynamic>))
          .toList(),
      strengths: List<String>.from(data['strengths'] ?? []),
      improvements: List<String>.from(data['improvements'] ?? []),
      generalFeedback: List<String>.from(data['generalFeedback'] ?? []),
      categoryScores: Map<String, int>.from(data['categoryScores'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'overallScore': overallScore,
        'transcript': transcript,
        'questionResults': questionResults.map((q) => q.toMap()).toList(),
        'strengths': strengths,
        'improvements': improvements,
        'generalFeedback': generalFeedback,
        'categoryScores': categoryScores,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
