import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../academic/screens/academic_subject_management_screen.dart';
import '../../../app/atlas_academy_app.dart';
class AdminAcademicScreen extends StatefulWidget {
  const AdminAcademicScreen({super.key});
  @override
  State<AdminAcademicScreen> createState() => _AdminAcademicScreenState();
}
class _AdminAcademicScreenState extends State<AdminAcademicScreen> {
  final CollectionReference<Map<String, dynamic>> _years =
      FirebaseFirestore.instance.collection('academic_years');
  bool _authorized = false;
  bool _checking = true;
  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }
  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    bool allowed = false;
    if (user != null) {
      try {
        final token = await user.getIdTokenResult(true);
        allowed = token.claims?['admin'] == true;
      } catch (_) {
        allowed = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _authorized = allowed;
      _checking = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: const Color(0xFFF3F7FF),
        body: Center(
          child: CircularProgressIndicator(
            color: AtlasColors.royalBlue,
          ),
        ),
      );
    }
    if (!_authorized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F7FF),
        appBar: AppBar(title: const Text('Academic Management')),
        body: const Center(
          child: Text('Administrator access required.'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text(
          'Academic Management',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AtlasColors.navy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddYearDialog,
        backgroundColor: AtlasColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Academic Year'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _years.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _messageState(
              Icons.cloud_off_rounded,
              'Unable to load academic years',
              'Please check your connection and Firestore security rules.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AtlasColors.royalBlue,
              ),
            );
          }
          final documents = snapshot.data?.docs ?? [];
          documents.sort((a, b) {
            final aOrder = (a.data()['order'] as num?)?.toInt() ?? 0;
            final bOrder = (b.data()['order'] as num?)?.toInt() ?? 0;
            return aOrder.compareTo(bOrder);
          });
          final activeCount = documents
              .where((doc) => doc.data()['isActive'] != false)
              .length;
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
            children: [
              _buildHero(documents.length, activeCount),
              const SizedBox(height: 25),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Academic Years',
                      style: TextStyle(
                        color: AtlasColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _countBadge(documents.length),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Organise the academic structure of your academy.',
                style: TextStyle(
                  color: AtlasColors.secondaryText,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 17),
              if (documents.isEmpty)
                _messageState(
                  Icons.menu_book_rounded,
                  'No Academic Years Yet',
                  'Add your first academic year to begin organising '
                      'your curriculum.',
                )
              else
                ...documents.map((doc) {
                  final data = doc.data();
                  final name =
                      (data['name'] ?? 'Unnamed Year').toString();
                  final active = data['isActive'] != false;
                  return _yearCard(
                    id: doc.id,
                    name: name,
                    active: active,
                  );
                }),
            ],
          );
        },
      ),
    );
  }
  Widget _buildHero(int total, int active) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AtlasColors.navy, AtlasColors.royalBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                color: AtlasColors.royalBlue,
                size: 29,
              ),
              SizedBox(width: 11),
              Text(
                'ACADEMIC STRUCTURE',
                style: TextStyle(
                  color: AtlasColors.royalBlue,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Build your curriculum',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Manage academic years and organise the learning '
            'structure of The Atlas Academy.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _statBox('TOTAL YEARS', '$total'),
              const SizedBox(width: 11),
              _statBox('ACTIVE YEARS', '$active'),
            ],
          ),
        ],
      ),
    );
  }
  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 8,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AtlasColors.paleBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count configured',
        style: const TextStyle(
          color: AtlasColors.royalBlue,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
  Widget _yearCard({
    required String id,
    required String name,
    required bool active,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0EAF5)),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AcademicSubjectManagementScreen(
              yearId: id,
              yearName: name,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 9,
        ),
        leading: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AtlasColors.paleBlue,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: AtlasColors.royalBlue,
            size: 23,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: AtlasColors.navy,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Row(
            children: [
              Container(
                height: 7,
                width: 7,
                decoration: BoxDecoration(
                  color: active
                      ? AtlasColors.success
                      : AtlasColors.secondaryText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                active ? 'Tap to manage subjects' : 'Inactive · tap to manage',
                style: TextStyle(
                  color: active
                      ? AtlasColors.success
                      : AtlasColors.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AtlasColors.secondaryText,
          ),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditYearDialog(id, name);
            } else if (value == 'toggle') {
              _toggleYear(id, active);
            } else if (value == 'delete') {
              _confirmDelete(id, name);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit name'),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Text(active ? 'Deactivate' : 'Activate'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete',
                style: TextStyle(color: AtlasColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _messageState(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE0EAF5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AtlasColors.royalBlue),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AtlasColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _showAddYearDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Academic Year'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Academic year name',
            hintText: 'e.g. First Year',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                await _years.add({
                  'name': name,
                  'order': 0,
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                Navigator.pop(dialogContext);
                _message('Academic year added successfully.');
              } catch (e) {
                _message('Could not add academic year: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
  Future<void> _showEditYearDialog(
    String id,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Academic Year'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Academic year name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                await _years.doc(id).update({
                  'name': name,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                Navigator.pop(dialogContext);
                _message('Academic year updated.');
              } catch (e) {
                _message('Update failed: $e');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
  Future<void> _toggleYear(String id, bool currentlyActive) async {
    try {
      await _years.doc(id).update({
        'isActive': !currentlyActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _message(
        currentlyActive
            ? 'Academic year deactivated.'
            : 'Academic year activated.',
      );
    } catch (e) {
      _message('Could not update academic year: $e');
    }
  }
  Future<void> _confirmDelete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Academic Year?'),
        content: Text(
          'Are you sure you want to delete "$name"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AtlasColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _years.doc(id).delete();
      _message('Academic year deleted.');
    } catch (e) {
      _message('Could not delete academic year: $e');
    }
  }
  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
