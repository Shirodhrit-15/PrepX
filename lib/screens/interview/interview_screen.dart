import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/interview_provider.dart';
import '../results/results_screen.dart';

class InterviewScreen extends StatefulWidget {
  final String userId;
  final String jobRole;
  final String domain;
  final String difficulty;
  final String? resumeUrl;

  const InterviewScreen({
    super.key,
    required this.userId,
    required this.jobRole,
    required this.domain,
    required this.difficulty,
    this.resumeUrl,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  @override
  void initState() {
    super.initState();
    // Start interview after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InterviewProvider>().startInterview(
            userId: widget.userId,
            jobRole: widget.jobRole,
            domain: widget.domain,
            difficulty: widget.difficulty,
            resumeUrl: widget.resumeUrl,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final interview = context.watch<InterviewProvider>();
    final phase = interview.phase;

    // Navigate to results when done
    if (phase == InterviewPhase.done &&
        interview.currentResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              sessionId: interview.currentSession!.sessionId,
            ),
          ),
        );
        interview.reset();
      });
    }

    return WillPopScope(
      onWillPop: () async {
        if (phase == InterviewPhase.active) {
          final confirm = await _showEndDialog(context);
          if (confirm) await interview.endInterview();
          return confirm;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(widget.jobRole),
          actions: [
            if (phase == InterviewPhase.active)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 16),
                  label: Text(interview.formattedDuration),
                  backgroundColor: cs.primaryContainer,
                ),
              ),
          ],
        ),
        body: _buildBody(context, interview, cs),
        bottomNavigationBar: phase == InterviewPhase.active
            ? _buildBottomBar(context, interview, cs)
            : null,
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, InterviewProvider interview, ColorScheme cs) {
    switch (interview.phase) {
      case InterviewPhase.connecting:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to AI interviewer...'),
            ],
          ),
        );

      case InterviewPhase.analyzing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing your interview...'),
              SizedBox(height: 8),
              Text(
                'Gemini AI is reviewing your responses',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );

      case InterviewPhase.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 60, color: cs.error),
                const SizedBox(height: 16),
                const Text('Something went wrong',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  interview.errorMessage ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    interview.reset();
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        );

      case InterviewPhase.active:
        return Column(
          children: [
            // Active indicator
            Container(
              width: double.infinity,
              color: cs.primaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PulsingDot(color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Interview in progress',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            // Transcript
            Expanded(
              child: interview.liveTranscript.isEmpty
                  ? Center(
                      child: Text(
                        'The AI interviewer will speak first...',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      reverse: false,
                      itemCount: interview.liveTranscript.length,
                      itemBuilder: (_, i) {
                        final msg = interview.liveTranscript[i];
                        return _TranscriptBubble(
                          role: msg['role'] ?? '',
                          text: msg['text'] ?? '',
                        );
                      },
                    ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(
      BuildContext context, InterviewProvider interview, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await _showEndDialog(context);
          if (confirm) await interview.endInterview();
        },
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('End Interview'),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.error,
          foregroundColor: cs.onError,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }

  Future<bool> _showEndDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('End Interview?'),
            content: const Text(
              'Your session will be ended and results will be analyzed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('End Session'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _TranscriptBubble extends StatelessWidget {
  final String role;
  final String text;

  const _TranscriptBubble({required this.role, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              child: const Icon(Icons.smart_toy_outlined, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14).copyWith(
                  bottomRight:
                      isUser ? Radius.zero : const Radius.circular(14),
                  bottomLeft:
                      isUser ? const Radius.circular(14) : Radius.zero,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? cs.onPrimary : cs.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.5 + _ctrl.value * 0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
