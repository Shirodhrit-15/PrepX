// pages/feedback_page.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:prepx/asset/app_theme.dart';
import 'package:prepx/asset/common_widget.dart';
import 'package:prepx/asset/interview_model.dart';

class FeedbackPage extends StatelessWidget {
  final InterviewModel interview;

  const FeedbackPage({super.key, required this.interview});

  // Mock feedback data (replace with AI-generated data from Gemini/Vapi)
  static const _categories = [
    _FeedbackCategory('Technical Accuracy', 6, AppColors.info,
        'Demonstrated solid understanding of core concepts. Could improve depth on advanced topics.'),
    _FeedbackCategory('Communication', 7, AppColors.success,
        'Clear and structured responses. Occasional filler words noticed.'),
    _FeedbackCategory('Problem Solving', 5, AppColors.warning,
        'Approached problems logically but missed some optimization opportunities.'),
    _FeedbackCategory('Confidence', 6, AppColors.accent,
        'Good overall tone. Slight hesitation on complex questions.'),
    _FeedbackCategory('Culture Fit', 8, AppColors.success,
        'Strong enthusiasm and team-oriented mindset demonstrated.'),
  ];

  int get _overallScore {
    final sum = _categories.fold(0, (sum, c) => sum + c.score);
    return (sum / _categories.length).round();
  }

  String get _verdict {
    if (_overallScore >= 8) return 'Strongly Recommended';
    if (_overallScore >= 6) return 'Recommended';
    if (_overallScore >= 4) return 'Needs Improvement';
    return 'Not Recommended';
  }

  Color get _verdictColor {
    if (_overallScore >= 8) return AppColors.success;
    if (_overallScore >= 6) return AppColors.accent;
    if (_overallScore >= 4) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: GestureDetector(
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.textSecondary),
              ),
            ),
            title: const Text('Interview Feedback'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: AppColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interview info chip
                  Wrap(
                    spacing: 8,
                    children: [
                      StatusBadge(
                          label: interview.typeLabel, color: AppColors.info),
                      StatusBadge(
                          label: interview.level, color: AppColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    interview.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    interview.company,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Overall score card
                  _buildOverallCard(),
                  const SizedBox(height: 24),

                  // Category breakdown
                  const SectionHeader(title: 'Category Breakdown'),
                  const SizedBox(height: 14),
                  ..._categories.map((cat) => _buildCategoryCard(cat)),
                  const SizedBox(height: 24),

                  // Improvement suggestions
                  const SectionHeader(title: 'Improvement Tips'),
                  const SizedBox(height: 14),
                  _buildTips(),
                  const SizedBox(height: 32),

                  // Action buttons
                  GradientButton(
                    label: 'Practice Again',
                    icon: Icons.refresh_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Back to Dashboard',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _verdictColor.withOpacity(0.12),
            _verdictColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _verdictColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          ScoreRing(score: _overallScore, size: 90),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Score',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  _verdict,
                  style: TextStyle(
                    color: _verdictColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You showed strong communication and culture fit. Focus on deepening technical answers.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_FeedbackCategory cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cat.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${cat.score}/10',
                  style: TextStyle(
                    color: cat.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat.score / 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(cat.color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cat.feedback,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    final tips = [
      '📚 Review React hooks deeply — useEffect, useMemo, useCallback.',
      '🗣️ Practice answering without filler words like "um" and "uh".',
      '⚡ Study time & space complexity for common algorithms.',
      '💡 Use the STAR method for behavioral questions.',
      '🔁 Do 2 mock interviews per week to build consistency.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: tips.asMap().entries.map((entry) {
          final isLast = entry.key == tips.length - 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.value,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: 8),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _FeedbackCategory {
  final String title;
  final int score;
  final Color color;
  final String feedback;

  const _FeedbackCategory(this.title, this.score, this.color, this.feedback);
}
