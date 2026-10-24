import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/campus.dart';
import 'package:michaelean_app/models/feed.dart';
import 'package:michaelean_app/models/user_profile.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

const css = 'org1';
const robotics = 'org6';

/// Signs in with shared services, so changes carry over between sign-ins.
Future<void> signIn(WidgetTester tester, String role, MockCampusService campus,
    MockHomeService home) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(campus: campus),
    homeService: home,
    campusService: campus,
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
}

/// Opens Michaelean Life › Clubs You Advise › [club].
Future<void> openManage(WidgetTester tester, String club) async {
  await tester.tap(find.text('Michaelean Life'));
  await tester.pumpAndSettle();
  final row = find.text(club);
  await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(row); // to the top, clear of the nav bar
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

bool hasTag(UserProfile u, String label) => u.tags.any((t) => t.label == label);

void main() {
  late MockCampusService campus;
  late MockHomeService home;
  setUp(() {
    campus = MockCampusService(delay: Duration.zero);
    home = MockHomeService(delay: Duration.zero, campus: campus);
  });

  group('service', () {
    test('Mark advises CSS and the Robotics Club; students advise nothing', () async {
      final clubs = await campus.loadAdvisedClubs(mockTeacher);
      expect({for (final c in clubs) c.org.id: c.requests}, {css: 2, robotics: 3});
      expect(await campus.loadAdvisedClubs(mockStudent), isEmpty);
      expect(await campus.loadClubAdmin(mockStudent, robotics), isNull);
      // Clubs without an adviser in this preview can't be managed by him.
      expect(await campus.loadClubAdmin(mockTeacher, 'org3'), isNull);
    });

    test('only the adviser can change a club', () async {
      final someoneId = (await campus.loadClubAdmin(mockTeacher, robotics))!.members.first.id;
      for (final act in <Future<void> Function()>[
        () => campus.addMember(mockStudent, robotics, 'stu-BSCS2A5'),
        () => campus.removeMember(mockStudent, robotics, someoneId),
        () => campus.setOfficerPosition(mockStudent, robotics, someoneId, 'Treasurer'),
        () => campus.updateClubInfo(mockStudent, robotics, about: 'x', meetings: const []),
        () => campus.answerJoinRequest(mockStudent, robotics, 'stu-BSCS3A11', accept: true),
        () => campus.addMember(mockTeacher, 'org3', 'stu-BSCS2A5'), // not his club
      ]) {
        await expectLater(act(), throwsStateError);
      }
    });

    test('accepting a request makes a member and tells the student', () async {
      await campus.requestToJoin(mockStudent, robotics);
      expect((await campus.loadClubAdmin(mockTeacher, robotics))!.requests.last.name,
          'Nicolas Santos');
      await campus.answerJoinRequest(mockTeacher, robotics, mockStudent.id, accept: true);

      final nicolas = campus.withAffiliations(mockStudent);
      expect(hasTag(nicolas, 'SMCL Robotics Club'), isTrue);
      expect((await campus.loadOrganization(nicolas, robotics))!.isMember, isTrue);
      expect((await campus.loadMyOrganizations(nicolas)).map((o) => o.id), contains(robotics));
      expect((await campus.loadMembershipNotices(mockStudent)).single.title,
          'Your request to join SMCL Robotics Club was accepted.');
      await expectLater(
          campus.answerJoinRequest(mockTeacher, robotics, mockStudent.id, accept: false),
          throwsStateError); // already answered
    });

    test('declining keeps them out and passes the reason on', () async {
      await campus.answerJoinRequest(mockTeacher, robotics, 'stu-BSCS3A11',
          accept: false, reason: 'Full this semester');
      final admin = (await campus.loadClubAdmin(mockTeacher, robotics))!;
      expect(admin.requests.map((m) => m.id), isNot(contains('stu-BSCS3A11')));
      expect(admin.members.map((m) => m.id), isNot(contains('stu-BSCS3A11')));
      final notice = (await campus.loadMembershipNotices(
              mockStudent.withTags(mockStudent.tags).copyId('stu-BSCS3A11')))
          .single;
      expect(notice.title, contains('declined'));
      expect(notice.title, contains('Reason: Full this semester'));
    });

    test('removing Nicolas from CSS removes his tag and membership', () async {
      expect(hasTag(campus.withAffiliations(mockStudent), 'Computer Science Society'), isTrue);
      await campus.removeMember(mockTeacher, css, mockStudent.id);
      final nicolas = campus.withAffiliations(mockStudent);
      expect(hasTag(nicolas, 'Computer Science Society'), isFalse);
      expect(hasTag(nicolas, 'SMCL Chorale'), isTrue); // other clubs untouched
      expect((await campus.loadOrganization(nicolas, css))!.isMember, isFalse);
      expect((await campus.loadMembershipNotices(mockStudent)).single.title,
          'You were removed from Computer Science Society.');
      await expectLater(campus.removeMember(mockTeacher, css, mockStudent.id), throwsStateError);
    });

    test('officer positions show on the club page and as a tag', () async {
      await campus.setOfficerPosition(mockTeacher, css, mockStudent.id, 'Treasurer');
      final officers = (await campus.loadOrganization(mockStudent, css))!.org.officers;
      expect(officers.map((o) => '${o.name}: ${o.position}'), [
        'Andrea Bautista: President',
        'Carlo Mendoza: Vice President',
        'Erika Lim: Secretary',
        'Nicolas Santos: Treasurer',
        'Mark Villanueva: Adviser',
      ]);
      expect(hasTag(campus.withAffiliations(mockStudent), 'Computer Science Society Officer'),
          isTrue);
      await campus.setOfficerPosition(mockTeacher, css, mockStudent.id, null);
      expect(hasTag(campus.withAffiliations(mockStudent), 'Computer Science Society Officer'),
          isFalse);
    });

    test('adding, searching, and member counts', () async {
      final before = (await campus.loadClubAdmin(mockTeacher, robotics))!.org.memberCount;
      final found = await campus.searchStudents(mockTeacher, robotics, 'ella');
      expect(found.map((m) => m.name), ['Ella Morales']);
      await campus.addMember(mockTeacher, robotics, found.single.id);
      expect((await campus.loadClubAdmin(mockTeacher, robotics))!.org.memberCount, before + 1);
      expect(await campus.searchStudents(mockTeacher, robotics, 'ella'), isEmpty);
      // People waiting to join aren't offered; they're answered under Requests.
      expect(await campus.searchStudents(mockTeacher, robotics, 'Kyla'), isEmpty);
    });

    test('club info: meetings need a name and a time', () async {
      await expectLater(
          campus.updateClubInfo(mockTeacher, robotics,
              about: 'x', meetings: const [OrgMeeting(title: '', when: '', place: '')]),
          throwsArgumentError);
      await campus.updateClubInfo(mockTeacher, robotics, about: ' Robots! ', meetings: const [
        OrgMeeting(title: 'Demo day', when: 'Last Friday · 3:00 PM', place: ''),
      ]);
      final o = (await campus.loadOrganization(mockStudent, robotics))!.org;
      expect(o.about, 'Robots!');
      expect(o.meetings.single.title, 'Demo day');
    });

    test('club posts: as the club, members only, urgent ones notify members', () async {
      final post = await home.savePost(mockTeacher,
          orgId: css,
          kind: PostKind.announcement,
          title: 'Meeting moved',
          body: 'Sample.',
          audience: 'Computer Science Society',
          urgent: true,
          sentTo: 'Members of Computer Science Society');
      expect(post.source, 'Computer Science Society');
      expect(post.kind, PostKind.organizationNews);

      final nicolas = campus.withAffiliations(mockStudent);
      expect((await home.loadClubPosts(nicolas, css)).single.title, 'Meeting moved');
      expect((await home.loadNotifications(nicolas)).map((n) => n.title),
          contains('Urgent: Computer Science Society: Meeting moved'));

      // A non-member doesn't see a members-only post.
      await campus.removeMember(mockTeacher, css, mockStudent.id);
      expect(await home.loadClubPosts(campus.withAffiliations(mockStudent), css), isEmpty);

      // Only the club's adviser can post as the club.
      await expectLater(
          home.savePost(mockStudent,
              orgId: css, kind: PostKind.announcement, title: 'x', body: 'y', sentTo: 't'),
          throwsStateError);
    });

    test("a teacher's tags show the roles they're assigned", () {
      final mark = campus.withAffiliations(mockTeacher);
      expect([for (final t in mark.tags) if (t.kind == TagKind.role) t.label], [
        'Computer Science Society Adviser',
        'SMCL Robotics Club Adviser',
        'Department of Computer Studies Clearance Staff',
      ]);
      // Applying it again doesn't duplicate them; students get no role tags.
      expect(campus.withAffiliations(mark).tags.length, mark.tags.length);
      expect(campus.withAffiliations(mockStudent).tags.where((t) => t.kind == TagKind.role),
          isEmpty);
    });

    test("advisers count as members for their clubs' members-only events", () async {
      // ev1 is for CSS members only; Mark advises CSS.
      expect(await campus.loadEvent(mockTeacher, 'ev1'), isNotNull);
      expect((await campus.loadEventAttendees(mockTeacher, 'ev1'))!.shown.length, 4);
      // ev6 is for Dance Company members; he doesn't advise it.
      expect(await campus.loadEvent(mockTeacher, 'ev6'), isNull);
    });

    test('club events are hosted by the club', () async {
      final day = DateTime.now().add(const Duration(days: 10));
      final e = await campus.saveEvent(mockTeacher,
          publish: true,
          title: 'Robot demo',
          start: DateTime(day.year, day.month, day.day, 15),
          end: DateTime(day.year, day.month, day.day, 17),
          venue: 'Lab 2',
          audience: 'SMCL Robotics Club',
          hostOrgId: robotics);
      expect(e.host, 'SMCL Robotics Club');
      expect((await campus.loadClubAdmin(mockTeacher, robotics))!.events.single.title,
          'Robot demo');
    });
  });

  testWidgets('Michaelean Life lists the clubs he advises, with requests', (tester) async {
    await signIn(tester, 'Teacher', campus, home);
    await tester.tap(find.text('Michaelean Life'));
    await tester.pumpAndSettle();
    final pill = find.text('3 requests');
    await tester.scrollUntilVisible(pill, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Clubs You Advise'), findsOneWidget);
    expect(pill, findsOneWidget); // the Robotics Club
  });

  testWidgets('accept a request on the Manage club page', (tester) async {
    await signIn(tester, 'Teacher', campus, home);
    await openManage(tester, 'SMCL Robotics Club');
    expect(find.text('6 members'), findsOneWidget);
    await tester.tap(find.text('Requests (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Accepted in this preview only'), findsOneWidget);
    expect(find.text('Requests (2)'), findsOneWidget);
    expect(find.text('7 members'), findsOneWidget);
  });

  testWidgets('remove a member, with a confirmation', (tester) async {
    await signIn(tester, 'Teacher', campus, home);
    await openManage(tester, 'SMCL Robotics Club');
    final options = find.byTooltip('Options for Leo Marquez');
    await tester.scrollUntilVisible(options, 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150)); // clear of the nav bar
    await tester.pumpAndSettle();
    await tester.tap(options);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from club'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Leo Marquez?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Removed in this preview only'), findsOneWidget);
    expect(find.text('Leo Marquez'), findsNothing);
  });

  testWidgets('add a member by searching', (tester) async {
    await signIn(tester, 'Teacher', campus, home);
    await openManage(tester, 'SMCL Robotics Club');
    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ella');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ella Morales added in this preview only'), findsOneWidget);
    expect(find.text('Ella Morales'), findsNothing); // no longer offered
  });

  testWidgets("the teacher's Profile shows his adviser tags", (tester) async {
    await signIn(tester, 'Teacher', campus, home);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final tag = find.text('SMCL Robotics Club Adviser');
    await tester.scrollUntilVisible(tag, 200, scrollable: find.byType(Scrollable).first);
    expect(tag, findsOneWidget);
    expect(find.text('Department of Computer Studies Clearance Staff'), findsOneWidget);
  });

  testWidgets("a student sees the adviser's decision", (tester) async {
    await tester.runAsync(() async {
      await campus.requestToJoin(mockStudent, robotics);
      await campus.answerJoinRequest(mockTeacher, robotics, mockStudent.id, accept: true);
    });
    await signIn(tester, 'Student', campus, home);
    await tester.tap(find.byTooltip(RegExp('^Notifications')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your request to join SMCL Robotics Club was accepted.'));
    await tester.pumpAndSettle();
    expect(find.text('Member'), findsOneWidget); // the club page opened
  });
}

extension on UserProfile {
  /// A copy with another id, to read a sample student's notices.
  UserProfile copyId(String id) => UserProfile(
        id: id,
        role: role,
        firstName: firstName,
        lastName: lastName,
        designation: designation,
        maskedId: maskedId,
        email: email,
        qrToken: qrToken,
        tags: tags,
      );
}
