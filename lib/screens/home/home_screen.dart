// ignore_for_file: deprecated_member_use, non_constant_identifier_names, prefer_const_literals_to_create_immutables

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/session_model.dart';
import '../interview/interview_setup_screen.dart';
import '../results/results_screen.dart';
import '../profile/profile_screen.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _primary = Color(0xFF6C63FF);
const _bg = Color(0xFFF5F6FA);
const _card = Colors.white;
const _green = Color(0xFF22C55E);
const _orange = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _textPrimary = Color(0xFF0D0D2B);
const _textSub = Color(0xFF9CA3AF);

// ── Shell ─────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _fs = FirestoreService();
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.uid;

    final pages = [
      _DashboardPage(uid: uid, fs: _fs),
      const InterviewSetupScreen(),
      ProfileScreen(uid: uid),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: pages[_navIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: _card,
        indicatorColor: _primary.withOpacity(0.12),
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded, color: _primary),
            label: 'Interview',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Page ────────────────────────────────────────────────────────────
class _DashboardPage extends StatelessWidget {
  final String uid;
  final FirestoreService fs;

  const _DashboardPage({required this.uid, required this.fs});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;
    final firstName = user?.displayName.split(' ').first ?? 'there';

    return StreamBuilder<List<SessionModel>>(
      stream: fs.watchUserSessions(uid),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        final completed =
            sessions.where((s) => s.status == SessionStatus.completed).toList();

        // ── Derived stats ──
        final totalSessions = completed.length;

        // avg score from userModel (already tracked server-side)
        final avgScore = user?.avgScore ?? 0.0;

        // topics = unique domains
        final topics = completed.map((s) => s.domain).toSet().length;

        // total time
        final totalSecs =
            completed.fold<int>(0, (sum, s) => sum + s.durationSeconds);
        final totalTimeStr = _formatDuration(totalSecs);

        // weekly chart data: last 7 days, avg score per day
        final chartPoints = _buildWeeklyChart(completed);

        // domain breakdown for donut
        final domainMap = <String, int>{};
        for (final s in completed) {
          domainMap[s.domain] = (domainMap[s.domain] ?? 0) + 1;
        }

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, $firstName! 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Track your learning journey and improve every day.',
                              style: TextStyle(fontSize: 13, color: _textSub),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // New Interview CTA
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InterviewSetupScreen()),
                        ),
                        icon: const Icon(Icons.mic_rounded, size: 16),
                        label: const Text('New Interview'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 4 Stat cards ──
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      _StatCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconBg: const Color(0xFFEDE9FF),
                        iconColor: _primary,
                        value: '$totalSessions',
                        label: 'Total Sessions',
                        delta: '+${max(0, totalSessions - 3)} from last week',
                      ),
                      _StatCard(
                        icon: Icons.edit_note_rounded,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: _green,
                        value: '${avgScore.toStringAsFixed(0)}%',
                        label: 'Avg Score',
                        delta: '+8% from last week',
                      ),
                      _StatCard(
                        icon: Icons.flag_outlined,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: _orange,
                        value: '$topics',
                        label: 'Topics Covered',
                        delta: '${max(0, topics - 2)} new this week',
                      ),
                      _StatCard(
                        icon: Icons.access_time_rounded,
                        iconBg: const Color(0xFFDBEAFE),
                        iconColor: const Color(0xFF3B82F6),
                        value: totalTimeStr,
                        label: 'Total Time',
                        delta: 'Keep it up!',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Score Over Time ──
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Score Over Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Score %',
                                style: TextStyle(fontSize: 12, color: _textSub),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _LineChart(points: chartPoints),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Top Topics ──
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Top Topics',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'View All',
                                style: TextStyle(color: _primary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DonutChart(
                          domainMap: domainMap.isEmpty
                              ? {
                                  'Technical': 35,
                                  'HR': 25,
                                  'Behavioral': 20,
                                  'Mixed': 20,
                                }
                              : domainMap,
                          total: topics == 0 ? 18 : topics,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Recent Sessions ──
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Recent Sessions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'View All',
                                style: TextStyle(color: _primary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator())
                        else if (completed.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No sessions yet.\nStart your first interview!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _textSub, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...completed.take(4).map(
                                (s) => _SessionRow(
                                  session: s,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ResultsScreen(sessionId: s.sessionId),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Learning Strengths ──
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Learning Strengths',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StrengthChip('Problem Solving'),
                            _StrengthChip('System Design'),
                            _StrengthChip('DBMS Concepts'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Areas to Improve ──
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Areas to Improve',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ImprovementBar(
                            label: 'Communication', percent: 0.45, color: _red),
                        const SizedBox(height: 8),
                        _ImprovementBar(
                            label: 'Problem Solving',
                            percent: 0.60,
                            color: _orange),
                        const SizedBox(height: 8),
                        _ImprovementBar(
                            label: 'Algorithms', percent: 0.65, color: _orange),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── AI Tutor Insight ──
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: _primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'AI Tutor Insight',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          totalSessions == 0
                              ? 'Start your first interview to get personalized insights and recommendations!'
                              : 'You\'re doing great! Focus more on weak areas. I recommend ${max(1, 3 - totalSessions ~/ 3)} personalized sessions this week.',
                          style: const TextStyle(
                              fontSize: 13, color: _textSub, height: 1.5),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const InterviewSetupScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Start Practice'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ──

  String _formatDuration(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  List<_ChartPoint> _buildWeeklyChart(List<SessionModel> sessions) {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Map weekday (1=Mon..7=Sun) to label index
    final result = <_ChartPoint>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = days[day.weekday - 1];
      final daySessions = sessions.where((s) {
        return s.createdAt.year == day.year &&
            s.createdAt.month == day.month &&
            s.createdAt.day == day.day;
      }).toList();
      double avg = 0;
      if (daySessions.isNotEmpty) {
        // use durationSeconds as a proxy for score (replace with actual score field if available)
        avg = daySessions.length * 15.0; // placeholder
        avg = avg.clamp(0, 100);
      }
      result.add(_ChartPoint(label: label, value: avg));
    }
    return result;
  }
}

// ── Reusable card wrapper ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String delta;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _textSub),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded,
                        size: 11, color: _green),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        delta,
                        style: const TextStyle(fontSize: 10, color: _green),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session Row ───────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;

  const _SessionRow({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final durMin = session.durationSeconds ~/ 60;
    final durSec = session.durationSeconds % 60;
    final dateStr = DateFormat('MMM d, h:mm a').format(session.createdAt);

    // Placeholder score derived from duration
    final score = ((session.durationSeconds / 600) * 100).clamp(0, 99).toInt();
    final scoreColor = score >= 80
        ? _green
        : score >= 60
            ? _orange
            : _red;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.jobRole,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    session.domain,
                    style: const TextStyle(fontSize: 11, color: _textSub),
                  ),
                ],
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 11, color: _textSub),
            ),
            const SizedBox(width: 8),
            Text(
              '${durMin}m ${durSec}s',
              style: const TextStyle(fontSize: 11, color: _textSub),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$score%',
                style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Strength Chip ─────────────────────────────────────────────────────────────

class _StrengthChip extends StatelessWidget {
  final String label;
  const _StrengthChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_rounded, size: 12, color: _primary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: _primary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Improvement Bar ───────────────────────────────────────────────────────────

class _ImprovementBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _ImprovementBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: _textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(percent * 100).toInt()}%',
          style: const TextStyle(fontSize: 11, color: _textSub),
        ),
      ],
    );
  }
}

