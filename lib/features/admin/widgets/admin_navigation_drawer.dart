import 'package:flutter/material.dart';

class AdminNavigationItem {
  final String title;
  final IconData icon;
  final String route;

  const AdminNavigationItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class AdminNavigationDrawer extends StatelessWidget {
  final String selectedRoute;
  final ValueChanged<String> onDestinationSelected;

  const AdminNavigationDrawer({
    super.key,
    required this.selectedRoute,
    required this.onDestinationSelected,
  });

  static const Color deepTeal = Color(0xFF123F46);
  static const Color oceanTeal = Color(0xFF28777B);
  static const Color champagne = Color(0xFFD8B66B);

  static const List<AdminNavigationItem> items = [
    AdminNavigationItem(
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
      route: 'dashboard',
    ),
    AdminNavigationItem(
      title: 'Students',
      icon: Icons.people_alt_rounded,
      route: 'students',
    ),
    AdminNavigationItem(
      title: 'Academic Management',
      icon: Icons.school_rounded,
      route: 'academic',
    ),
    AdminNavigationItem(
      title: 'Subscription Requests',
      icon: Icons.receipt_long_rounded,
      route: 'subscription_requests',
    ),
    AdminNavigationItem(
      title: 'Learning Content',
      icon: Icons.library_books_rounded,
      route: 'content',
    ),
    AdminNavigationItem(
      title: 'Exams & MCQs',
      icon: Icons.quiz_rounded,
      route: 'exams',
    ),
    AdminNavigationItem(
      title: 'Subscription Plans',
      icon: Icons.workspace_premium_rounded,
      route: 'plans',
    ),
    AdminNavigationItem(
      title: 'Notifications',
      icon: Icons.notifications_active_rounded,
      route: 'notifications',
    ),
    AdminNavigationItem(
      title: 'Analytics & Reports',
      icon: Icons.analytics_rounded,
      route: 'analytics',
    ),
    AdminNavigationItem(
      title: 'Settings',
      icon: Icons.settings_rounded,
      route: 'settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = items.indexWhere(
      (item) => item.route == selectedRoute,
    );

    return NavigationDrawer(
      backgroundColor: Colors.white,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) {
        if (index >= 0 && index < items.length) {
          onDestinationSelected(items[index].route);
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [deepTeal, oceanTeal],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: champagne,
                  size: 27,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'THE ATLAS ACADEMY',
                style: TextStyle(
                  color: deepTeal,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Administration Panel',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 20, 16, 10),
          child: Text(
            'MAIN MENU',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        for (final item in items)
          NavigationDrawerDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(
              item.icon,
              color: deepTeal,
            ),
            label: Text(
              item.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 24, 16, 20),
          child: Text(
            'THE ATLAS ACADEMY • ADMIN',
            style: TextStyle(
              color: Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
