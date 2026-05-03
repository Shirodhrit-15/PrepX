import 'package:flutter/material.dart';
import '../../models/result_model.dart';
import '../../services/firestore_service.dart';

class ResultsScreen extends StatelessWidget {
  final String sessionId;

  const ResultsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Results'),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: StreamBuilder<ResultModel?>(
        stream: firestoreService.watchResult(sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your results...'),
                ],
              ),
            );
          }
          final result = snapshot.data;
          if (result == null) {
            return const Center(child: Text('Results not available yet'));
          }
          return _ResultsBody(result: result);
        },
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  final ResultModel result;

  const _ResultsBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = result.overallScore;
    final scoreColor = score >= 75
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scoreColor.withOpacity(0.2),
                  scoreColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const Text('Overall Score',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _ScoreLabel(score: score),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category scores
          if (result.categoryScores.isNotEmpty) ...[
            const Text('Category Breakdown',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...result.categoryScores.entries.map(
              (e) => _CategoryBar(
                  label: e.key[0].toUpperCase() + e.key.substring(1),
                  score: e.value),
            ),
            const SizedBox(height: 24),
          ],

          // Strengths
          _FeedbackSection(
            icon: Icons.thumb_up_outlined,
            title: 'Strengths',
            items: result.strengths,
            color: Colors.green,
          ),
          const SizedBox(height: 16),

          // Improvements
          _FeedbackSection(
            icon: Icons.trending_up_rounded,
            title: 'Areas to Improve',
            items: result.improvements,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),

          // General feedback
          if (result.generalFeedback.isNotEmpty) ...[
            _FeedbackSection(
              icon: Icons.comment_outlined,
              title: 'AI Feedback',
              items: result.generalFeedback,
              color: cs.primary,
            ),
            const SizedBox(height: 16),
          ],

          // Per question breakdown
          if (result.questionResults.isNotEmpty) ...[
            const Text('Question Breakdown',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...result.questionResults
                .asMap()
                .entries
                .map((e) => _QuestionCard(
                    index: e.key + 1, qResult: e.value)),
          ],
          const SizedBox(height: 32),

          // Try again button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/home'),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Try Another Interview'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreLabel extends StatelessWidget {
  final int score;
  const _ScoreLabel({required this.score});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    if (score >= 85) {
      label = '🏆 Excellent';
      color = Colors.green;
    } else if (score >= 70) {
      label = '👍 Good';
      color = Colors.green;
    } else if (score >= 55) {
      label = '📈 Average';
      color = Colors.orange;
    } else {
      label = '💪 Needs Practice';
      color = Colors.red;
    }
    return Chip(
      label: Text(label, style: TextStyle(color: color)),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int score;

  const _CategoryBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text('$score%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: cs.surfaceContainerHighest,
              color: score >= 70 ? Colors.green : Colors.orange,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;

  const _FeedbackSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuestionResult qResult;

  const _QuestionCard({required this.index, required this.qResult});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = qResult.score;
    final scoreColor = score >= 7
        ? Colors.green
        : score >= 5
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor.withOpacity(0.15),
          child: Text(
            '$score',
            style: TextStyle(
                color: scoreColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Q$index: ${qResult.question}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Score: $score / 10',
          style: TextStyle(fontSize: 12, color: scoreColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Your answer:', value: qResult.answer),
                const SizedBox(height: 8),
                _InfoRow(label: 'Feedback:', value: qResult.feedback),
                const SizedBox(height: 8),
                _InfoRow(
                    label: 'Ideal answer:', value: qResult.idealAnswer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
