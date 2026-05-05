import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prepx/providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _obscurePass = true;

  static const _navy = Color(0xFF1A237E);

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            children: [
              // 🔥 LOGO
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: _navy,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'P', // 🔥 FIXED
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "PrepX", // 🔥 BRAND NAME
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // 🔥 CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(hintText: 'Email'),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: passCtrl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (auth.error != null)
                      Text(auth.error!,
                          style: const TextStyle(color: Colors.red)),

                    const SizedBox(height: 12),

                    // 🔥 EMAIL LOGIN
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                final ok =
                                    await context.read<AuthProvider>().signIn(
                                          email: emailCtrl.text.trim(),
                                          password: passCtrl.text,
                                        );

                                if (!mounted) return;

                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text(auth.error ?? 'Login failed')),
                                  );
                                }
                              },
                        child: auth.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Login'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔥 GOOGLE ONLY
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await context
                            .read<AuthProvider>()
                            .signInWithGoogle();

                        if (!mounted) return;

                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    auth.error ?? 'Google sign-in failed')),
                          );
                        }
                      },
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text("Continue with Google"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 REGISTER NAVIGATION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
