// models/interview_model.dart

// ignore_for_file: prefer_const_constructors

enum InterviewType { technical, behavioral, mixed, hr }

enum InterviewStatus { available, completed, inProgress }

class InterviewModel {
  final String id;
  final String title;
  final String company;
  final String logoPath;
  final InterviewType type;
  final InterviewStatus status;
  final String? date;
  final int? score; // out of 10
  final String description;
  final List<String> techStack;
  final String level; // Junior / Mid / Senior
  final List<String> questions;

  const InterviewModel({
    required this.id,
    required this.title,
    required this.company,
    required this.logoPath,
    required this.type,
    required this.status,
    this.date,
    this.score,
    required this.description,
    this.techStack = const [],
    this.level = 'Junior',
    this.questions = const [],
  });

  String get typeLabel {
    switch (type) {
      case InterviewType.technical:
        return 'Technical';
      case InterviewType.behavioral:
        return 'Behavioral';
      case InterviewType.mixed:
        return 'Mixed';
      case InterviewType.hr:
        return 'HR';
    }
  }

  String get scoreLabel => score != null ? '$score/10' : '---/10';

  bool get isCompleted => status == InterviewStatus.completed;
}

// Sample data for the app
class InterviewData {
  static final List<InterviewModel> available = [
    InterviewModel(
      id: '1',
      title: 'Frontend Developer',
      company: 'Microsoft',
      logoPath: 'assets/logos/microsoft.png',
      type: InterviewType.technical,
      status: InterviewStatus.available,
      date: 'Mar 15, 2025',
      description:
          'Covers React, Next.js, TypeScript and frontend fundamentals.',
      techStack: ['React', 'TypeScript', 'Next.js'],
      level: 'Junior',
      questions: [
        'Explain the difference between props and state in React.',
        'What is the virtual DOM and how does it work?',
        'How does useEffect work? Explain its dependencies.',
        'What are controlled vs uncontrolled components?',
        'Explain CSS specificity and the box model.',
      ],
    ),
    InterviewModel(
      id: '2',
      title: 'Full Stack Developer',
      company: 'Google',
      logoPath: 'assets/logos/google.png',
      type: InterviewType.mixed,
      status: InterviewStatus.available,
      date: 'Mar 14, 2025',
      description: 'Covers frontend, backend, databases and system design.',
      techStack: ['Node.js', 'React', 'PostgreSQL'],
      level: 'Mid',
      questions: [
        'How would you design a URL shortener service?',
        'Explain RESTful API design principles.',
        'What is the difference between SQL and NoSQL?',
        'How does authentication with JWT tokens work?',
        'Explain the concept of database indexing.',
      ],
    ),
    InterviewModel(
      id: '3',
      title: 'HR Screening',
      company: 'Adobe',
      logoPath: 'assets/logos/adobe.png',
      type: InterviewType.hr,
      status: InterviewStatus.available,
      date: 'TBD',
      description:
          'Focuses on communication skills, culture fit and soft skills.',
      techStack: [],
      level: 'All Levels',
      questions: [
        'Tell me about yourself and your background.',
        'Why are you interested in this role?',
        'Describe a challenging situation you faced at work.',
        'Where do you see yourself in 5 years?',
        'What are your biggest strengths and weaknesses?',
      ],
    ),
  ];

  static final List<InterviewModel> past = [
    InterviewModel(
      id: '4',
      title: 'Frontend Dev Interview',
      company: 'Google',
      logoPath: 'assets/logos/google.png',
      type: InterviewType.technical,
      status: InterviewStatus.completed,
      date: 'Oct 10, 2024',
      score: 3,
      description:
          'Struggled with React fundamentals. Needs improvement in hooks.',
      techStack: ['React', 'JavaScript'],
      level: 'Junior',
    ),
    InterviewModel(
      id: '5',
      title: 'Behavioral Interview',
      company: 'Adobe',
      logoPath: 'assets/logos/adobe.png',
      type: InterviewType.behavioral,
      status: InterviewStatus.completed,
      date: 'Oct 5, 2024',
      score: 7,
      description: 'Good communication, but lacked enthusiasm on some answers.',
      techStack: [],
      level: 'Junior',
    ),
  ];
}
