import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/people.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/person_row.dart';

/// People (spec §10.1): search students by name. With no search, students
/// see their suggestions and teachers see every student. Teachers view
/// profiles only; they don't connect.
class PeopleScreen extends StatefulWidget {
  final CampusService campusService;

  const PeopleScreen({super.key, required this.campusService});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  Future<List<PersonSummary>>? _results;
  String? _loadedFor;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final key = SessionScope.of(context).dataKey;
    if (key != _loadedFor) {
      _loadedFor = key; // reload after a Connect, so buttons show Pending
      _search();
    }
  }

  bool get _browsing => _query.trim().isEmpty;

  void _search() {
    final me = SessionScope.of(context).user!;
    _results = _browsing && me.role == UserRole.student
        ? widget.campusService.loadSuggestions(me)
        : widget.campusService.searchPeople(me, _query);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge?.copyWith(color: AppColors.muted);
    final isStudent = SessionScope.of(context).user?.role == UserRole.student;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('People'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
              child: TextField(
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
              child: FutureBuilder<List<PersonSummary>>(
                future: _results,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text("Couldn't load people.", style: muted),
                    );
                  }
                  final list = snap.data;
                  if (list == null) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  final heading = _browsing
                      ? (isStudent ? 'People you may know' : 'All students')
                      : 'Results';
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                    children: [
                      Text(heading,
                          style: text.labelMedium?.copyWith(color: AppColors.muted)),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Text(
                              _browsing
                                  ? 'No suggestions right now. Search for a name above.'
                                  : 'No students match "$_query".',
                              style: muted),
                        )
                      else
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: PersonRow.textIndent),
                          PersonRow(
                            person: list[i],
                            onTap: () => context.push('/life/people/${list[i].id}'),
                            trailing: connectAction(context, widget.campusService, list[i]),
                          ),
                        ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
