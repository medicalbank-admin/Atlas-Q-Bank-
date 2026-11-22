import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_logo.dart';

class AdminNavigationItem {
  final String title;
  final IconData icon;
  final String route;
  const AdminNavigationItem({required this.title, required this.icon, required this.route});
}

class AdminNavigationDrawer extends StatelessWidget {
  final String selectedRoute;
  final ValueChanged<String> onDestinationSelected;
  const AdminNavigationDrawer({super.key, required this.selectedRoute, required this.onDestinationSelected});

  static const List<AdminNavigationItem> items = [
    AdminNavigationItem(title: 'Dashboard', icon: Icons.dashboard_rounded, route: 'dashboard'),
    AdminNavigationItem(title: 'Students', icon: Icons.people_alt_rounded, route: 'students'),
    AdminNavigationItem(title: 'Academic Management', icon: Icons.school_rounded, route: 'academic'),
    AdminNavigationItem(title: 'Subscription Requests', icon: Icons.receipt_long_rounded, route: 'subscription_requests'),
    AdminNavigationItem(title: 'Learning Content', icon: Icons.library_books_rounded, route: 'content'),
    AdminNavigationItem(title: 'Exams & MCQs', icon: Icons.quiz_rounded, route: 'exams'),
    AdminNavigationItem(title: 'Subscription Plans', icon: Icons.workspace_premium_rounded, route: 'plans'),
    AdminNavigationItem(title: 'Notifications', icon: Icons.notifications_active_rounded, route: 'notifications'),
    AdminNavigationItem(title: 'Analytics & Reports', icon: Icons.analytics_rounded, route: 'analytics'),
    AdminNavigationItem(title: 'Settings', icon: Icons.settings_rounded, route: 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = items.indexWhere((item) => item.route == selectedRoute);
    return NavigationDrawer(
      backgroundColor: Colors.white,
      indicatorColor: AtlasColors.paleBlue,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) {
        if (index >= 0 && index < items.length) onDestinationSelected(items[index].route);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 27, 20, 23),
          child: Row(children: [
            const AtlasLogo(size: 49),
            const SizedBox(width: 13),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('THE ATLAS ACADEMY', style: TextStyle(color: AtlasColors.navy, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: .8)),
              SizedBox(height: 5),
              Text('Administrator workspace', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 11)),
            ])),
          ]),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20, color: AtlasColors.border),
        const Padding(
          padding: EdgeInsets.fromLTRB(27, 20, 16, 9),
          child: Text('WORKSPACE', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
        ),
        for (final item in items)
          NavigationDrawerDestination(
            icon: Icon(item.icon, color: AtlasColors.secondaryText),
            selectedIcon: Icon(item.icon, color: AtlasColors.royalBlue),
            label: Text(item.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AtlasColors.charcoal)),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(27, 24, 16, 22),
          child: Text('THE ATLAS ACADEMY  •  ADMIN', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .6)),
        ),
      ],
    );
  }
}
