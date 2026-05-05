import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prepx/providers/auth_provider.dart' as app;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static const _navy = Color(0xFF1A237E);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<app.AuthProvider>();

    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app.AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 🔥 LOGO
                Container(
                  height: 72,
                  width: 72,
                  decoration: const BoxDecoration(
                    color: _navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'P',
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
                  "PrepX",
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
                      // NAME
                      TextFormField(
                        controller: _nameCtrl,
                        decoration:
                            const InputDecoration(hintText: 'Full Name'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter name' : null,
                      ),

                      const SizedBox(height: 14),

                      // EMAIL
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Email'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter email' : null,
                      ),

                      const SizedBox(height: 14),

                      // PASSWORD
                      TextFormField(
                        controller: _passCtrl,
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
                        validator: (v) => v == null || v.length < 6
                            ? 'Min 6 characters'
                            : null,
                      ),

                      const SizedBox(height: 14),

                      // CONFIRM PASSWORD
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) => v != _passCtrl.text
                            ? 'Passwords do not match'
                            : null,
                      ),

                      const SizedBox(height: 20),

                      if (auth.error != null)
                        Text(auth.error!,
                            style: const TextStyle(color: Colors.red)),

                      const SizedBox(height: 12),

                      // 🔥 REGISTER BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
                          child: auth.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Sign Up"),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text("or"),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 🔥 GOOGLE ONLY
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await context
                              .read<app.AuthProvider>()
                              .signInWithGoogle();

                          if (!mounted) return;

                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      auth.error ?? "Google sign-in failed")),
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

                // 🔥 BACK TO LOGIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Login",
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
      ),
    );
  }
}
