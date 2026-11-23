import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/atlas_academy_app.dart';

class AtlasAiMedicalTutorScreen extends StatefulWidget {
  const AtlasAiMedicalTutorScreen({super.key});

  @override
  State<AtlasAiMedicalTutorScreen> createState() => _AtlasAiMedicalTutorScreenState();
}

class _AtlasAiMedicalTutorScreenState extends State<AtlasAiMedicalTutorScreen> {
  static const _storageKey = 'atlas_ai_tutor_chat_v1';
  static const _modelName = 'gemini-3.8-flash';
  static const _systemPrompt = '''
You are Atlas, the medical learning tutor inside The Atlas Academy.
Teach medical students using clear, structured, evidence-aware explanations.
Adapt depth to the learner. Explain mechanisms before memorisation. For clinical
questions, organise answers into: key concept, clinical reasoning, differential
diagnosis where relevant, investigations, management principles, and exam pearls.
Distinguish established facts from uncertainty. Never invent references, guideline
quotes, statistics, or citations. If recommendations may vary by country or change
over time, say so and advise checking current local guidelines and formularies.
Do not diagnose or prescribe for an individual patient. Do not replace a clinician.
If a message describes an emergency or immediately dangerous symptoms, advise
urgent local emergency care rather than attempting remote management.
For medication questions, discuss educational principles and flag that dose depends
on indication, age, weight, renal/hepatic function, pregnancy, interactions and
local protocols. Keep answers readable with headings and concise bullet points.
''';

  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_TutorMessage> _messages = [];
  bool _loading = false;
  bool _restoring = true;
  String? _error;

