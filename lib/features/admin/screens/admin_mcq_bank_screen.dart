import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../mcqs/models/mcq_model.dart';
import '../../mcqs/services/mcq_management_service.dart';
import 'admin_mcq_import_screen.dart';

class AdminMcqBankScreen extends StatefulWidget {
  const AdminMcqBankScreen({super.key});

  @override
  State<AdminMcqBankScreen> createState() =>
      _AdminMcqBankScreenState();
}

class _AdminMcqBankScreenState extends State<AdminMcqBankScreen> {
  final McqManagementService _service = McqManagementService();
  final TextEditingController _searchController =
      TextEditingController();

  String? _selectedYearId;
  String _statusFilter = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _togglePublished(McqModel question) async {
    try {
      await _service.setPublished(
        id: question.id,
        isPublished: !question.isPublished,
      );

      if (!mounted) return;

      _showMessage(
        question.isPublished
            ? 'Question unpublished.'
            : 'Question published.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to update question: $error');
    }
  }

  Future<void> _deleteQuestion(McqModel question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete MCQ?'),
        content: const Text(
          'This question will be permanently deleted. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteMcq(question.id);

      if (!mounted) return;
      _showMessage('Question deleted successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to delete question: $error');
    }
  }

  void _showQuestionDetails(McqModel question) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Question Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(question.options.length, (index) {
                final letter = String.fromCharCode(65 + index);
                final isCorrect =
                    letter == question.correctAnswer;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFFEAF1FC)
                        : Colors.grey.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF174A91)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$letter. ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(child: Text(question.options[index])),
                      if (isCorrect)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF174A91),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              const Text(
                'Explanation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                question.explanation.isEmpty
                    ? 'No explanation added.'
                    : question.explanation,
              ),
              const SizedBox(height: 16),
              Text('Subject: ${question.subject}'),
              Text('Topic: ${question.topic}'),
              Text('Difficulty: ${question.difficulty}'),
              if (question.reference.isNotEmpty)
                Text('Reference: ${question.reference}'),
              const SizedBox(height: 12),
              Text(
                question.isPublished ? 'Published' : 'Unpublished',
                style: TextStyle(
                  color: question.isPublished
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearFilter() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('academic_years')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final years = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: years.any((doc) => doc.id == _selectedYearId)
              ? _selectedYearId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Filter by academic year',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school_outlined),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All academic years'),
            ),
            ...years.map((doc) {
              final data = doc.data();
              final name = data['name'] ??
                  data['title'] ??
                  data['year'] ??
                  doc.id;

              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(name.toString()),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedYearId = value;
            });
          },
        );
      },
    );
  }

  Widget _buildQuestionCard(McqModel question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFEAF1FC),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF071B3D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _tag(
                        question.difficulty,
                        const Color(0xFFEAF1FC),
                      ),
                      _tag(
                        question.isPublished
                            ? 'Published'
                            : 'Unpublished',
                        question.isPublished
                            ? const Color(0xFFE5F4EC)
                            : const Color(0xFFFFF6E5),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view') {
                      _showQuestionDetails(question);
                    } else if (value == 'publish') {
                      _togglePublished(question);
                    } else if (value == 'delete') {
                      _deleteQuestion(question);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View details'),
                    ),
                    PopupMenuItem(
                      value: 'publish',
                      child: Text(
                        question.isPublished
                            ? 'Unpublish'
                            : 'Publish',
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
            const SizedBox(height: 12),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(question.options.length, (optionIndex) {
              final letter = String.fromCharCode(65 + optionIndex);
              final correct = letter == question.correctAnswer;

              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$letter. ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: correct
                            ? const Color(0xFF174A91)
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        question.options[optionIndex],
                        style: TextStyle(
                          color: correct
                              ? const Color(0xFF174A91)
                              : null,
                          fontWeight: correct
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (correct)
                      const Icon(
                        Icons.check_circle,
                        size: 17,
                        color: Color(0xFF174A91),
                      ),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Text(
              '${question.subject}  •  ${question.topic}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showQuestionDetails(question),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Details'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _togglePublished(question),
                  child: Text(
                    question.isPublished ? 'Unpublish' : 'Publish',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCQ Question Bank'),
        actions: [
          IconButton(
            tooltip: 'Bulk import',
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminMcqImportScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search questions, subjects or topics',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildYearFilter(),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Publication status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All questions'),
                      ),
                      DropdownMenuItem(
                        value: 'Published',
                        child: Text('Published only'),
                      ),
                      DropdownMenuItem(
                        value: 'Unpublished',
                        child: Text('Unpublished only'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value ?? 'All';
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<McqModel>>(
                stream: _service.watchMcqs(
                  yearId: _selectedYearId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load MCQs.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final questions = snapshot.data!.where((question) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        question.question
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        question.subject
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        question.topic
                            .toLowerCase()
                            .contains(_searchQuery);

                    final matchesStatus = _statusFilter == 'All' ||
                        (_statusFilter == 'Published' &&
                            question.isPublished) ||
                        (_statusFilter == 'Unpublished' &&
                            !question.isPublished);

                    return matchesSearch && matchesStatus;
                  }).toList();

                  if (questions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 55,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No MCQs found',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Import questions or change your filters.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: questions.length,
                    itemBuilder: (context, index) =>
                        _buildQuestionCard(questions[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminMcqImportScreen(),
            ),
          );
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Bulk Import'),
      ),
    );
  }
}
