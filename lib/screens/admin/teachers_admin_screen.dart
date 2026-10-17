import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Teacher management — approval / authorization control + add-new-teacher.
///
/// Public app shows ONLY `is_approved == true`. Admin can approve or revoke
/// any teacher, and publish a new teacher immediately or save as a draft.
class TeachersAdminScreen extends StatefulWidget {
  const TeachersAdminScreen({super.key});

  @override
  State<TeachersAdminScreen> createState() => _TeachersAdminScreenState();
}

class _TeachersAdminScreenState extends State<TeachersAdminScreen> {
  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final pending = data.pendingTeachers;
    final approved = data.approvedTeachers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('শিক্ষক ব্যবস্থাপনা'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.person_add_alt, size: 16),
              label: const Text('নতুন শিক্ষক'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.teal, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'শিক্ষক তালিকা অনুমোদনভিত্তিক। “অনুমোদন দিন” করলে শিক্ষক পাবলিক অ্যাপের '
                    'শিক্ষক তালিকায় দেখা যাবে। ড্রাফট/অননুমোদিত শিক্ষক শুধু এখানে থাকবে।',
                    style: TextStyle(fontSize: 12.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle('অনুমোদনের অপেক্ষায় (${pending.length})'),
          if (pending.isEmpty)
            const EmptyState(
              icon: Icons.hourglass_empty,
              message: 'অনুমোদনের অপেক্ষায় কোনো শিক্ষক নেই',
            )
          else
            for (final t in pending) _teacherCard(context, data, t, pending: true),
          const SizedBox(height: 22),
          SectionTitle('অনুমোদিত শিক্ষক (${approved.length})'),
          if (approved.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              message: 'এখনো কোনো অনুমোদিত শিক্ষক নেই',
            )
          else
            for (final t in approved) _teacherCard(context, data, t, pending: false),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _teacherCard(
    BuildContext context,
    DataProvider data,
    Teacher t, {
    required bool pending,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: pending ? AppColors.gold : AppColors.green,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                backgroundImage:
                    t.photoUrl.isNotEmpty ? NetworkImage(t.photoUrl) : null,
                child: t.photoUrl.isEmpty
                    ? Text(
                        t.name.isNotEmpty ? t.name[0] : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (t.title.isNotEmpty)
                      Text(
                        t.title,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Pill(
                pending ? 'অপেক্ষমাণ' : 'অনুমোদিত',
                color: pending ? AppColors.gold : AppColors.green,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (t.qualification.isNotEmpty)
            _row(Icons.school_outlined, t.qualification),
          if (t.subjects.isNotEmpty) _row(Icons.menu_book_outlined, t.subjects),
          if (t.targetClasses.isNotEmpty)
            _row(Icons.class_outlined, t.targetClasses),
          if (t.phone.isNotEmpty) _row(Icons.call_outlined, t.phone),
          if (t.email.isNotEmpty) _row(Icons.mail_outline, t.email),
          if (t.location.isNotEmpty)
            _row(Icons.location_on_outlined, t.location),
          const SizedBox(height: 10),
          const Divider(height: 1),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'অনুমোদন / পাবলিক ভিজিবিলিটি',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: t.isApproved,
                activeThumbColor: AppColors.green,
                onChanged: (v) => data.setTeacherApproval(t.id, v),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _openEditor(context, existing: t),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('সম্পাদনা', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    '“${t.name}” কে মুছে ফেলতে চান?',
                  );
                  if (ok) await data.deleteTeacher(t.id);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppColors.danger,
                ),
                label: const Text(
                  'মুছুন',
                  style: TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  void _openEditor(BuildContext context, {Teacher? existing}) {
    showDialog(
      context: context,
      builder: (_) => _TeacherEditor(existing: existing),
    );
  }

  Future<bool> _confirm(BuildContext context, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('নিশ্চিত করুন'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('না'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('হ্যাঁ'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ─────────────────────────────────────────────────────────────
class _TeacherEditor extends StatefulWidget {
  final Teacher? existing;
  const _TeacherEditor({this.existing});

  @override
  State<_TeacherEditor> createState() => _TeacherEditorState();
}

class _TeacherEditorState extends State<_TeacherEditor> {
  final _name = TextEditingController();
  final _title = TextEditingController();
  final _qualification = TextEditingController();
  final _subjects = TextEditingController();
  final _classes = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _location = TextEditingController(text: AppConfig.instituteAddress);

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name.text = t?.name ?? '';
    _title.text = t?.title ?? '';
    _qualification.text = t?.qualification ?? '';
    _subjects.text = t?.subjects ?? '';
    _classes.text = t?.targetClasses ?? '';
    _phone.text = t?.phone ?? '';
    _email.text = t?.email ?? '';
    _location.text = (t?.location.isNotEmpty ?? false)
        ? t!.location
        : AppConfig.instituteAddress;
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _qualification.dispose();
    _subjects.dispose();
    _classes.dispose();
    _phone.dispose();
    _email.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'নতুন শিক্ষক যোগ করুন' : 'শিক্ষক সম্পাদনা',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _f(_name, 'শিক্ষকের নাম *'),
                      const SizedBox(height: 12),
                      _f(_title, 'পদবি / স্পেশালিটি'),
                      const SizedBox(height: 12),
                      _f(_qualification, 'যোগ্যতা'),
                      const SizedBox(height: 12),
                      _f(_subjects, 'বিষয় (কমা দিয়ে আলাদা করুন)'),
                      const SizedBox(height: 12),
                      _f(_classes, 'টার্গেট ক্লাস'),
                      const SizedBox(height: 12),
                      _f(_phone, 'মোবাইল নম্বর'),
                      const SizedBox(height: 12),
                      _f(_email, 'ইমেইল'),
                      const SizedBox(height: 12),
                      _f(_location, 'লোকেশন'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('বাতিল'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _save(context, publish: false),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('ড্রাফট সংরক্ষণ'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _save(context, publish: true),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('প্রকাশ করুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
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

  Widget _f(TextEditingController c, String label) => TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, isDense: true),
      );

  Future<void> _save(BuildContext context, {required bool publish}) async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('শিক্ষকের নাম দিন'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final data = context.read<DataProvider>();
    final t = Teacher(
      id: widget.existing?.id ?? 't_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      title: _title.text.trim(),
      qualification: _qualification.text.trim(),
      subjects: _subjects.text.trim(),
      targetClasses: _classes.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      location: _location.text.trim(),
      photoUrl: widget.existing?.photoUrl ?? '',
      isApproved: publish,
      linkedUserId: widget.existing?.linkedUserId ?? '',
      createdAt: widget.existing?.createdAt,
    );
    await data.saveTeacher(t);
    if (mounted) Navigator.pop(context);
  }
}
