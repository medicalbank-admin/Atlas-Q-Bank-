import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';

import 'admin_navigation_drawer.dart';

class AdminPanelLayout extends StatelessWidget {
  final String title;
  final String selectedRoute;
  final Widget child;
  final ValueChanged<String> onDestinationSelected;
  final List<Widget> actions;

  const AdminPanelLayout({
    super.key,
    required this.title,
    required this.selectedRoute,
    required this.child,
    required this.onDestinationSelected,
    this.actions = const [],
  });

  static const Color deepTeal = Color(0xFF071B3D);
  static const Color ivory = Color(0xFFF5F7FC);
  static const Color champagne = Color(0xFFE4BE68);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: deepTeal,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 8,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: deepTeal,
          ),
        ),
        actions: [
          ...actions,
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  deepTeal,
                  Color(0xFF174A91),
                  champagne,
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: SizedBox(
        width: 300,
        child: AdminNavigationDrawer(
          selectedRoute: selectedRoute,
          onDestinationSelected: onDestinationSelected,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 1000 ? 32.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 22,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1500,
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
