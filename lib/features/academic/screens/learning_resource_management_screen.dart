import 'package:flutter/material.dart';

import '../models/learning_resource_model.dart';
import '../services/learning_resource_service.dart';

class LearningResourceManagementScreen extends StatelessWidget {
  final String yearId;
  final String subjectId;
  final String topicId;
  final String topicTitle;

  const LearningResourceManagementScreen({
    super.key,
    required this.yearId,
    required this.subjectId,
    required this.topicId,
    required this.topicTitle,
  });

  static const Color deepTeal = Color(0xFF123F46);
  static const Color oceanTeal = Color(0xFF28777B);
  static const Color ivory = Color(0xFFF7F8F5);
  static const Color champagne = Color(0xFFD8B66B);

  Future<void> _addResource(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    final durationController = TextEditingController();

    var selectedType = LearningResourceType.pdf;
    var isFree = false;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Learning Resource'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Resource title',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter a title'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<LearningResourceType>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Resource type',
                          ),
                          items: LearningResourceType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_typeLabel(type)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: urlController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Resource URL',
                            hintText: 'https://...',
                            prefixIcon: Icon(Icons.link),
                          ),
                          validator: (value) {
                            final uri = Uri.tryParse(
                              value?.trim() ?? '',
                            );

                            if (uri == null ||
                                !uri.hasScheme ||
                                !['http', 'https'].contains(uri.scheme) ||
                                uri.host.isEmpty) {
                              return 'Enter a valid HTTP or HTTPS URL';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration in minutes (videos)',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }

                            final number = int.tryParse(value.trim());

                            if (number == null || number < 0) {
                              return 'Enter a valid duration';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Free resource'),
                          subtitle: const Text(
                            'Mark this resource as freely accessible',
                          ),
                          value: isFree,
                          activeThumbColor: oceanTeal,
                          onChanged: (value) {
                            setDialogState(() {
                              isFree = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await LearningResourceService.createResource(
                              yearId: yearId,
                              subjectId: subjectId,
                              topicId: topicId,
                              title: titleController.text,
                              description: descriptionController.text,
                              type: selectedType,
                              resourceUrl: urlController.text,
                              isFree: isFree,
                              durationMinutes: int.tryParse(
                                    durationController.text.trim(),
                                  ) ??
                                  0,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Learning resource added successfully.',
                                ),
                              ),
                            );
                          } catch (error) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not add resource: $error',
                                ),
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Resource'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    urlController.dispose();
    durationController.dispose();
  }

  Future<void> _deleteResource(
    BuildContext context,
    LearningResourceModel resource,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: Text(
          'Are you sure you want to delete "${resource.title}"?',
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
      await LearningResourceService.deleteResource(resource.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource deleted successfully.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  static String _typeLabel(LearningResourceType type) {
    switch (type) {
      case LearningResourceType.pdf:
        return 'PDF';
      case LearningResourceType.video:
        return 'Video';
      case LearningResourceType.document:
        return 'Document';
      case LearningResourceType.presentation:
        return 'Presentation';
      case LearningResourceType.externalLink:
        return 'External Link';
    }
  }

  static IconData _typeIcon(LearningResourceType type) {
    switch (type) {
      case LearningResourceType.pdf:
        return Icons.picture_as_pdf_rounded;
      case LearningResourceType.video:
        return Icons.play_circle_rounded;
      case LearningResourceType.document:
        return Icons.description_rounded;
      case LearningResourceType.presentation:
        return Icons.slideshow_rounded;
      case LearningResourceType.externalLink:
        return Icons.open_in_new_rounded;
    }
  }

  Widget _resourceCard(
    BuildContext context,
    LearningResourceModel resource,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1EF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _typeIcon(resource.type),
                  color: oceanTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: const TextStyle(
                        color: deepTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _typeLabel(resource.type),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'publish') {
                    try {
                      await LearningResourceService.setPublished(
                        resourceId: resource.id,
                        isPublished: !resource.isPublished,
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Update failed: $error')),
                      );
                    }
                  } else if (value == 'delete') {
                    await _deleteResource(context, resource);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(
                      resource.isPublished ? 'Unpublish' : 'Publish',
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
          if (resource.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              resource.description,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip(
                resource.isPublished ? 'Published' : 'Draft',
                resource.isPublished
                    ? const Color(0xFFE5F1EF)
                    : const Color(0xFFFFF3DB),
              ),
              if (resource.isFree)
                _statusChip(
                  'Free',
                  const Color(0xFFEAF2FF),
                ),
              if (resource.durationMinutes > 0)
                _statusChip(
                  '${resource.durationMinutes} min',
                  const Color(0xFFF0EDF8),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            resource.resourceUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: oceanTeal,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: deepTeal,
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
          topicTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add resource',
            onPressed: () => _addResource(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addResource(context),
        backgroundColor: deepTeal,
        foregroundColor: champagne,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Resource'),
      ),
      body: StreamBuilder<List<LearningResourceModel>>(
        stream: LearningResourceService.watchResources(
          yearId: yearId,
          subjectId: subjectId,
          topicId: topicId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load resources.\n${snapshot.error}',
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

          final resources = snapshot.data ?? [];

          if (resources.isEmpty) {
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
                      'No Learning Resources Yet',
                      style: TextStyle(
                        color: deepTeal,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add PDFs, videos, documents or external links '
                      'to this topic.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _addResource(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Resource'),
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
                      Icons.library_books_rounded,
                      color: champagne,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Topic Resources',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${resources.length} learning resources',
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
              for (final resource in resources)
                _resourceCard(context, resource),
            ],
          );
        },
      ),
    );
  }
}

           
