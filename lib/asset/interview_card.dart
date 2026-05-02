// widgets/interview_card.dart
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:prepx/asset/app_theme.dart';
import 'package:prepx/asset/common_widget.dart';
import 'package:prepx/asset/interview_model.dart';

class InterviewCard extends StatelessWidget {
  final InterviewModel interview;
  final VoidCallback onPressed;

  const InterviewCard({
    super.key,
    required this.interview,
    required this.onPressed,
  });

  Color get _typeColor {
    switch (interview.type) {
      case InterviewType.technical:
        return AppColors.info;
      case InterviewType.behavioral:
        return AppColors.warning;
      case InterviewType.mixed:
        return AppColors.accent;
      case InterviewType.hr:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppColors.gradientCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Top accent line
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_typeColor, _typeColor.withOpacity(0.3)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Company avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            interview.company[0],
                            style: TextStyle(
                              color: _typeColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              interview.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              interview.company,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge
                      if (interview.isCompleted)
                        StatusBadge(
                            label: 'Completed', color: AppColors.success)
                      else
                        StatusBadge(
                            label: interview.typeLabel, color: _typeColor),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Metadata row
                  Row(
                    children: [
                      if (interview.date != null) ...[
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(interview.date!,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(width: 12),
                      ],
                      const Icon(Icons.bar_chart_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(interview.level,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      if (interview.isCompleted && interview.score != null) ...[
                        const Spacer(),
                        ScoreRing(score: interview.score!, size: 48),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    interview.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Tech stack chips
                  if (interview.techStack.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: interview.techStack
                          .map((tech) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  tech,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: interview.isCompleted
                            ? const LinearGradient(
                                colors: [Color(0xFF2A2A42), Color(0xFF1E1E30)])
                            : AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onPressed,
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: Text(
                              interview.isCompleted
                                  ? 'View Feedback'
                                  : 'Start Interview',
                              style: TextStyle(
                                color: interview.isCompleted
                                    ? AppColors.textSecondary
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
