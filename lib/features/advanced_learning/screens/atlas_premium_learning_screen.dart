import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import 'atlas_flashcards_screen.dart';

class AtlasPremiumLearningHomeSection extends StatelessWidget {
  const AtlasPremiumLearningHomeSection({super.key});

  static const _features = <_PremiumFeature>[
    _PremiumFeature(
      title: 'Smart Flashcards',
      subtitle: 'Recall • Revise • Retain',
      count: '200+ CARDS',
      icon: Icons.style_rounded,
      colors: [Color(0xFF2457A7), Color(0xFF4B83D0)],
      description: 'A structured medical recall library with concise question-and-answer cards, subject filters, bookmarks, confidence ratings and spaced review.',
      topics: ['Anatomy and neuroanatomy', 'Physiology and biochemistry', 'Pathology and microbiology', 'Pharmacology and clinical medicine'],
      deliverable: 'At least 200 authored cards',
    ),
    _PremiumFeature(
      title: 'AI Medical Tutor',
      subtitle: 'Ask • Understand • Apply',
      count: 'AI LEARNING',
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFF5141A8), Color(0xFF8A6BD6)],
      description: 'A medically focused tutor for concept explanations, clinical reasoning, MCQ discussions and revision plans, with safe boundaries and cited learning references.',
      topics: ['Explain a difficult concept', 'Discuss clinical reasoning', 'Review MCQ explanations', 'Create focused revision summaries'],
      deliverable: 'Secure AI-powered tutor',
    ),
    _PremiumFeature(
      title: 'OSCE Simulator',
      subtitle: 'Practice clinical stations',
      count: '80+ STATIONS',
      icon: Icons.medical_services_rounded,
      colors: [Color(0xFF087D78), Color(0xFF35A99C)],
      description: 'Interactive examination stations with patient briefs, history prompts, examination findings, investigations, expected actions and examiner marking checklists.',
      topics: ['History taking', 'Physical examination', 'Communication and counselling', 'Diagnosis and management'],
      deliverable: 'At least 80 authored simulations',
    ),
    _PremiumFeature(
      title: 'ECG Interpretation',
      subtitle: 'Read rhythms with confidence',
      count: '80+ ECG CASES',
      icon: Icons.monitor_heart_rounded,
      colors: [Color(0xFFB44854), Color(0xFFE17A77)],
      description: 'A progressive ECG case library with authentic teaching tracings, systematic interpretation, diagnosis, clinical significance and explanations.',
      topics: ['Rate, rhythm and axis', 'Intervals and waveforms', 'Ischaemia and infarction', 'Arrhythmias and conduction disorders'],
      deliverable: 'At least 80 ECG cases',
    ),
    _PremiumFeature(
      title: 'Radiology Lab',
      subtitle: 'Learn through diagnostic images',
      count: '80+ IMAGE CASES',
      icon: Icons radiology_rounded,
      colors: [Color(0xFF236C83), Color(0xFF48A2B5)],
      description: 'Image-led diagnostic learning using labelled findings, structured reporting, differential diagnoses and case explanations.',
      topics: ['Chest and musculoskeletal X-rays', 'CT and MRI cases', 'Ultrasound and abdominal imaging', 'Normal anatomy and pathology'],
      deliverable: 'At least 80 image-based cases',
    ),
    _PremiumFeature(
      title: 'Clinical Pharmacology',
      subtitle: 'A practical drug reference',
      count: 'DRUG LIBRARY',
      icon: Icons.medication_rounded,
      colors: [Color(0xFF9B6721), Color(0xFFD49B43)],
      description: 'A searchable educational formulary organised by drug class, with mechanisms, indications, dosing context, precautions, interactions and monitoring.',
      topics: ['Mechanism and pharmacokinetics', 'Indications and dosing', 'Contraindications and adverse effects', 'Interactions, monitoring and toxicity'],
      deliverable: 'Comprehensive generic-drug coverage',
    ),
    _PremiumFeature(
      title: 'Daily Medical Challenge',
      subtitle: 'One challenge every day',
      count: '200+ DAYS',
      icon: Icons.local_fire_department_rounded,
      colors: [Color(0xFFB64E24), Color(0xFFE58A45)],
      description: 'A daily medical question or clinical challenge with an explanation, completion history, streak calendar and achievement milestones.',
      topics: ['Clinical MCQs and vignettes', 'Image-based spotters', 'Daily explanations', 'Streaks and achievement badges'],
      deliverable: 'At least 200 scheduled challenges',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ATLAS LEARNING SUITE',
                      style: TextStyle(color: AtlasColors.royalBlue, fontSize: 10,
                          fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                  SizedBox(height: 5),
                  Text('Explore advanced learning',
                      style: TextStyle(color: AtlasColors.navy, fontSize: 19,
                          fontWeight: FontWeight.w900, letterSpacing: -.35)),
                  SizedBox(height: 3),
                  Text('Clinical skills, visual diagnosis and smarter revision.',
                      style: TextStyle(color: AtlasColors.secondaryText, fontSize: 11,
                          height: 1.4)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('7 MODULES', style: TextStyle(
                  color: AtlasColors.royalBlue, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 13),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _features.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.08,
          ),
          itemBuilder: (context, index) {
            final feature = _features[index];
            return _PremiumFeatureCard(
              feature: feature,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => feature.title == 'Smart Flashcards'
                    ? const AtlasFlashcardsScreen()
                    : _PremiumFeatureDetailScreen(feature: feature),
              )),
            );
          },
        ),
      ],
    );
  }
}

