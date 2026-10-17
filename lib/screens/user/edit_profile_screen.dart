import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Edit profile — change display name, upload a profile photo and update the
/// class / job selection.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  String? _studyFor;
  String? _level;
  Uint8List? _photoBytes;
  bool _saving = false;

  static const _classLevels = [
    'নবম শ্রেণি',
    'দশম শ্রেণি',
    'একাদশ শ্রেণি',
    'দ্বাদশ শ্রেণি',
    'এডমিশন / ভর্তি প্রস্তুতি',
  ];
  static const _jobLevels = [
    'বিসিএস',
    'ব্যাংক',
    'প্রাইমারি শিক্ষক',
    'সরকারি চাকরি',
    'অন্যান্য',
  ];

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name = TextEditingController(text: u?.name ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _studyFor = (u?.studyFor.isEmpty ?? true) ? null : u!.studyFor;
    _level = (u?.studyLevel.isEmpty ?? true) ? null : u!.studyLevel;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি নির্বাচন করা যায়নি: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নাম খালি রাখা যাবে না।')),
      );
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      // A real backend would upload the bytes and store the returned URL.
      photoUrl: _photoBytes != null ? _photoDataUri(_photoBytes!) : null,
    );
    if (_studyFor != null && _level != null) {
      await auth.completeOnboarding(studyFor: _studyFor!, studyLevel: _level!);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('প্রোফাইল আপডেট হয়েছে ✓'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  String _photoDataUri(Uint8List bytes) =>
      'data:image/png;base64,${base64Encode(bytes)}';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final levels = _studyFor == 'job' ? _jobLevels : _classLevels;

    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল সম্পাদনা')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.bg,
                  backgroundImage: _photoBytes != null
                      ? MemoryImage(_photoBytes!)
                      : (auth.user?.photoUrl.isNotEmpty ?? false)
                      ? NetworkImage(auth.user!.photoUrl)
                      : null,
                  child: (_photoBytes == null &&
                          (auth.user?.photoUrl.isEmpty ?? true))
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.textSecondary,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined, size: 17),
              label: const Text('প্রোফাইল ছবি পরিবর্তন করুন'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'পূর্ণ নাম',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'মোবাইল নম্বর',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'কীসের জন্য প্রস্তুতি নিচ্ছেন?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _choice(
                  'একাডেমিক স্টাডি',
                  Icons.school_outlined,
                  _studyFor == 'class',
                  () => setState(() {
                    _studyFor = 'class';
                    _level = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _choice(
                  'চাকুরি প্রস্তুতি',
                  Icons.workspace_premium_outlined,
                  _studyFor == 'job',
                  () => setState(() {
                    _studyFor = 'job';
                    _level = null;
                  }),
                ),
              ),
            ],
          ),
          if (_studyFor != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: levels.map((l) {
                final sel = _level == l;
                return ChoiceChip(
                  label: Text(l, style: const TextStyle(fontSize: 12.5)),
                  selected: sel,
                  onSelected: (_) => setState(() => _level = l),
                  selectedColor: AppColors.teal.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 26),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('সংরক্ষণ করুন'),
          ),
        ],
      ),
    );
  }

  Widget _choice(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.divider,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.teal, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