  GenerativeModel get _model => FirebaseAI.googleAI().generativeModel(
        model: _modelName,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.35,
          maxOutputTokens: 1800,
        ),
      );

  @override
  void initState() {
    super.initState();
    _restoreConversation();
  }

  Future<void> _restoreConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _messages.addAll(decoded.whereType<Map>().map((item) =>
              _TutorMessage(
                text: (item['text'] ?? '').toString(),
                isUser: item['isUser'] == true,
              )).where((item) => item.text.isNotEmpty).take(40));
        }
      }
    } catch (_) {
      // A corrupt local history must never prevent opening the tutor.
    }
    if (mounted) setState(() => _restoring = false);
    _scrollToBottom();
  }

  Future<void> _persistConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = _messages.length > 40
          ? _messages.sublist(_messages.length - 40)
          : _messages;
      await prefs.setString(
        _storageKey,
        jsonEncode(recent.map((m) => {'text': m.text, 'isUser': m.isUser}).toList()),
      );
    } catch (_) {
      // The current conversation remains available in memory.
    }
  }

  Future<void> _send([String? suggested]) async {
    final question = (suggested ?? _composer.text).trim();
    if (question.isEmpty || _loading) return;
    _composer.clear();
    setState(() {
      _error = null;
      _loading = true;
      _messages.add(_TutorMessage(text: question, isUser: true));
    });
    await _persistConversation();
    _scrollToBottom();

    try {
      final historyMessages = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : <_TutorMessage>[];
      final history = historyMessages.map((m) => m.isUser
          ? Content.text(m.text)
          : Content.model([TextPart(m.text)])).toList();
      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(question));
      final answer = response.text?.trim();
      if (answer == null || answer.isEmpty) {
        throw StateError('The tutor returned an empty response. Please try again.');
      }
      if (!mounted) return;
      setState(() => _messages.add(_TutorMessage(text: answer, isUser: false)));
      await _persistConversation();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      setState(() {
        _error = message.contains('ServiceApiNotEnabled') ||
                message.contains('PERMISSION_DENIED') ||
                message.contains('service is not enabled')
            ? 'Firebase AI Logic is not enabled for this Firebase project yet. Enable the Gemini Developer API in Firebase Console → AI Logic, then try again.'
            : message.contains('QuotaExceeded') || message.contains('429')
                ? 'The AI service has reached its current usage limit. Please wait and try again later.'
                : 'The tutor could not connect. Check your internet connection and Firebase AI Logic setup, then try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _newChat() async {
    if (_loading) return;
    setState(() {
      _messages.clear();
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Row(children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFEDE8FF),
            child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF6650B8), size: 19),
          ),
          SizedBox(width: 10),
          Text('AI Medical Tutor'),
        ]),
        actions: [
          IconButton(
            tooltip: 'Start a new chat',
            onPressed: _loading ? null : _newChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(children: [
        _buildStatusBanner(),
        Expanded(
          child: _restoring
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) return const _TypingBubble();
                        return _MessageBubble(message: _messages[index]);
                      },
                    ),
        ),
        if (_error != null) _buildError(),
        _buildComposer(),
      ]),
    );
  }

  Widget _buildStatusBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: const Color(0xFFF0ECFF),
        child: const Row(children: [
          Icon(Icons.verified_user_outlined, size: 15, color: Color(0xFF6650B8)),
          SizedBox(width: 7),
          Expanded(child: Text(
            'AI-assisted study • Verify clinical decisions with current guidelines',
            style: TextStyle(color: Color(0xFF51418D), fontSize: 10, fontWeight: FontWeight.w700),
          )),
          Text('BETA', style: TextStyle(color: Color(0xFF6650B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ]),
      );

  Widget _buildWelcome() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF29204F), Color(0xFF6856B9), Color(0xFF9279D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x1F5141A8), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 49, height: 49,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 18),
              const Text('Think deeper.\nLearn medicine smarter.',
                style: TextStyle(color: Colors.white, fontSize: 25, height: 1.16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text('Ask complex questions, unpack mechanisms and practise clinical reasoning with your medical study companion.',
                style: TextStyle(color: Color(0xFFDAD6E8), height: 1.5, fontSize: 12)),
              const SizedBox(height: 17),
              const Wrap(spacing: 7, runSpacing: 7, children: [
                _HeroTag('Concept breakdowns'),
                _HeroTag('Clinical reasoning'),
                _HeroTag('Exam preparation'),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('WHAT WOULD YOU LIKE TO LEARN?',
            style: TextStyle(color: AtlasColors.royalBlue, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 11),
          _PromptTile(icon: Icons.biotech_rounded, title: 'Explain a difficult concept', subtitle: 'Build understanding step by step', prompt: 'Explain the cardiac action potential step by step, including the ionic currents and how it differs in pacemaker cells.', onTap: _send),
          _PromptTile(icon: Icons.medical_services_rounded, title: 'Work through a clinical case', subtitle: 'Reason from presentation to diagnosis', prompt: 'Give me a structured clinical reasoning tutorial using a short case of acute chest pain. Ask me one decision at a time.', onTap: _send),
          _PromptTile(icon: Icons.quiz_rounded, title: 'Discuss an MCQ', subtitle: 'Understand why each option is right or wrong', prompt: 'Create a challenging single-best-answer medical MCQ on renal physiology. Let me answer before revealing the explanation.', onTap: _send),
          _PromptTile(icon: Icons.menu_book_rounded, title: 'Make a revision summary', subtitle: 'Turn a topic into high-yield notes', prompt: 'Create a high-yield revision summary of the renin–angiotensin–aldosterone system, including a comparison table and exam pearls.', onTap: _send),
          const SizedBox(height: 12),
          const Text('Your conversations are saved on this device only. Do not enter patient-identifying information.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AtlasColors.secondaryText, fontSize: 10, height: 1.5)),
        ],
      );

  Widget _buildError() => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF1E8), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFF4D5C4))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFAD572F), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: const TextStyle(color: AtlasColors.charcoal, fontSize: 11, height: 1.45))),
          IconButton(onPressed: () => setState(() => _error = null), icon: const Icon(Icons.close, size: 17), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
        ]),
      );

  Widget _buildComposer() => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE4EAF1)))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: _composer,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask your medical question…',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF8D7BD0))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48, height: 48,
              child: FilledButton(
                onPressed: _loading ? null : () => _send(),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6650B8), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 19),
              ),
            ),
          ]),
        ),
      );
}

class _TutorMessage {
  final String text;
  final bool isUser;
  const _TutorMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _TutorMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .86),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: user ? const Color(0xFF6650B8) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17), topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(user ? 17 : 5), bottomRight: Radius.circular(user ? 5 : 17),
          ),
          border: user ? null : Border.all(color: const Color(0xFFE5EAF1)),
          boxShadow: const [BoxShadow(color: Color(0x080E315A), blurRadius: 9, offset: Offset(0, 3))],
        ),
        child: SelectableText(message.text, style: TextStyle(
          color: user ? Colors.white : AtlasColors.charcoal,
          fontSize: 13, height: 1.55,
        )),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5EAF1))),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6650B8))),
        SizedBox(width: 9),
        Text('Atlas is thinking…', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _PromptTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, prompt;
  final ValueChanged<String> onTap;
  const _PromptTile({required this.icon, required this.title, required this.subtitle, required this.prompt, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      onTap: () => onTap(prompt),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: CircleAvatar(backgroundColor: const Color(0xFFEDE8FF), child: Icon(icon, color: const Color(0xFF6650B8), size: 20)),
      title: Text(title, style: const TextStyle(color: AtlasColors.navy, fontSize: 12, fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 10)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF8878C8)),
    ),
  );
}

class _HeroTag extends StatelessWidget {
  final String label;
  const _HeroTag(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .18))),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}
