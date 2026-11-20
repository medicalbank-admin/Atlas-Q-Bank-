import 'package:flutter/material.dart';

import '../models/academic_subject_model.dart';
import '../services/academic_subject_service.dart';
import 'academic_topic_management_screen.dart';

class AcademicSubjectManagementScreen extends StatelessWidget {
  final String yearId;
  final String yearName;

  const AcademicSubjectManagementScreen({
    super.key,
    required this.yearId,
    required this.yearName,
  });

  static const Color deepTeal = Color(0xFF123F46);
  static const Color oceanTeal = Color(0xFF28777B);
  static const Color ivory = Color(0xFFF7F8F5);
  static const Color champagne = Color(0xFFD8B66B);

  Future<void> _showSubjectDialog(
    BuildContext context, {
    AcademicSubjectModel? existing,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: existing?.name ?? '',
    );

    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );

    final orderController = TextEditingController(
      text: (existing?.displayOrder ?? 0).toString(),
    );

    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Subject' : 'Edit Subject',
              ),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Subject name',
                            prefixIcon: Icon(Icons.menu_book_rounded),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter a subject name'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: orderController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Display order',
                            helperText: 'Smaller numbers appear first.',
                            prefixIcon: Icon(Icons.sort_rounded),
                          ),
                          validator: (value) {
                            final number = int.tryParse(
                              value?.trim() ?? '',
                            );

                            if (number == null || number < 0) {
                              return 'Enter a valid non-negative number';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            if (existing == null) {
                              await AcademicSubjectService.createSubject(
                                yearId: yearId,
                                name: nameController.text,
                                description: descriptionController.text,
                                displayOrder: int.parse(
                                  orderController.text.trim(),
                                ),
                              );
                            } else {
                              final updated = existing.copyWith(
                                name: nameController.text.trim(),
                                description:
                                    descriptionController.text.trim(),
                                displayOrder: int.parse(
                                  orderController.text.trim(),
                                ),
                              );

                              await AcademicSubjectService.updateSubject(
                                updated,
                              );
                            }

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  existing == null
                                      ? 'Subject created successfully.'
                                      : 'Subject updated successfully.',
                                ),
                              ),
                            );
                          } catch (error) {
                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Unable to save subject: $error',
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          existing == null ? 'Add Subject' : 'Save Changes',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    orderController.dispose();
  }

  Future<void> _deleteSubject(
    BuildContext context,
    AcademicSubjectModel subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text(
          'Delete "${subject.name}"? Associated topics and resources '
          'must be handled separately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AcademicSubjectService.deleteSubject(subject.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject deleted successfully.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  Widget _subjectCard(
    BuildContext context,
    AcademicSubjectModel subject,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE7ECEA),
        ),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: oceanTeal,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        color: deepTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Display order: ${subject.displayOrder}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _showSubjectDialog(
                      context,
                      existing: subject,
                    );
                  } else if (value == 'publish') {
                    try {
                      await AcademicSubjectService.setPublished(
                        subjectId: subject.id,
                        isPublished: !subject.isPublished,
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Update failed: $error'),
                        ),
                      );
                    }
                  } else if (value == 'delete') {
                    await _deleteSubject(context, subject);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit subject'),
                  ),
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(
                      subject.isPublished ? 'Unpublish' : 'Publish',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          if (subject.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subject.description,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _statusChip(
                subject.isPublished ? 'Published' : 'Draft',
                subject.isPublished
                    ? const Color(0xFFE5F1EF)
                    : const Color(0xFFFFF3DB),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AcademicTopicManagementScreen(
                        yearId: yearId,
                        subjectId: subject.id,
                        subjectName: subject.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.account_tree_rounded,
                  size: 17,
                ),
                label: const Text('Topics'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: deepTeal,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: deepTeal,
        title: Text(
          yearName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add subject',
            onPressed: () => _showSubjectDialog(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: deepTeal,
        foregroundColor: champagne,
        onPressed: () => _showSubjectDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subject'),
      ),
      body: StreamBuilder<List<AcademicSubjectModel>>(
        stream: AcademicSubjectService.watchSubjects(yearId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load subjects.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: oceanTeal,
              ),
            );
          }

          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: oceanTeal,
                      size: 58,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Subjects Added Yet',
                      style: TextStyle(
                        color: deepTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start building the curriculum for this '
                      'academic year.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _showSubjectDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Subject'),
                      style: FilledButton.styleFrom(
                        backgroundColor: deepTeal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [deepTeal, oceanTeal],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: champagne,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Academic Subjects',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subjects.length} subjects in $yearName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (final subject in subjects)
                _subjectCard(context, subject),
            ],
          );
        },
      ),
    );
  }
}