class _PremiumFeature {
  final String title;
  final String subtitle;
  final String count;
  final IconData icon;
  final List<Color> colors;
  final String description;
  final List<String> topics;
  final String deliverable;

  const _PremiumFeature({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.colors,
    required this.description,
    required this.topics,
    required this.deliverable,
  });
}

class _PremiumFeatureCard extends StatelessWidget {
  final _PremiumFeature feature;
  final VoidCallback onTap;

  const _PremiumFeatureCard({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFDCE8F2)),
            boxShadow: const [
              BoxShadow(color: Color(0x080E315A), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: feature.colors),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(feature.icon, color: Colors.white, size: 21),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded,
                      color: AtlasColors.secondaryText, size: 16),
                ],
              ),
              const Spacer(),
              Text(feature.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AtlasColors.navy, fontSize: 13,
                      height: 1.2, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(feature.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 9)),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: feature.colors.first.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(feature.count, maxLines: 1,
                    style: TextStyle(color: feature.colors.first, fontSize: 8,
                        letterSpacing: .55, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumFeatureDetailScreen extends StatelessWidget {
  final _PremiumFeature feature;
  const _PremiumFeatureDetailScreen({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(title: Text(feature.title)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: feature.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .17),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(feature.icon, color: Colors.white, size: 29),
                ),
                const SizedBox(height: 18),
                Text(feature.title, style: const TextStyle(
                    color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                Text(feature.subtitle, style: const TextStyle(
                    color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 15),
                Text(feature.deliverable.toUpperCase(), style: const TextStyle(
                    color: Colors.white, fontSize: 10, letterSpacing: 1,
                    fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('ABOUT THIS MODULE', style: TextStyle(
              color: AtlasColors.royalBlue, fontSize: 10, letterSpacing: 1.1,
              fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(feature.description, style: const TextStyle(
              color: AtlasColors.charcoal, fontSize: 14, height: 1.65)),
          const SizedBox(height: 20),
          const Text('WHAT YOU WILL LEARN', style: TextStyle(
              color: AtlasColors.royalBlue, fontSize: 10, letterSpacing: 1.1,
              fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          ...feature.topics.map((topic) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.check_circle_rounded, color: feature.colors.first, size: 20),
              title: Text(topic, style: const TextStyle(
                  color: AtlasColors.charcoal, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FC),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD7E6F7)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: AtlasColors.royalBlue, size: 19),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Educational content is being authored and quality-checked for this module. Clinical material will be presented for learning, not as patient-specific medical advice.',
                  style: TextStyle(color: AtlasColors.charcoal, fontSize: 11, height: 1.5),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
