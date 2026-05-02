// ignore_for_file: unnecessary_import

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:prepx/asset/app_theme.dart';
import 'package:prepx/asset/auth_service.dart';
import 'package:prepx/asset/common_widget.dart';
import 'package:prepx/asset/feedback.dart';
import 'package:prepx/asset/interview_model.dart';

class InterviewPage extends StatefulWidget {
  final InterviewModel interview;

  const InterviewPage({super.key, required this.interview});

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  int _currentQuestion = 0;
  bool _isAiSpeaking = false;
  bool _isUserSpeaking = false;
  bool _hasStarted = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Timer? _aiSimTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  void _startInterview() {
    setState(() => _hasStarted = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
    _simulateAi();
  }

  void _simulateAi() {
    setState(() => _isAiSpeaking = true);
    _aiSimTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isAiSpeaking = false);
    });
  }

  void _toggleUserSpeaking() {
    setState(() => _isUserSpeaking = !_isUserSpeaking);
  }

  void _nextQuestion() {
    if (_currentQuestion < widget.interview.questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _isUserSpeaking = false;
      });
      _simulateAi();
    } else {
      _endInterview();
    }
  }

  void _endInterview() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackPage(interview: widget.interview),
      ),
    );
  }

  String get _time {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aiSimTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.interview.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (_hasStarted)
                    Text(_time, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),

            Expanded(
              child: _hasStarted
                  ? _buildInterview(user?.name ?? "You")
                  : _buildStart(),
            ),

            if (_hasStarted) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStart() {
    return Center(
      child: GradientButton(
        label: "Start Interview",
        onPressed: _startInterview,
      ),
    );
  }

  Widget _buildInterview(String name) {
    final q = widget.interview.questions;

    return Column(
      children: [
        Text(
          q[_currentQuestion],
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _avatar("AI", _isAiSpeaking, true),
            _avatar(name, _isUserSpeaking, false),
          ],
        ),
      ],
    );
  }

  Widget _avatar(String label, bool speaking, bool isAi) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Transform.scale(
            scale: speaking ? _pulseAnimation.value : 1,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: isAi ? AppColors.primary : AppColors.accent,
              child: Icon(
                isAi ? Icons.psychology : Icons.person,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(
            icon: _isUserSpeaking ? Icons.mic : Icons.mic_off,
            color: _isUserSpeaking ? AppColors.accent : AppColors.textMuted,
            onTap: _toggleUserSpeaking,
          ),
          _circleButton(
            icon: Icons.arrow_forward,
            color: AppColors.primary,
            onTap: _nextQuestion,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.card,
        child: Icon(icon, color: color),
      ),
    );
  }
}
