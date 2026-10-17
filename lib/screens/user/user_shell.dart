import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import 'home_screen.dart';
import 'smart_tutor_screen.dart';
import 'teachers_screen.dart';
import '../ebook/ebook_store_screen.dart';
import '../video/video_class_screen.dart';
import 'profile_screen.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();

    // Feature-gated navigation: the Smart Generator (tutor) tab and the
    // Video Class tab appear only when the admin keeps them enabled.
    final showGenerator = data.smartGeneratorEnabled;
    final showVideo = data.feature('video_classes_enabled');

    final pages = <Widget>[
      const HomeScreen(),
      if (showGenerator) const SmartTutorScreen(),
      const TeachersScreen(),
      if (showVideo) const VideoClassScreen(),
      const EbookStoreScreen(),
      const ProfileScreen(),
    ];
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'হোম',
      ),
      if (showGenerator)
        const BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_outlined),
          activeIcon: Icon(Icons.auto_awesome),
          label: 'স্মার্ট টিউটর',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups_outlined),
        activeIcon: Icon(Icons.groups),
        label: 'শিক্ষক',
      ),
      if (showVideo)
        const BottomNavigationBarItem(
          icon: Icon(Icons.video_library_outlined),
          activeIcon: Icon(Icons.video_library),
          label: 'ভিডিও ক্লাস',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        activeIcon: Icon(Icons.menu_book),
        label: 'ই-বুক',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          auth.isGuest ? Icons.person_outline : Icons.account_circle_outlined,
        ),
        activeIcon: const Icon(Icons.account_circle),
        label: 'প্রোফাইল',
      ),
    ];

    // Guard the selected index in case a tab disappeared mid-session.
    final safeIndex = _index.clamp(0, items.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: items,
      ),
    );
  }
}
