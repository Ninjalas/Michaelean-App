import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/campus.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/org_row.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';

/// The Organizations directory (spec §7.4), in three groups: the student's
/// departmental society, school-wide clubs, and My Organizations.
class OrganizationsScreen extends StatefulWidget {
  final CampusService campusService;

  const OrganizationsScreen({super.key, required this.campusService});

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  Future<OrgDirectory>? _data;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session.user != null && session.dataKey != _loadedFor) {
      _loadedFor = session.dataKey;
      _data = widget.campusService.loadOrganizationDirectory(session.user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Organizations'),
            Expanded(
              child: FutureBuilder<OrgDirectory>(
                future: _data,
                builder: fadeOnLoad((context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Couldn't load organizations."),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: () => setState(() => _data = widget.campusService
                                .loadOrganizationDirectory(SessionScope.of(context).user!)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final d = snap.data;
                  if (d == null) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  final memberOf = d.mine.map((o) => o.id).toSet();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, 0, AppSpacing.screen, 120),
                    children: [
                      ..._group('Your Department Society', d.society, memberOf,
                          empty: Text('Your department has no student society listed.',
                              style: muted)),
                      ..._group('School-wide Clubs', d.clubs, memberOf),
                      ..._group('My Organizations', d.mine, memberOf,
                          showMember: false,
                          empty: Text("You haven't joined any organizations yet.",
                              style: muted)),
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

  List<Widget> _group(String title, List<Organization> orgs, Set<String> memberOf,
      {bool showMember = true, Widget? empty}) {
    return [
      SectionHeader(title),
      if (orgs.isEmpty && empty != null) empty,
      for (var i = 0; i < orgs.length; i++) ...[
        if (i > 0) const Divider(height: 1, indent: OrgRow.textIndent),
        OrgRow(
          org: orgs[i],
          pill: showMember && memberOf.contains(orgs[i].id)
              ? const StatusPill('Member', tone: PillTone.green)
              : null,
          onTap: () => context.push('/life/organizations/${orgs[i].id}'),
        ),
      ],
    ];
  }
}
