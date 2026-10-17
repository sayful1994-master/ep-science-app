import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/duration_selector.dart';

/// User management — create / remove accounts, premium toggle with dynamic
/// duration, account-level download permission, and "mark as teacher"
/// (auto-moves the profile into the teacher list).
class UsersAdminScreen extends StatelessWidget {
  const UsersAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final users = data.users;

    return Scaffold(
      appBar: AppBar(title: const Text('ইউজার ম্যানেজমেন্ট')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, data),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('নতুন ইউজার'),
      ),
      body: users.isEmpty
          ? const EmptyState(message: 'কোনো ইউজার নেই')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _userCard(context, data, users[i]),
            ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, DataProvider data) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final pass = TextEditingController();
    String role = 'student';
    bool premium = false;
    int premiumMonths = 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('নতুন ইউজার তৈরি করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'নাম', isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  decoration:
                      const InputDecoration(labelText: 'ইমেইল / আইডি', isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'মোবাইল', isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pass,
                  decoration:
                      const InputDecoration(labelText: 'পাসওয়ার্ড', isDense: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'ভূমিকা', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('শিক্ষার্থী')),
                    DropdownMenuItem(value: 'teacher', child: Text('শিক্ষক')),
                    DropdownMenuItem(value: 'admin', child: Text('অ্যাডমিন')),
                  ],
                  onChanged: (v) => setSt(() => role = v ?? 'student'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: premium,
                  activeThumbColor: AppColors.gold,
                  title: const Text('প্রিমিয়াম অ্যাকাউন্ট', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text(
                    'নতুন মেম্বারকে কতদিনের মেয়াদে প্রিমিয়াম দিতে চান — নিচে নির্বাচন করুন।',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onChanged: (v) => setSt(() => premium = v),
                ),
                // ── Premium duration selector (new members) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  decoration: BoxDecoration(
                    color: premium
                        ? AppColors.gold.withValues(alpha: 0.08)
                        : AppColors.divider.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: premium
                          ? AppColors.gold.withValues(alpha: 0.5)
                          : AppColors.divider,
                    ),
                  ),
                  child: Opacity(
                    opacity: premium ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !premium,
                      child: DurationSelector(
                        selectedMonths: premiumMonths,
                        onSelect: (m) => setSt(() => premiumMonths = m),
                        title: 'প্রিমিয়াম মেয়াদ (নতুন মেম্বার)',
                        subtitle:
                            'নির্বাচিত মেয়াদ অনুযায়ী আজ থেকে প্রিমিয়াম অ্যাক্সেস চালু হবে ',
                        textColor: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('তৈরি করুন'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    if (name.text.trim().isEmpty || email.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('নাম ও ইমেইল অবশ্যই দিন'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }
    await data.createUser(
      name: name.text.trim(),
      email: email.text.trim(),
      phone: phone.text.trim(),
      password: pass.text.trim(),
      role: role,
      isPremium: premium,
      premiumMonths: premium ? premiumMonths : 0,
      intendedPlanMonths: premium ? premiumMonths : 0,
    );
    if (context.mounted) {
      final durTxt = premium
          ? ' • প্রিমিয়াম ${PlanDurations.label(premiumMonths)}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${name.text.trim()} তৈরি হয়েছে ✓ '
              '(পাসওয়ার্ড: ${pass.text.trim().isEmpty ? '1234' : pass.text.trim()})$durTxt'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _userCard(BuildContext context, DataProvider data, AppUser u) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: u.isPremium
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : AppColors.primaryBlue.withValues(alpha: 0.12),
                backgroundImage:
                    u.photoUrl.isNotEmpty ? NetworkImage(u.photoUrl) : null,
                child: u.photoUrl.isEmpty
                    ? Text(
                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                              u.isPremium ? AppColors.gold : AppColors.primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            u.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (u.isAdmin) ...[
                          const SizedBox(width: 6),
                          const Pill('ADMIN', color: AppColors.navy, filled: true),
                        ],
                        if (u.isTeacher) ...[
                          const SizedBox(width: 6),
                          const Pill('TEACHER', color: AppColors.teal, filled: true),
                        ],
                      ],
                    ),
                    Text(
                      u.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (u.phone.isNotEmpty)
                      Text(
                        u.phone,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
              Pill(
                u.isPremium ? 'প্রিমিয়াম' : 'ফ্রি',
                color: u.isPremium ? AppColors.gold : AppColors.textSecondary,
                filled: true,
              ),
              if (!u.isAdmin)
                IconButton(
                  tooltip: 'ইউজার মুছুন',
                  onPressed: () => _confirmDelete(context, data, u),
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                size: 16,
                color: AppColors.gold,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('প্রিমিয়াম স্ট্যাটাস', style: TextStyle(fontSize: 13)),
              ),
              // ── Duration grant / extend — ALWAYS available (existing
              //    members AND new members), regardless of current premium
              //    state. Extending an active plan adds to the expiry. ──
              if (!u.isAdmin)
                TextButton.icon(
                  onPressed: () => _activateDialog(context, data, u),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: Text(
                    u.hasActivePremium ? 'মেয়াদ বাড়ান' : 'মেয়াদ দিয়ে চালু',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              Switch(
                value: u.isPremium,
                activeThumbColor: AppColors.gold,
                onChanged: (v) => v
                    ? _activateDialog(context, data, u)
                    : data.revokePremium(u.uid),
              ),
            ],
          ),
          if (u.hasActivePremium) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    'মেয়াদ শেষ: ${_fmtDate(u.subscriptionEndDate)} '
                    '(${u.premiumDaysLeft} দিন বাকি)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (u.isPremium) ...[
            const SizedBox(height: 2),
            const Row(
              children: [
                SizedBox(width: 22),
                Expanded(
                  child: Text(
                    'প্রিমিয়াম মেয়াদ শেষ হয়ে গেছে — নতুন মেয়াদ দিন।',
                    style: TextStyle(fontSize: 11.5, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 1),
          Row(
            children: [
              const Icon(Icons.download_outlined, size: 16, color: AppColors.teal),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'অ্যাকাউন্ট-লেভেল ডাউনলোড অনুমতি',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Switch(
                value: u.canDownloadPdf,
                activeThumbColor: AppColors.teal,
                onChanged: (v) => data.toggleUserDownload(u.uid, v),
              ),
            ],
          ),
          if (!u.isAdmin) ...[
            const Divider(height: 1),
            Row(
              children: [
                const Icon(Icons.groups_outlined,
                    size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'শিক্ষক হিসেবে চিহ্নিত করুন',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Switch(
                  value: u.isTeacher,
                  activeThumbColor: AppColors.primaryBlue,
                  onChanged: (v) async {
                    if (v) {
                      await data.markAsTeacher(u.uid);
                    } else {
                      await data.unmarkTeacher(u.uid);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            v
                                ? '${u.name} → শিক্ষক তালিকায় যুক্ত হয়েছে'
                                : '${u.name} → শিক্ষক তালিকা থেকে সরানো হয়েছে',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, DataProvider data, AppUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ইউজার মুছবেন?'),
        content: Text('${u.name} (${u.email}) স্থায়ীভাবে মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await data.deleteUser(u.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${u.name} মুছে ফেলা হয়েছে'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _activateDialog(
      BuildContext context, DataProvider data, AppUser u) async {
    final extending = u.hasActivePremium;
    final months = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('${u.name} — মেয়াদ নির্বাচন'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              extending
                  ? 'বর্তমান মেয়াদ শেষ: ${_fmtDate(u.subscriptionEndDate)} '
                      '(${u.premiumDaysLeft} দিন বাকি)।\n'
                      'নির্বাচিত মেয়াদ বর্তমান মেয়াদের সাথে যোগ হবে।'
                  : 'নির্বাচিত মেয়েদের জন্য আজ থেকে প্রিমিয়াম চালু হবে।',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          for (final m in PlanDurations.months)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m),
              child: Text(
                '${PlanDurations.label(m)} (${PlanDurations.daysFor(m)} দিন)'
                '${extending ? ' — যোগ করুন' : ''}',
              ),
            ),
        ],
      ),
    );
    if (months == null) return;
    await data.activateSubscription(
      u.uid,
      months: months,
      days: PlanDurations.daysFor(months),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${u.name}-এর প্রিমিয়াম ${PlanDurations.label(months)} '
            '${extending ? 'বর্ধিত হয়েছে' : 'সক্রিয় হয়েছে'} ✓',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Formats an ISO date as yyyy-MM-dd (falls back to a dash).
  static String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    return iso.split('T').first;
  }
}
