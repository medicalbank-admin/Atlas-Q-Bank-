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
    (
      kind: 'AYAT OF THE DAY',
      text: 'My Lord, increase me in knowledge.',
      source: 'Qur’an 20:114',
    ),
    (
      kind: 'HADITH OF THE DAY',
      text: 'Whoever follows a path in pursuit of knowledge, Allah will make easy for him a path to Paradise.',
      source: 'Sahih Muslim 2699',
    ),
    (
      kind: 'DAILY MOTIVATION',
      text: 'Learn with purpose. Practice with consistency. Serve with excellence.',
      source: 'A reminder for your medical journey',
    ),
    (
      kind: 'AYAT OF THE DAY',
      text: 'Are those who know equal to those who do not know?',
      source: 'Qur’an 39:9',
    ),
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
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.multiply),
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
                  children: List.generate(_reminders.length, (i) => Container(
                    width: i == _index ? 17 : 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i == _index
                          ? const Color(0xFF2563A6)
                          : const Color(0xFF9CBBDD),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
