import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  bool _uploadingPhoto = false;
  bool _uploadingResume = false;

  final _roles = [
    'Flutter Developer', 'Android Developer', 'iOS Developer',
    'Full Stack Developer', 'Data Scientist', 'ML Engineer',
    'Backend Developer', 'Frontend Developer', 'DevOps Engineer',
    'Product Manager', 'UI/UX Designer', 'Other',
  ];

  final _levels = ['fresher', 'junior', 'mid', 'senior'];

  Future<void> _uploadPhoto(UserModel user) async {
    setState(() => _uploadingPhoto = true);
    try {
      final url = await _storageService.uploadProfilePicture(widget.uid);
      if (url != null) {
        await _firestoreService.updateUser(widget.uid, {'photoUrl': url});
        if (mounted) {
          context.read<AuthProvider>().refreshUserModel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _uploadResume() async {
    setState(() => _uploadingResume = true);
    try {
      final url = await _storageService.uploadResume(widget.uid);
      if (url != null) {
        await _firestoreService.updateUser(widget.uid, {'resumeUrl': url});
        if (mounted) {
          context.read<AuthProvider>().refreshUserModel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume uploaded!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingResume = false);
    }
  }

  Future<void> _editTargetRole(UserModel user) async {
    String? selected = user.targetRole;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Target Role',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...(_roles.map((r) => ListTile(
                  title: Text(r),
                  leading: Radio<String>(
                    value: r,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  onTap: () => setState(() => selected = r),
                ))),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _firestoreService.updateUser(
                      widget.uid, {'targetRole': selected});
                  if (context.mounted) {
                    context.read<AuthProvider>().refreshUserModel();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editExperienceLevel(UserModel user) async {
    String selected = user.experienceLevel;
    final labelMap = {
      'fresher': 'Fresher (0 yrs)',
      'junior': 'Junior (1–2 yrs)',
      'mid': 'Mid-level (3–5 yrs)',
      'senior': 'Senior (5+ yrs)',
    };
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Experience Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...(_levels.map((l) => ListTile(
                  title: Text(labelMap[l] ?? l),
                  leading: Radio<String>(
                    value: l,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v!),
                  ),
                  onTap: () => setState(() => selected = l),
                ))),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _firestoreService.updateUser(
                      widget.uid, {'experienceLevel': selected});
                  if (context.mounted) {
                    context.read<AuthProvider>().refreshUserModel();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

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
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                    fontSize: 40, color: cs.primary),
                              )
                            : null,
                      ),
                      GestureDetector(
                        onTap: _uploadingPhoto
                            ? null
                            : () => _uploadPhoto(user),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.primary,
                          child: _uploadingPhoto
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user.displayName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user.email,
                      style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                          label: 'Sessions',
                          value: '${user.totalSessions}'),
                      Container(
                          width: 1,
                          height: 40,
                          color: cs.outlineVariant),
                      _StatItem(
                          label: 'Avg Score',
                          value:
                              '${user.avgScore.toStringAsFixed(0)}%'),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Profile settings card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _ProfileTile(
                          icon: Icons.work_outline_rounded,
                          label: 'Target Role',
                          value: user.targetRole ?? 'Not set',
                          onTap: () => _editTargetRole(user),
                        ),
                        const Divider(height: 1, indent: 56),
                        _ProfileTile(
                          icon: Icons.bar_chart_rounded,
                          label: 'Experience Level',
                          value: _levelLabel(user.experienceLevel),
                          onTap: () => _editExperienceLevel(user),
                        ),
                        const Divider(height: 1, indent: 56),
                        _ProfileTile(
                          icon: Icons.description_outlined,
                          label: 'Resume',
                          value: user.resumeUrl != null
                              ? 'Uploaded ✓'
                              : 'Not uploaded',
                          trailing: _uploadingResume
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : TextButton(
                                  onPressed: _uploadResume,
                                  child: Text(user.resumeUrl != null
                                      ? 'Replace'
                                      : 'Upload PDF'),
                                ),
                          onTap: null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _levelLabel(String level) {
    const m = {
      'fresher': 'Fresher (0 yrs)',
      'junior': 'Junior (1–2 yrs)',
      'mid': 'Mid-level (3–5 yrs)',
      'senior': 'Senior (5+ yrs)',
    };
    return m[level] ?? level;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(value),
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
