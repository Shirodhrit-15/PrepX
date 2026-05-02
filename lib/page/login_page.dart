import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      resizeToAvoidBottomInset:
          true, // 👈 allows the screen to resize on keyboard open
      body: SafeArea(
        child: SingleChildScrollView(
          // 👈 makes the form scrollable
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "PrepX - AI Interviews",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Full Name
              _buildField("Full Name"),
              const SizedBox(height: 16),

              // Email
              _buildField("Email"),
              const SizedBox(height: 16),

              // Password
              _buildField("Password", obscure: true),
              const SizedBox(height: 24),

              // Upload Buttons
              _buildUploadButton("Upload Profile Picture"),
              const SizedBox(height: 16),
              _buildUploadButton("Upload Resume PDF"),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Space below for keyboard
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, {bool obscure = false}) => TextField(
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF2A2A3D),
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    style: const TextStyle(color: Colors.white),
  );

  Widget _buildUploadButton(String label) => OutlinedButton.icon(
    onPressed: () {},
    icon: const Icon(Icons.upload_file, color: Colors.white),
    label: Text(label, style: const TextStyle(color: Colors.white)),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.white38),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
