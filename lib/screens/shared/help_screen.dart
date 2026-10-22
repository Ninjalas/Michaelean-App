import 'package:flutter/material.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/inset_list.dart';

/// Help & Support (spec §11): short answers to common questions, then the
/// offices to contact. Nothing is sent from here.
class HelpScreen extends StatefulWidget {
  final CampusService campusService;

  const HelpScreen({super.key, required this.campusService});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  static const _faq = [
    (
      'How do I show my QR code?',
      'Press and hold Student Life (or Michaelean Life) in the bottom bar. Students can '
          'also tap Show QR on the Class screen.',
    ),
    (
      'When am I marked present in class?',
      'When your teacher scans your QR during the class and then finalizes attendance. '
          "Scans before the class starts or after it ends don't count, and a second scan "
          'counts once.',
    ),
    (
      'Does registering for an event count as attending?',
      "No. Registering saves your spot. Only attendance recorded at the event appears in "
          'your Event History.',
    ),
    (
      'What do the clearance statuses mean?',
      'Action required: something to do for the first time. In review: the office is '
          'checking it. Needs correction: the office returned it with a reason. On hold: '
          'contact the office. Not applicable: it doesn\'t apply to you.',
    ),
    (
      'Why does the app say "preview only"?',
      'Michaelean is a prototype. It uses sample data, and actions like registering or '
          'recording attendance are saved only in this preview, not in school records.',
    ),
  ];

  late final Future<List<SupportContact>> _contacts = widget.campusService.loadSupportContacts();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    final label = text.labelMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Help & Support'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                children: [
                  Text('Common questions', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  InsetGroup([
                    for (final (q, a) in _faq)
                      ExpansionTile(
                        title: Text(q, style: text.bodyLarge),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        childrenPadding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                        expandedAlignment: Alignment.centerLeft,
                        children: [Text(a, style: text.bodyMedium)],
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Contact an office', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  FutureBuilder<List<SupportContact>>(
                    future: _contacts,
                    builder: (context, snap) {
                      if (snap.hasError) return Text("Couldn't load the offices.", style: muted);
                      final list = snap.data;
                      if (list == null) return const LinearProgressIndicator();
                      return InsetGroup([
                        for (final c in list)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.office, style: text.titleMedium),
                                Text(c.helpsWith, style: muted),
                                const SizedBox(height: AppSpacing.xs),
                                Text('${c.place}\n${c.hours} · ${c.contact}',
                                    style: text.bodyMedium),
                              ],
                            ),
                          ),
                      ]);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Sample contacts for the prototype. The real directory will come from '
                      'the school.', style: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
