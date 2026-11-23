import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../services/daily_challenge_service.dart';

class AtlasDailyMedicalChallengeScreen extends StatefulWidget {
  const AtlasDailyMedicalChallengeScreen({super.key});

  @override
  State<AtlasDailyMedicalChallengeScreen> createState() =>
      _AtlasDailyMedicalChallengeScreenState();
}

class _AtlasDailyMedicalChallengeScreenState
    extends State<AtlasDailyMedicalChallengeScreen> {
  final DailyChallengeService _service = DailyChallengeService();
  Map<String, dynamic>? _challenge;
  Map<String, dynamic>? _stats;
  int? _selected;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait([
        _service.startToday(),
        _service.loadStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _challenge = values[0];
        _stats = values[1];
        _selected = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _submit() async {
    if (_selected == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await _service.submitAnswer(_selected!);
      if (!mounted) return;
      setState(() {
        _challenge = {
          ...?_challenge,
          'alreadyCompleted': true,
          'isCorrect': result['isCorrect'],
          'selectedAnswer': result['selectedAnswer'],
          'correctAnswer': result['correctAnswer'],
          'explanation': result['explanation'],
        };
        _stats = {
          ...?_stats,
          'currentStreak': result['currentStreak'] ?? _stats?['currentStreak'] ?? 0,
          'longestStreak': result['longestStreak'] ?? _stats?['longestStreak'] ?? 0,
          'totalCompleted': result['totalCompleted'] ?? ((_stats?['totalCompleted'] ?? 0) + 1),
          'totalCorrect': result['totalCorrect'] ?? ((_stats?['totalCorrect'] ?? 0) + ((result['isCorrect'] == true) ? 1 : 0)),
          'completedToday': true,
        };
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _challenge?['alreadyCompleted'] == true;
    final options = (_challenge?['options'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final correct = _challenge?['isCorrect'] == true;
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Text('Daily Medical Challenge'),
        actions: [
          IconButton(
            tooltip: 'Refresh challenge',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                    children: [
                      _heroCard(),
                      const SizedBox(height: 15),
                      _statsRow(),
                      const SizedBox(height: 22),
                      Row(children: [
                        const Expanded(child: Text('TODAY\'S QUESTION',
                          style: TextStyle(color: AtlasColors.royalBlue, fontSize: 10,
                            letterSpacing: 1.2, fontWeight: FontWeight.w900))),
                        Text(_challenge?['date']?.toString() ?? '',
                          style: const TextStyle(color: AtlasColors.secondaryText,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: AtlasColors.border),
                          boxShadow: const [BoxShadow(color: Color(0x090E315A),
                            blurRadius: 18, offset: Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(spacing: 7, runSpacing: 7, children: [
                              _tag(_challenge?['subject']?.toString().isNotEmpty == true
                                  ? _challenge!['subject'].toString() : 'General Medicine'),
                              _tag(_challenge?['difficulty']?.toString() ?? 'Medium'),
                            ]),
                            const SizedBox(height: 15),
                            Text(_challenge?['question']?.toString() ?? '',
                              style: const TextStyle(color: AtlasColors.navy,
                                fontSize: 17, height: 1.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 17),
                            for (var i = 0; i < options.length; i++)
                              _option(i, options[i], completed),
                            if (completed) ...[
                              const SizedBox(height: 13),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: correct ? const Color(0xFFE9F7EF) : const Color(0xFFFFF1EF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: correct ? const Color(0xFFB9E4C9) : const Color(0xFFF3C7C1)),
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Icon(correct ? Icons.check_circle_rounded : Icons.info_rounded,
                                      color: correct ? const Color(0xFF21865A) : const Color(0xFFC14D42)),
                                    const SizedBox(width: 8),
                                    Text(correct ? 'Correct answer!' : 'Not quite — keep learning',
                                      style: TextStyle(fontWeight: FontWeight.w900,
                                        color: correct ? const Color(0xFF176B43) : const Color(0xFF9C3D35))),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text('Correct answer: ${_challenge?['correctAnswer'] ?? ''}',
                                    style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 7),
                                  Text(_challenge?['explanation']?.toString().isNotEmpty == true
                                      ? _challenge!['explanation'].toString()
                                      : 'Review this concept in your study library.',
                                    style: const TextStyle(color: AtlasColors.charcoal, height: 1.55, fontSize: 13)),
                                ]),
                              ),
                            ] else ...[
                              const SizedBox(height: 13),
                              SizedBox(width: double.infinity, height: 52,
                                child: ElevatedButton(
                                  onPressed: _selected == null || _submitting ? null : _submit,
                                  child: _submitting
                                    ? const SizedBox(width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Submit Answer'),
                                )),
                              const SizedBox(height: 8),
                              const Text('You get one official submission each day. Your answer is checked securely.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AtlasColors.secondaryText, fontSize: 10, height: 1.4)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 23),
                      const Text('RECENT CHALLENGES',
                        style: TextStyle(color: AtlasColors.royalBlue, fontSize: 10,
                          letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 9),
                      _history(),
                    ],
                  ),
                ),
    );
  }

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF173D6C), Color(0xFF286BA7)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ONE QUESTION. EVERY DAY.',
          style: TextStyle(color: Colors.white70, fontSize: 9,
            letterSpacing: 1.3, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('Build your clinical thinking habit.',
          style: TextStyle(color: Colors.white, fontSize: 21,
            height: 1.2, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(_challenge?['alreadyCompleted'] == true
            ? 'Today’s challenge completed'
            : 'A fresh question is waiting for you.',
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ])),
      const SizedBox(width: 12),
      const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFB45B), size: 55),
    ]),
  );

  Widget _statsRow() {
    final stats = _stats ?? {};
    return Row(children: [
      _stat('CURRENT STREAK', '${stats['currentStreak'] ?? 0}', Icons.local_fire_department_rounded),
      const SizedBox(width: 8),
      _stat('BEST STREAK', '${stats['longestStreak'] ?? 0}', Icons.emoji_events_rounded),
      const SizedBox(width: 8),
      _stat('COMPLETED', '${stats['totalCompleted'] ?? 0}', Icons.task_alt_rounded),
    ]);
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(child:
    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AtlasColors.border)),
      child: Column(children: [
        Icon(icon, color: AtlasColors.royalBlue, size: 19),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: AtlasColors.navy,
          fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(
          color: AtlasColors.secondaryText, fontSize: 8, fontWeight: FontWeight.w900)),
      ])));

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: AtlasColors.paleBlue,
      borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: AtlasColors.navy,
      fontSize: 10, fontWeight: FontWeight.w800)));

  Widget _option(int index, String text, bool completed) {
    final selected = _selected == index;
    final answerLetter = String.fromCharCode(65 + index);
    final isCorrectOption = completed && _challenge?['correctAnswer'] == answerLetter;
    final wasSelected = completed && _challenge?['selectedAnswer'] == answerLetter;
    final color = isCorrectOption ? const Color(0xFF21865A)
        : wasSelected ? const Color(0xFFC14D42)
        : selected ? AtlasColors.royalBlue : AtlasColors.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: completed ? null : () => setState(() => _selected = index),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AtlasColors.paleBlue : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color, width: selected || isCorrectOption || wasSelected ? 1.6 : 1),
          ),
          child: Row(children: [
            Container(width: 29, height: 29, alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(9)),
              child: Text(answerLetter, style: TextStyle(color: color,
                fontWeight: FontWeight.w900, fontSize: 12))),
            const SizedBox(width: 11),
            Expanded(child: Text(text, style: const TextStyle(color: AtlasColors.charcoal,
              fontSize: 13, height: 1.35, fontWeight: FontWeight.w600))),
            if (isCorrectOption) const Icon(Icons.check_circle_rounded, color: Color(0xFF21865A))
            else if (wasSelected) const Icon(Icons.cancel_rounded, color: Color(0xFFC14D42))
            else if (selected) const Icon(Icons.radio_button_checked_rounded, color: AtlasColors.royalBlue),
          ]),
        ),
      ),
    );
  }

  Widget _history() {
    final history = (_stats?['history'] as List?) ?? const [];
    if (history.isEmpty) {
      return Container(padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AtlasColors.border)),
        child: const Text('Your completed daily challenges will appear here.',
          style: TextStyle(color: AtlasColors.secondaryText, fontSize: 12)));
    }
    return Column(children: history.take(7).map((item) {
      final entry = Map<String, dynamic>.from(item as Map);
      final ok = entry['isCorrect'] == true;
      return Container(margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AtlasColors.border)),
        child: Row(children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: ok ? const Color(0xFF21865A) : AtlasColors.secondaryText, size: 19),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry['topic']?.toString().isNotEmpty == true ? entry['topic'].toString() : 'Daily challenge',
              style: const TextStyle(color: AtlasColors.navy, fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(entry['date']?.toString() ?? '',
              style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 10)),
          ])),
          Text(ok ? 'Correct' : 'Reviewed',
            style: TextStyle(color: ok ? const Color(0xFF21865A) : AtlasColors.secondaryText,
              fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      );
    }).toList());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, color: AtlasColors.royalBlue, size: 42),
        const SizedBox(height: 13),
        const Text('Challenge unavailable',
          style: TextStyle(color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 12, height: 1.5)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
      ]),
    ),
  );
}
