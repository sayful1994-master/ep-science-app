import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'questions_admin_screen.dart';
import 'generator_screen.dart';
import 'users_admin_screen.dart';
import 'teachers_admin_screen.dart';
import 'books_admin_screen.dart';
import 'access_requests_screen.dart';
import 'announcements_screen.dart';
import 'audit_log_screen.dart';
import 'video_admin_screen.dart';
import 'app_control_screen.dart';
import 'study_admin_screen.dart';

/// E&P Science — Flutter Web admin console.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _items = [
    _NavItem('ড্যাশবোর্ড', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem('শিক্ষক ব্যবস্থাপনা', Icons.groups_outlined, Icons.groups),
    _NavItem('বই ও লাইব্রেরি', Icons.menu_book_outlined, Icons.menu_book),
    _NavItem('প্রশ্নব্যাংক', Icons.quiz_outlined, Icons.quiz),
    _NavItem('স্টাডি কনটেন্ট', Icons.school_outlined, Icons.school),
    _NavItem('ভিডিও ক্লাস', Icons.video_library_outlined, Icons.video_library),
    _NavItem('জেনারেটর', Icons.auto_awesome_outlined, Icons.auto_awesome),
    _NavItem('ইউজার', Icons.people_outline, Icons.people),
    _NavItem('অ্যাক্সেস রিকোয়েস্ট', Icons.verified_user_outlined, Icons.verified_user),
    _NavItem('ঘোষণা', Icons.campaign_outlined, Icons.campaign),
    _NavItem('অ্যাপ কন্ট্রোল', Icons.tune_outlined, Icons.tune),
    _NavItem('অডিট লগ', Icons.history_outlined, Icons.history),
  ];

  static const _pages = [
    AdminDashboardScreen(),
    TeachersAdminScreen(),
    BooksAdminScreen(),
    QuestionsAdminScreen(),
    StudyAdminScreen(),
    VideoAdminScreen(),
    GeneratorScreen(),
    UsersAdminScreen(),
    AccessRequestsScreen(),
    AnnouncementsScreen(),
    AppControlScreen(),
    AuditLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 860;
    final auth = context.watch<AuthProvider>();

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _sidebar(auth),
            Expanded(child: IndexedStack(index: _index, children: _pages)),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_items[_index].label),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout, size: 20),
          ),
        ],
      ),
      drawer: Drawer(child: _sidebar(auth, isDrawer: true)),
      body: IndexedStack(index: _index, children: _pages),
    );
  }

  Widget _sidebar(AuthProvider auth, {bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 250,
      color: AppColors.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.science,
                      color: AppColors.teal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConfig.appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Admin Control Panel',
                        style: TextStyle(color: AppColors.teal, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < _items.length; i++) _navTile(i, isDrawer),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.teal,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.name ?? 'Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          'Super Admin',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<AuthProvider>().logout(),
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTile(int i, bool isDrawer) {
    final selected = i == _index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          _items[i].icon,
          color: selected ? AppColors.teal : Colors.white70,
          size: 20,
        ),
        title: Text(
          _items[i].label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        onTap: () {
          setState(() => _index = i);
          if (isDrawer) Navigator.pop(context);
        },
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData active;
  const _NavItem(this.label, this.icon, this.active);
}
