import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? targetRole;
  final String experienceLevel; // 'fresher' | 'junior' | 'mid' | 'senior'
  final String? resumeUrl;
  final int totalSessions;
  final double avgScore;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.targetRole,
    this.experienceLevel = 'fresher',
    this.resumeUrl,
    this.totalSessions = 0,
    this.avgScore = 0.0,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      targetRole: data['targetRole'],
      experienceLevel: data['experienceLevel'] ?? 'fresher',
      resumeUrl: data['resumeUrl'],
      totalSessions: data['totalSessions'] ?? 0,
      avgScore: (data['avgScore'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'targetRole': targetRole,
        'experienceLevel': experienceLevel,
        'resumeUrl': resumeUrl,
        'totalSessions': totalSessions,
        'avgScore': avgScore,
        'createdAt': FieldValue.serverTimestamp(),
      };

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? targetRole,
    String? experienceLevel,
    String? resumeUrl,
    int? totalSessions,
    double? avgScore,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      targetRole: targetRole ?? this.targetRole,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      totalSessions: totalSessions ?? this.totalSessions,
      avgScore: avgScore ?? this.avgScore,
      createdAt: createdAt,
    );
  }
}
