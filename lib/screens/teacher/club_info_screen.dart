import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';

/// Edit club info: the About text and the regular meetings shown on the club
/// page. Only the club's adviser can open it. Saved in this preview only.
class ClubInfoScreen extends StatefulWidget {
  final CampusService campusService;
  final String orgId;

  const ClubInfoScreen({super.key, required this.campusService, required this.orgId});

  @override
  State<ClubInfoScreen> createState() => _ClubInfoScreenState();
}

/// One meeting's three fields.
class _MeetingFields {
  final title = TextEditingController();
  final when = TextEditingController();
  final place = TextEditingController();

  _MeetingFields([OrgMeeting? m]) {
    title.text = m?.title ?? '';
    when.text = m?.when ?? '';
    place.text = m?.place ?? '';
  }

  void dispose() {
    title.dispose();
    when.dispose();
    place.dispose();
  }
}

class _ClubInfoScreenState extends State<ClubInfoScreen> {
  Future<ClubAdmin?>? _load;
  final _about = TextEditingController();
  final _meetings = <_MeetingFields>[];
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= widget.campusService
        .loadClubAdmin(SessionScope.of(context).user!, widget.orgId)
        .then((a) {
      if (a != null) {
        _about.text = a.org.about;
        _meetings.addAll([for (final m in a.org.meetings) _MeetingFields(m)]);
      }
      return a;
    });
  }

  @override
  void dispose() {
    _about.dispose();
    for (final m in _meetings) {
      m.dispose();
    }
    super.dispose();
  }

  String? get _problem => _meetings.any((m) => m.title.text.trim().isEmpty || m.when.text.trim().isEmpty)
      ? 'Each meeting needs a name and a time.'
      : null;

  Future<void> _save() async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.campusService.updateClubInfo(
        session.user!,
        widget.orgId,
        about: _about.text,
        meetings: [
          for (final m in _meetings)
            OrgMeeting(title: m.title.text, when: m.when.text, place: m.place.text),
        ],
      );
    } catch (e) {
      // Never claim success when the save failed.
      final reason = e is ArgumentError ? '${e.message}' : e is StateError ? e.message : null;
      if (mounted) setState(() => _error = 'Not saved. ${reason ?? "Couldn't reach the service."}');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    router.pop();
    session.refresh();
    messenger.showSnackBar(const SnackBar(content: Text('Club info saved in this preview only.')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ClubAdmin?>(
          future: _load,
          builder: (context, snap) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackHeader('Edit club info'),
                if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snap.hasError || snap.data == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: Text(
                        snap.hasError
                            ? "Couldn't load this club."
                            : "You aren't an adviser of this club.",
                        style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                  )
                else ...[
                  Expanded(child: _form()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
                    child: FilledButton(
                      onPressed: !_saving && _problem == null ? _save : null,
                      child: Text(_saving ? 'Saving…' : 'Save Changes'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _form() {
    final text = Theme.of(context).textTheme;
    final problem = _error ?? _problem;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
      children: [
        _label('About'),
        TextField(
          controller: _about,
          minLines: 3,
          maxLines: 8,
          maxLength: 600,
          decoration: const InputDecoration(hintText: 'What is the club about?'),
        ),
        _label('Regular meetings'),
        for (var i = 0; i < _meetings.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _meetings[i].title,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: 'Name, e.g. Build session'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove this meeting',
                      onPressed: () => setState(() => _meetings.removeAt(i).dispose()),
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _meetings[i].when,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'When, e.g. Every Thursday · 4:00 PM'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _meetings[i].place,
                  decoration: const InputDecoration(hintText: 'Where (optional)'),
                ),
              ],
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _meetings.add(_MeetingFields())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add meeting'),
          ),
        ),
        if (problem != null)
          Text(problem, style: text.bodyMedium?.copyWith(color: AppColors.red)),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(s,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.muted)),
      );
}
