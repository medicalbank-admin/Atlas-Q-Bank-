
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminAcademicScreen extends StatefulWidget {
  const AdminAcademicScreen({super.key});

  @override
  State<AdminAcademicScreen> createState() =>
      _AdminAcademicScreenState();
}

class _AdminAcademicScreenState extends State<AdminAcademicScreen> {
  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);

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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Academic Management')),
        body: const Center(
          child: Text('Administrator access required.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text(
          'Academic Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        onPressed: _showAddYearDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Academic Year'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _years.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load academic years. '
                  'Check your Firestore security rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: teal),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          documents.sort((a, b) {
            final aOrder = (a.data()['order'] as num?)?.toInt() ?? 0;
            final bOrder = (b.data()['order'] as num?)?.toInt() ?? 0;
            return aOrder.compareTo(bOrder);
          });

          if (documents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 65,
                      color: teal,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Academic Years Yet',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add your first academic year to begin '
                      'organizing the curriculum.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [navy, teal],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 36,
                      color: gold,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Academic Structure',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${documents.length} academic year(s) configured',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Academic Years',
                style: TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ...documents.map((doc) {
                final data = doc.data();
                final name = (data['name'] ?? 'Unnamed Year').toString();
                final active = data['isActive'] != false;

                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F1EF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: teal,
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        active ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: active ? teal : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditYearDialog(doc.id, name);
                        } else if (value == 'toggle') {
                          _toggleYear(doc.id, active);
                        } else if (value == 'delete') {
                          _confirmDelete(doc.id, name);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            active ? 'Deactivate' : 'Activate',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddYearDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
            ElevatedButton(
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
        );
      },
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
      builder: (dialogContext) {
        return AlertDialog(
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
            ElevatedButton(
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
        );
      },
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
              style: TextStyle(color: Colors.red),
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
