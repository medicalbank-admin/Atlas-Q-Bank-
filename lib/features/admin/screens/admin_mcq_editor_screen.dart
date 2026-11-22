import 'package:flutter/material.dart';
import '../../mcqs/models/mcq_model.dart';
import '../../mcqs/services/mcq_management_service.dart';
import '../widgets/mcq_destination_selector.dart';

class AdminMcqEditorScreen extends StatefulWidget {
  final McqModel? question;

  const AdminMcqEditorScreen({
    super.key,
    this.question,
  });

  @override
  State<AdminMcqEditorScreen> createState() =>
      _AdminMcqEditorScreenState();
}

class _AdminMcqEditorScreenState
    extends State<AdminMcqEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = McqManagementService();

  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final _referenceController = TextEditingController();
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();

  final List<TextEditingController> _optionControllers =
      List.generate(5, (_) => TextEditingController());

  McqDestination? _destination;
  String _correctAnswer = 'A';
  String _difficulty = 'Medium';

  int _optionCount = 4;
  bool _saving = false;

  bool get _isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    _loadExistingQuestion();
  }

  void _loadExistingQuestion() {
    final question = widget.question;

    if (question == null) return;

    _questionController.text = question.question;
    _explanationController.text = question.explanation;
    _referenceController.text = question.reference;
    _subjectController.text = question.subject;
    _topicController.text = question.topic;


    _correctAnswer = question.correctAnswer;
    _difficulty = question.difficulty;
    _optionCount = question.options.length;

    for (int i = 0; i < question.options.length; i++) {
      _optionControllers[i].text = question.options[i];
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    _referenceController.dispose();
    _subjectController.dispose();
    _topicController.dispose();

    for (final controller in _optionControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_destination == null) {
      _showMessage('Please select a track, subject and exam set.');
      return;
    }

    final options = List.generate(
      _optionCount,
      (index) => _optionControllers[index].text.trim(),
    );

    final question = McqModel(
      id: widget.question?.id ?? '',
      question: _questionController.text.trim(),
      options: options,
      correctAnswer: _correctAnswer,
      explanation: _explanationController.text.trim(),
      yearId: _destination!.yearId,
      trackType: _destination!.trackType,
      subjectId: _destination!.subjectId,
      examSetId: _destination!.examSetId,
      examSetName: _destination!.examSetName,
      subject: _destination!.subjectName,
      topic: _topicController.text.trim(),
      difficulty: _difficulty,
      reference: _referenceController.text.trim(),
      tags: widget.question?.tags ?? const [],
      isPublished: widget.question?.isPublished ?? false,
      createdBy: widget.question?.createdBy ?? '',
      createdAt: widget.question?.createdAt,
    );

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await _service.updateMcq(question);
      } else {
        await _service.addMcq(question);
      }

      if (!mounted) return;

      _showMessage(
        _isEditing
            ? 'MCQ updated successfully.'
            : 'MCQ created successfully.',
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to save MCQ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 22),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOptionField(int index) {
    final letter = String.fromCharCode(65 + index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Radio<String>(
            value: letter,
            groupValue: _correctAnswer,
            activeColor: const Color(0xFF2563A6),
            onChanged: _saving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _correctAnswer = value;
                    });
                  },
          ),
          Expanded(
            child: TextFormField(
              controller: _optionControllers[index],
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: 'Option $letter',
                border: const OutlineInputBorder(),
                suffixIcon: letter == _correctAnswer
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF174A91),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter option $letter.';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return DropdownButtonFormField<String>(
      value: _difficulty,
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Easy', child: Text('Easy')),
        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
        DropdownMenuItem(value: 'Hard', child: Text('Hard')),
      ],
      onChanged: _saving
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _difficulty = value;
              });
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F7FF),
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit MCQ' : 'Create MCQ',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF123B68),
                      Color(0xFF174A91),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  _isEditing
                      ? 'Update your medical question and its answer details.'
                      : 'Create a new question for the Atlas Academy question bank.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),

              _sectionTitle('Academic Classification'),

              McqDestinationSelector(
                onChanged: (value) => setState(() => _destination = value),
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 12),

              TextFormField(
                controller: _topicController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'e.g. Upper Limb',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Topic is required.'
                        : null,
              ),

              _sectionTitle('Question'),

              TextFormField(
                controller: _questionController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Question statement',
                  hintText: 'Write your MCQ question here...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Question is required.'
                        : null,
              ),

              _sectionTitle('Answer Options'),

              const Text(
                'Select the radio button beside the correct answer.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              ...List.generate(
                _optionCount,
                _buildOptionField,
              ),

              Row(
                children: [
                  const Text('Number of options:'),
                  const Spacer(),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 4,
                        label: Text('4'),
                      ),
                      ButtonSegment(
                        value: 5,
                        label: Text('5'),
                      ),
                    ],
                    selected: {_optionCount},
                    onSelectionChanged: _saving
                        ? null
                        : (selection) {
                            setState(() {
                              _optionCount = selection.first;

                              if ('ABCDE'.indexOf(_correctAnswer) >=
                                  _optionCount) {
                                _correctAnswer = 'A';
                              }
                            });
                          },
                  ),
                ],
              ),

              _sectionTitle('Correct Answer'),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Correct answer: $_correctAnswer',
                  style: const TextStyle(
                    color: Color(0xFF071B3D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              _sectionTitle('Explanation'),

              TextFormField(
                controller: _explanationController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Answer explanation',
                  hintText: 'Explain why this answer is correct...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              _sectionTitle('Difficulty'),

              _buildDifficultySelector(),

              _sectionTitle('Reference'),

              TextFormField(
                controller: _referenceController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Textbook / Reference',
                  hintText: 'e.g. Gray’s Anatomy, page 125',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveQuestion,
                  icon: _saving
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : _isEditing
                            ? 'Update MCQ'
                            : 'Save MCQ',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF071B3D),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
