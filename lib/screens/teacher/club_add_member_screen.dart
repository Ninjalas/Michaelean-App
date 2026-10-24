import 'package:flutter/material.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_rows.dart';
import '../../widgets/back_header.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/user_avatar.dart';

/// Add member: the adviser searches the sample students and adds them one
/// by one. Students already in the club, or waiting to join, aren't listed
/// (answer those under Requests).
class ClubAddMemberScreen extends StatefulWidget {
  final CampusService campusService;
  final String orgId;

  const ClubAddMemberScreen({super.key, required this.campusService, required this.orgId});

  @override
  State<ClubAddMemberScreen> createState() => _ClubAddMemberScreenState();
}

class _ClubAddMemberScreenState extends State<ClubAddMemberScreen> {
  Future<List<OrgMember>>? _results;
  String? _loadedFor;
  String _query = '';
  String? _adding; // student id being added

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final key = SessionScope.of(context).dataKey;
    if (key != _loadedFor) {
      _loadedFor = key;
      _search();
    }
  }

  void _search() => _results = widget.campusService
      .searchStudents(SessionScope.of(context).user!, widget.orgId, _query);

  Future<void> _add(OrgMember m) async {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding = m.id);
    try {
      await widget.campusService.addMember(session.user!, widget.orgId, m.id);
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Not added. ${e.message}')));
      return;
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Not added. Couldn't reach the service.")));
      return;
    } finally {
      if (mounted) setState(() => _adding = null);
    }
    session.refresh(); // the list drops them, and the club page updates
    messenger.showSnackBar(SnackBar(
      content: Text("${m.name} added in this preview only. They see a notice in this "
          "preview's bell."),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Add member'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() {
                  _query = v;
                  _search();
                }),
                decoration: const InputDecoration(
                  hintText: 'Search students by name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<OrgMember>>(
                future: _results,
                builder: fadeOnLoad((context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text("Couldn't search students.", style: muted),
                    );
                  }
                  final list = snap.data;
                  if (list == null) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text('No students to add match "$_query".', style: muted),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, 0, AppSpacing.screen, 120),
                    children: [
                      Text('Sample students from the class lists.',
                          style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                      // Someone you add folds away (spec §2.5).
                      AnimatedRows(
                        separator: const Divider(height: 1, indent: 56),
                        children: [
                          for (final m in list)
                            Padding(
                              key: ValueKey(m.id),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Row(
                                children: [
                                  UserAvatar(name: m.name, imageAsset: m.photoAsset, size: 44),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.name, style: text.titleMedium),
                                        Text('${m.section} · ${m.maskedId}',
                                            style:
                                                text.bodyMedium?.copyWith(color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: _adding == null ? () => _add(m) : null,
                                    child: Text(_adding == m.id ? 'Adding…' : 'Add'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
