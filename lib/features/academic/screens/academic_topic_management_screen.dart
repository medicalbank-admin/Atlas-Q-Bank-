import 'package:flutter/material.dart';

import '../models/academic_topic_model.dart';
import '../services/academic_topic_service.dart';
import 'learning_resource_management_screen.dart';

class AcademicTopicManagementScreen extends StatelessWidget {
  final String yearId;
  final String subjectId;
  final String subjectName;

  const AcademicTopicManagementScreen({
    super.key,
    required this.yearId,
    required this.subjectId,
    required this.subjectName,
  });

  static const Color deepTeal = Color(0xFF123F46);
  static const Color oceanTeal = Color(0xFF28777B);
  static const Color ivory = Color(0xFFF7F8F5);
  static const Color champagne = Color(0xFFD8B66B);

  Future<void> _showTopicDialog(
    BuildContext context, {
    AcademicTopicModel? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(
      text: existing?.title ?? '',
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
                existing == null ? 'Create Topic' : 'Edit Topic',
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
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Topic title',
                            prefixIcon: Icon(Icons.topic_rounded),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter a topic title'
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
                              await AcademicTopicService.createTopic(
                                yearId: yearId,
                                subjectId: subjectId,
                                title: titleController.text,
                                description:
                                    descriptionController.text,
                                displayOrder: int.parse(
                                  orderController.text.trim(),
                                ),
                              );
                            } else {
                              final updated = existing.copyWith(
                                title: titleController.text.trim(),
                                description:
                                    descriptionController.text.trim(),
                                displayOrder: int.parse(
                                  orderController.text.trim(),
                                ),
                              );

                              await AcademicTopicService.updateTopic(
                                updated,
                              );
                            }

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  existing == null
                                      ? 'Topic created successfully.'
                                      : 'Topic updated successfully.',
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
                                  'Unable to save topic: $error',
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          existing == null ? 'Create Topic' : 'Save Changes',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    orderController.dispose();
  }

  Future<void> _deleteTopic(
    BuildContext context,
    AcademicTopicModel topic,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Topic?'),
        content: Text(
          'Delete "${topic.title}"? This action cannot be undone. '
          'Any associated learning resources will also need to be '
          'managed separately.',
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
      await AcademicTopicService.deleteTopic(topic.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Topic deleted successfully.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  Widget _topicCard(
    BuildContext context,
    AcademicTopicModel topic,
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
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: oceanTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: const TextStyle(
                        color: deepTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Display order: ${topic.displayOrder}',
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
                    await _showTopicDialog(
                      context,
                      existing: topic,
                    );
                  } else if (value == 'publish') {
                    try {
                      await AcademicTopicService.setPublished(
                        topicId: topic.id,
                        isPublished: !topic.isPublished,
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
                    await _deleteTopic(context, topic);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit topic'),
                  ),
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(
                      topic.isPublished ? 'Unpublish' : 'Publish',
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
          if (topic.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                topic.description,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              _statusChip(
                topic.isPublished ? 'Published' : 'Draft',
                topic.isPublished
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
                          LearningResourceManagementScreen(
                        yearId: yearId,
                        subjectId: subjectId,
                        topicId: topic.id,
                        topicTitle: topic.title,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.library_books_rounded,
                  size: 17,
                ),
                label: const Text('Resources'),
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
          subjectName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add topic',
            onPressed: () => _showTopicDialog(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: deepTeal,
        foregroundColor: champagne,
        onPressed: () => _showTopicDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Topic'),
      ),
      body: StreamBuilder<List<AcademicTopicModel>>(
        stream: AcademicTopicService.watchTopics(
          yearId: yearId,
          subjectId: subjectId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load topics.\n${snapshot.error}',
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

          final topics = snapshot.data ?? [];

          if (topics.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: oceanTeal,
                      size: 58,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Topics Added Yet',
                      style: TextStyle(
                        color: deepTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start organizing this subject into topics '
                      'and chapters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _showTopicDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Topic'),
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
                      Icons.account_tree_rounded,
                      color: champagne,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subject Topics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${topics.length} topics available',
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
              for (final topic in topics)
                _topicCard(context, topic),
            ],
          );
        },
      ),
    );
  }
}
