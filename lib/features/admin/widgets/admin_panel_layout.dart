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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AtlasColors.navy.withValues(alpha: .08),
        titleSpacing: 8,
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AtlasColors.navy)),
        actions: [...actions, const SizedBox(width: 8)],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AtlasColors.border),
        ),
      ),
      drawer: SizedBox(
        width: 300,
        child: AdminNavigationDrawer(selectedRoute: selectedRoute, onDestinationSelected: onDestinationSelected),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1000 ? 32.0 : 16.0;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 22),
              child: Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1500), child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}
