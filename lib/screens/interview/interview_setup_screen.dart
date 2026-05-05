import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/App_auth_provider.dart';
import '../../providers/interview_provider.dart' as interview;
import 'interview_screen.dart';

class InterviewSetupScreen extends StatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  State<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends State<InterviewSetupScreen> {
  final _roleCtrl = TextEditingController();
  String _domain = 'technical';
  String _difficulty = 'medium';

  final _domains = ['technical', 'hr', 'behavioral', 'mixed'];
  final _difficulties = ['easy', 'medium', 'hard'];

  final _domainIcons = {
    'technical': Icons.code_rounded,
    'hr': Icons.people_outline_rounded,
    'behavioral': Icons.psychology_outlined,
    'mixed': Icons.shuffle_rounded,
  };

  @override
  void dispose() {
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _startInterview() async {
    if (_roleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job role')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    context.read<interview.InterviewProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewScreen(
          userId: auth.uid!,
          jobRole: _roleCtrl.text.trim(),
          domain: _domain,
          difficulty: _difficulty,
          resumeUrl: auth.userModel?.resumeUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Setup Interview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure your interview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your preferences and start practicing',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),

            // Job Role
            TextField(
              controller: _roleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Target Job Role',
                hintText: 'e.g. Flutter Developer, Data Scientist',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
            ),
            const SizedBox(height: 28),

            // Domain
            const Text('Interview Domain',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
              physics: const NeverScrollableScrollPhysics(),
              children: _domains
                  .map((d) => _OptionChip(
                        label: d[0].toUpperCase() + d.substring(1),
                        icon: _domainIcons[d]!,
                        selected: _domain == d,
                        onTap: () => setState(() => _domain = d),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),

            // Difficulty
            const Text('Difficulty',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: _difficulties.map((d) {
                final colors = {
                  'easy': Colors.green,
                  'medium': Colors.orange,
                  'hard': Colors.red,
                };
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _OptionChip(
                      label: d[0].toUpperCase() + d.substring(1),
                      icon: Icons.signal_cellular_alt_rounded,
                      selected: _difficulty == d,
                      onTap: () => setState(() => _difficulty = d),
                      color: colors[d],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startInterview,
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Start Interview',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The AI interviewer will conduct a voice interview. Ensure your microphone is ready.',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.7)),
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

class _OptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _OptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.12) : cs.surface,
          border: Border.all(
            color: selected ? activeColor : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? activeColor : cs.onSurface.withOpacity(0.5)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? activeColor : cs.onSurface,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
