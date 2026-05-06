import 'package:flutter/material.dart';
import 'package:prepx/asset/feedback.dart';
import 'package:prepx/services/firestore_service.dart';
import '../asset/interview_model.dart';
import '../asset/interview_tile.dart';
import '../asset/action_tile.dart';
import 'interview_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage(
      {super.key,
      required String uid,
      required FirestoreService firestoreService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔹 ACTION ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ActionTile(
                icon: Icons.mic,
                title: "Start Interview",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InterviewPage(
                        interview: InterviewData.available[0],
                      ),
                    ),
                  );
                },
              ),
              ActionTile(
                icon: Icons.bar_chart,
                title: "Performance",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Performance page coming soon"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ActionTile(
                icon: Icons.menu_book,
                title: "Resources",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Resources page coming soon"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          /// 🔹 PAST INTERVIEWS
          const Text(
            "Your Past Interviews",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...InterviewData.past.map(
            (interview) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InterviewTile(
                logoPath: interview.logoPath,
                interviewName: interview.title,
                type: interview.typeLabel,
                date: interview.date ?? '',
                rating: interview.scoreLabel,
                status: interview.isCompleted ? "Completed" : "",
                description: interview.description,
                buttonText: "View Interview",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackPage(
                        interview: interview,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// 🔹 AVAILABLE INTERVIEWS
          const Text(
            "Pick Your Interview",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...InterviewData.available.map(
            (interview) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InterviewTile(
                logoPath: interview.logoPath,
                interviewName: interview.title,
                type: interview.typeLabel,
                date: interview.date ?? '',
                description: interview.description,
                buttonText: "Start Interview",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InterviewPage(interview: interview),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
