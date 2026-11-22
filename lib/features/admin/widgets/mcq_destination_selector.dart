import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class McqDestination {
  final String trackType, yearId, yearName, pathwayId, pathwayName;
  final String subjectId, subjectName, examSetId, examSetName;
  const McqDestination({
    required this.trackType,
    this.yearId = '',
    this.yearName = '',
    this.pathwayId = '',
    this.pathwayName = '',
    required this.subjectId,
    required this.subjectName,
    required this.examSetId,
    required this.examSetName,
  });
}

class McqDestinationSelector extends StatefulWidget {
  final McqDestination? initialValue;
  final ValueChanged<McqDestination?> onChanged;
  const McqDestinationSelector({super.key, this.initialValue, required this.onChanged});
  @override
  State<McqDestinationSelector> createState() => _McqDestinationSelectorState();
}

class _McqDestinationSelectorState extends State<McqDestinationSelector> {
  String _track = 'structured';
  String _setId = '';
  String _setName = '';
  String _subjectId = '';
  String _subjectName = '';

  @override
  void initState() {
    super.initState();
    final value = widget.initialValue;
    if (value != null) {
      _track = value.trackType == 'past_paper' ? 'past_paper' : 'structured';
      _setId = value.examSetId;
      _setName = value.examSetName;
      _subjectId = value.subjectId;
      _subjectName = value.subjectName;
    }
  }

  void _reset() {
    setState(() {
      _setId = '';
      _setName = '';
      _subjectId = '';
      _subjectName = '';
    });
    widget.onChanged(null);
  }

  void _emit() {
    if (_setId.isEmpty || _subjectId.isEmpty) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(McqDestination(
      trackType: _track,
      yearId: _track == 'structured' ? 'exam_centre' : '',
      yearName: _track == 'structured' ? 'Examination Centre' : '',
      subjectId: _subjectId,
      subjectName: _subjectName,
      examSetId: _setId,
      examSetName: _setName,
    ));
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: const Color(0xFFF3F6FC),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MCQ DESTINATION', style: TextStyle(
            fontWeight: FontWeight.w900, letterSpacing: 1,
            color: Color(0xFF071B3D))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _track,
            decoration: const InputDecoration(
              labelText: 'Import category', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'structured', child: Text('Subject / System / Mock Exam')),
              DropdownMenuItem(value: 'past_paper', child: Text('Past Papers')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _track = value);
              _reset();
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('mcq_exam_sets')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Unable to load destinations: ${snapshot.error}');
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                if (data['isActive'] == false) return false;
                if (_track == 'past_paper') return data['trackType'] == 'past_paper';
                return data['trackType'] == 'structured' || data['yearId'] == 'exam_centre';
              }).toList()
                ..sort((a, b) => (a.data()['name'] ?? '')
                    .toString().compareTo((b.data()['name'] ?? '').toString()));
              if (docs.isEmpty) return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_track == 'past_paper'
                    ? 'Create a past paper first.'
                    : 'Create an exam in Subject-Wise, System-Wise or Mock Exams first.'),
              );
              final valid = docs.any((doc) => doc.id == _setId);
              return DropdownButtonFormField<String>(
                value: valid ? _setId : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _track == 'past_paper' ? 'Select past paper' : 'Select exam',
                  border: const OutlineInputBorder()),
                items: docs.map((doc) => DropdownMenuItem(
                  value: doc.id,
                  child: Text((doc.data()['name'] ?? doc.id).toString(),
                      overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (id) {
                  final selected = docs.where((doc) => doc.id == id);
                  if (selected.isEmpty) return;
                  final data = selected.first.data();
                  setState(() {
                    _setId = selected.first.id;
                    _setName = (data['name'] ?? '').toString();
                    _subjectId = (data['subjectId'] ?? selected.first.id).toString();
                    _subjectName = (data['categoryName'] ??
                        data['subjectName'] ??
                        (_track == 'past_paper' ? 'Past Paper' : 'Examination')).toString();
                  });
                  _emit();
                },
              );
            },
          ),
        ],
      ),
    ),
  );
}
