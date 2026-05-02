// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prepx/asset/app_theme.dart';
import 'package:prepx/asset/auth_service.dart';
import 'package:prepx/page/dashboard_page.dart';
import 'package:prepx/asset/interview_model.dart';
import 'package:prepx/page/auth_page.dart';
import 'package:prepx/page/interview_page.dart';

// ─── Firebase setup ──────────────────────────────────────────────────────────
// When you're ready to connect Firebase:
// 1. Add to pubspec.yaml:
//      firebase_core: ^2.x.x
//      firebase_auth: ^4.x.x
//      cloud_firestore: ^4.x.x
// 2. Run: flutterfire configure
// 3. Uncomment the lines below:
//
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
//
// And replace the runApp call with:
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(const PrepXApp());
// }
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PrepXApp());
}

class PrepXApp extends StatelessWidget {
  const PrepXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrepX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGuard(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _route(const AuthPage());
          case '/dashboard':
            return _route(const DashboardPage());
          case '/interview':
            final interview = settings.arguments as InterviewModel?;
            return _route(InterviewPage(
              interview: interview ?? InterviewData.available[0],
            ));
          default:
            return _route(const AuthPage());
        }
      },
    );
  }

  PageRouteBuilder _route(Widget page) => PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );
}

// ── Auth Guard: redirects based on login state ──────────────────────────────
class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChange);
  }

  void _onAuthChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show splash briefly then route
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _authService.isLoggedIn ? const DashboardPage() : const AuthPage(),
    );
  }
}
