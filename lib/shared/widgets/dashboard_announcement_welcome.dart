import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/atlas_academy_app.dart';

class DashboardAnnouncementWelcome extends StatefulWidget {
  final String displayName;
  const DashboardAnnouncementWelcome({super.key, required this.displayName});

  @override
  State<DashboardAnnouncementWelcome> createState() =>
      _DashboardAnnouncementWelcomeState();
}

class _DashboardAnnouncementWelcomeState
    extends State<DashboardAnnouncementWelcome> {
  static const _reminders = <({String kind, String text, String source})>[
    (kind: 'AYAT OF THE DAY', text: 'My Lord, increase me in knowledge.', source: 'Qur’an 20:114'),
    (kind: 'HADITH OF THE DAY', text: 'Whoever follows a path seeking knowledge, Allah will make a path to Paradise easy for him.', source: 'Sahih Muslim 2699a'),
    (kind: 'DAILY MOTIVATION', text: 'Learn with purpose. Practice with consistency. Serve with excellence.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'Are those who know equal to those who do not know?', source: 'Qur’an 39:9'),
    (kind: 'HADITH OF THE DAY', text: 'The reward of deeds depends upon intentions.', source: 'Sahih al-Bukhari 1'),
    (kind: 'DAILY MOTIVATION', text: 'Every expert was once a beginner who refused to give up.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'Indeed, Allah is with the patient.', source: 'Qur’an 2:153'),
    (kind: 'HADITH OF THE DAY', text: 'The most beloved deeds to Allah are those done regularly, even if they are few.', source: 'Sahih al-Bukhari 6464'),
    (kind: 'DAILY MOTIVATION', text: 'Small steps taken daily create remarkable progress.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'For indeed, with hardship comes ease.', source: 'Qur’an 94:5–6'),
    (kind: 'HADITH OF THE DAY', text: 'The strong believer is better and more beloved to Allah; seek what benefits you and seek Allah’s help.', source: 'Sahih Muslim 2664'),
    (kind: 'DAILY MOTIVATION', text: 'Let curiosity guide your study and compassion guide your care.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'Allah does not burden a soul beyond what it can bear.', source: 'Qur’an 2:286'),
    (kind: 'HADITH OF THE DAY', text: 'The best among you are those with the best character.', source: 'Sahih al-Bukhari 6029'),
    (kind: 'DAILY MOTIVATION', text: 'Consistency will carry you further than occasional intensity.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'Surely in the remembrance of Allah do hearts find comfort.', source: 'Qur’an 13:28'),
    (kind: 'HADITH OF THE DAY', text: 'Make things easy and do not make them difficult; give good tidings.', source: 'Sahih al-Bukhari 69'),
    (kind: 'DAILY MOTIVATION', text: 'Study not only to pass an exam, but to understand and help someone.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'If you are grateful, I will surely increase you.', source: 'Qur’an 14:7'),
    (kind: 'HADITH OF THE DAY', text: 'The believers, in their mutual kindness and compassion, are like one body.', source: 'Sahih al-Bukhari 6011'),
    (kind: 'DAILY MOTIVATION', text: 'A calm mind, a clear plan and a steady effort make a powerful combination.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'Do not lose heart or grieve; you will have the upper hand if you are believers.', source: 'Qur’an 3:139'),
    (kind: 'HADITH OF THE DAY', text: 'Whoever seeks knowledge, Allah makes a path to Paradise easy for him.', source: 'Jami‘ at-Tirmidhi 2646 (Hasan)'),
    (kind: 'DAILY MOTIVATION', text: 'Your future patients deserve the best of what you learn today.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'As for those who strive for Us, We will surely guide them to Our ways.', source: 'Qur’an 29:69'),
    (kind: 'DAILY MOTIVATION', text: 'Progress is built one focused session, one question and one lesson at a time.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'Whoever puts their trust in Allah, then He is sufficient for them.', source: 'Qur’an 65:3'),
    (kind: 'DAILY MOTIVATION', text: 'Be patient with the process and honest about the effort it requires.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'Do not despair of the mercy of Allah.', source: 'Qur’an 39:53'),
    (kind: 'DAILY MOTIVATION', text: 'Mistakes are not the end of learning; they are invitations to understand better.', source: 'A reminder for your medical journey'),
    (kind: 'AYAT OF THE DAY', text: 'Whoever does good, whether male or female, and is a believer, We will grant them a good life.', source: 'Qur’an 16:97'),
    (kind: 'DAILY MOTIVATION', text: 'Let every difficult topic become a reason to ask better questions.', source: 'A reminder for your medical journey'),
    (kind: 'DAILY MOTIVATION', text: 'Discipline is choosing the progress you want over the comfort you have now.', source: 'A reminder for your medical journey'),
    (kind: 'DAILY MOTIVATION', text: 'You do not need to know everything today; you need to keep learning today.', source: 'A reminder for your medical journey'),
    (kind: 'DAILY MOTIVATION', text: 'A thoughtful clinician listens carefully before reaching a conclusion.', source: 'A reminder for your medical journey'),
    (kind: 'DAILY MOTIVATION', text: 'Make room for rest; a healthy rhythm supports lasting learning.', source: 'A reminder for your medical journey'),
    (kind: 'DAILY MOTIVATION', text: 'Turn confusion into questions, and questions into understanding.', source: 'A reminder for your medical journey'),
    (kind: 'DAILY MOTIVATION', text: 'Your effort today is an investment in someone else’s tomorrow.', source: 'A reminder for your medical journey'),
    (kind: 'DAILY MOTIVATION', text: 'Stay humble enough to learn and confident enough to keep trying.', source: 'A reminder for your medical journey'),
    (kind: 'DAILY MOTIVATION', text: 'Excellence is built through knowledge, integrity and compassion.', source: 'A reminder for your medical journey'),
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _reminders.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminder = _reminders[_index];
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.fromLTRB(20, 19, 14, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5F2FF), Color(0xFFD8EAFF), Color(0xFFF0F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withValues(alpha: .95), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.royalBlue.withValues(alpha: .10),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -3,
            top: 3,
            bottom: 2,
            child: SizedBox(
              width: 139,
              child: Transform.flip(
                flipX: true,
                child: ColorFiltered(
                // The supplied JPG has a black canvas. Convert that canvas to
                // transparency while preserving the blue and silver instrument.
                colorFilter: const ColorFilter.matrix(<double>[
                  1, 0, 0, 0, 0,
                  0, 1, 0, 0, 0,
                  0, 0, 1, 0, 0,
                  1.2, 1.2, 1.2, 0, -0.10,
                ]),
                child: Image.asset(
                  'assets/images/IMG_20261123_044554.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
                    'assets/images/clinical_stethoscope.svg',
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF78A9D8), BlendMode.srcIn,
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 105),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${widget.displayName}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF123B68),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.65,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your journey to excellence continues',
                  maxLines: 2,
                  style: TextStyle(
                    color: Color(0xFF173B65),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 17),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_index),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.kind,
                        style: const TextStyle(
                          color: Color(0xFF2563A6),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '“${reminder.text}”',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF183B63),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.source,
                        style: const TextStyle(
                          color: Color(0xFF5D7897),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_index + 1) / _reminders.length,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFBDD4ED),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563A6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_index + 1).toString().padLeft(2, '0')} / 40',
                      style: const TextStyle(
                        color: Color(0xFF5D7897),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
