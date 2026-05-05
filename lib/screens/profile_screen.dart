import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    _nameCtrl = TextEditingController(text: app.userName);
  }

  Future<void> _pickImage(AppProvider app) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      app.updateProfileImagePath(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            InkWell(
              onTap: () => _pickImage(app),
              borderRadius: BorderRadius.circular(50),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                backgroundImage: app.profileImagePath.isNotEmpty ? FileImage(File(app.profileImagePath)) : null,
                child: app.profileImagePath.isEmpty
                    ? Text(app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                app.updateUserName(val.isEmpty ? 'User' : val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabled: false,
              ),
              controller: TextEditingController(text: app.email),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.mapPin, color: AppColors.secondary),
                ),
                title: const Text('Total Distance'),
                trailing: Text('${app.distance} km', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ),
            ),
            const SizedBox(height: 32),
            Align(alignment: Alignment.centerLeft, child: Text('Earned Badges', style: theme.textTheme.titleLarge)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: app.achievements.where((a) => a['unlocked'] == true).map((badge) {
                  return Chip(
                    avatar: Icon(badge['icon'] as IconData, color: AppColors.yellow, size: 18),
                    label: Text(badge['title']),
                    backgroundColor: AppColors.yellow.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
