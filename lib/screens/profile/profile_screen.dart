import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            (user.displayName?.isNotEmpty == true)
                                ? user.displayName![0].toUpperCase()
                                : 'U',
                            style: TextStyle(fontSize: 40, color: cs.primary),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    user.displayName ?? 'No Name',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.email ?? '',
                    style:
                        TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),

                  // Info card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              Icon(Icons.email_outlined, color: cs.primary),
                          title: const Text('Email',
                              style: TextStyle(fontSize: 13)),
                          subtitle: Text(user.email ?? 'N/A'),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: Icon(Icons.verified_user_outlined,
                              color: cs.primary),
                          title: const Text('Email Verified',
                              style: TextStyle(fontSize: 13)),
                          subtitle: Text(user.emailVerified
                              ? 'Verified ✓'
                              : 'Not verified'),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: Icon(Icons.fingerprint_rounded,
                              color: cs.primary),
                          title: const Text('User ID',
                              style: TextStyle(fontSize: 13)),
                          subtitle: Text(user.uid,
                              style: const TextStyle(fontSize: 11)),
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