// ── Line Chart ────────────────────────────────────────────────────────────────

class _ChartPoint {
  final String label;
  final double value;
  const _ChartPoint({required this.label, required this.value});
}

class _LineChart extends StatelessWidget {
  final List<_ChartPoint> points;
  const _LineChart({required this.points});

  static const _leftPad = 36.0;
  static const _bottomPad = 28.0;
  static const _topPad = 8.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final chartW = w - _leftPad;
          final chartH = h - _bottomPad - _topPad;
          final n = points.length;

          // Precompute dot positions
          final positions = <Offset>[
            for (int i = 0; i < n; i++)
              Offset(
                _leftPad + (n > 1 ? (i / (n - 1)) : 0) * chartW,
                _topPad + chartH - (points[i].value / 100) * chartH,
              ),
          ];

          return Stack(
            children: [
              // Chart lines + fill
              CustomPaint(
                size: Size(w, h),
                painter: _LineChartPainter(
                  points: points,
                  positions: positions,
                  chartH: chartH,
                  topPad: _topPad,
                ),
              ),
              // Y-axis labels
              ...List.generate(5, (i) {
                final pct = i * 25;
                final y = _topPad + chartH - (pct / 100) * chartH;
                return Positioned(
                  left: 0,
                  top: y - 6,
                  child: Text(
                    '$pct%',
                    style:
                        const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
                  ),
                );
              }),
              // X-axis labels
              if (n > 0)
                ...List.generate(n, (i) {
                  return Positioned(
                    left: positions[i].dx - 12,
                    bottom: 0,
                    width: 24,
                    child: Text(
                      points[i].label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF9CA3AF)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final List<Offset> positions;
  final double chartH;
  final double topPad;

  _LineChartPainter({
    required this.points,
    required this.positions,
    required this.chartH,
    required this.topPad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH - (i / 4) * chartH;
      canvas.drawLine(Offset(36, y), Offset(size.width, y), gridPaint);
    }

    if (positions.length < 2) return;

    // Fill
    final fillPath = Path();
    fillPath.moveTo(positions.first.dx, topPad + chartH);
    for (final p in positions) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(positions.last.dx, topPad + chartH);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _primary.withOpacity(0.18),
            _primary.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(positions.first.dx, positions.first.dy);
    for (int i = 1; i < positions.length; i++) {
      linePath.lineTo(positions[i].dx, positions[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    for (final p in positions) {
      canvas.drawCircle(p, 4, Paint()..color = _primary);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.points != points;
}

// ── Donut Chart ───────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final Map<String, int> domainMap;
  final int total;

  const _DonutChart({required this.domainMap, required this.total});

  static const _colors = [
    Color(0xFF6C63FF),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFF9CA3AF),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = domainMap.entries.toList();
    final totalCount = entries.fold<int>(0, (s, e) => s + e.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(90, 90),
                painter: _DonutPainter(
                  values: entries.map((e) => e.value.toDouble()).toList(),
                  colors: _colors,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const Text(
                    'Topics',
                    style: TextStyle(fontSize: 9, color: _textSub),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < entries.length && i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _capitalize(entries[i].key),
                          style: const TextStyle(
                              fontSize: 11, color: _textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${((entries[i].value / totalCount) * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeW = 14.0;
    final total = values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return;

    double startAngle = -pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeW / 2),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}
