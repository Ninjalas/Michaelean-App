// Club officers manage their own club like its adviser (decided 2026-10-31):
// posts, events, members (officers and positions too), About and meetings.
// Being an officer comes from the club's member list; mockOfficerPowers says
// what officers may do. Nicolas is CSS's Public Relations Officer.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_campus.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/campus.dart';
import 'package:michaelean_app/models/feed.dart';
import 'package:michaelean_app/models/user_profile.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

const css = 'org1';
const robotics = 'org6';

/// A CSS member without a position (Francis Tan's classmate Joshua is in
/// Robotics; Isabel Cruz is a plain CSS member).
const plainMember = UserProfile(
    id: 'stu-BSCS3A9', role: UserRole.student, firstName: 'Isabel', lastName: 'Cruz',
    designation: 'BSCS 3A', maskedId: '', email: '', qrToken: '', tags: []);

void main() {
  late MockCampusService campus;
  late MockHomeService home;
  setUp(() {
    campus = MockCampusService(delay: Duration.zero);
    home = MockHomeService(delay: Duration.zero, campus: campus);
  });

  test('officers get every listed power; the list is explicit mock data', () {
    expect(mockOfficerPowers, ClubPower.values.toSet());
    expect(mockClubMembers[css]![mockStudent.id], 'Public Relations Officer');
  });

  test('an officer manages members, positions, and About for their club', () async {
    expect((await campus.loadAdvisedClubs(mockStudent)).map((c) => c.org.id), [css]);
    expect(await campus.loadClubAdmin(mockStudent, css), isNotNull);
    await campus.addMember(mockStudent, css, 'stu-BSCS2A5');
    await campus.setOfficerPosition(mockStudent, css, 'stu-BSCS2A5', 'Treasurer');
    await campus.removeMember(mockStudent, css, 'stu-BSCS3A2'); // another officer
    await campus.updateClubInfo(mockStudent, css, about: 'By the PRO.', meetings: const []);
    final admin = (await campus.loadClubAdmin(mockStudent, css))!;
    expect(admin.org.about, 'By the PRO.');
    expect(admin.members.map((m) => m.id), isNot(contains('stu-BSCS3A2')));
  });

  test("not another club's, and not a plain member's", () async {
    expect(() => campus.addMember(mockStudent, robotics, 'stu-BSCS2A5'), throwsStateError);
    expect(await campus.loadClubAdmin(plainMember, css), isNull);
    expect(() => campus.addMember(plainMember, css, 'stu-BSCS2A5'), throwsStateError);
    expect(
        () => home.savePost(plainMember,
            orgId: css, kind: PostKind.organizationNews, title: 'x', body: 'y', sentTo: 'test'),
        throwsStateError);
  });

  test('an officer posts for the club; it notifies members', () async {
    final p = await home.savePost(mockStudent,
        orgId: css,
        kind: PostKind.organizationNews,
        title: 'Hackathon sign-ups',
        body: 'Sample.',
        audience: 'Computer Science Society',
        sentTo: 'Members of Computer Science Society');
    expect(p.source, 'Computer Science Society');
    expect((await home.loadClubPosts(mockStudent, css)).map((p) => p.id), contains(p.id));
  });

  test('club events: officers publish directly; the adviser can edit them', () async {
    final now = DateTime.now();
    final e = await campus.saveEvent(mockStudent,
        hostOrgId: css,
        publish: true,
        title: 'CSS Study Jam',
        start: now.add(const Duration(days: 6)),
        end: now.add(const Duration(days: 6, hours: 2)),
        venue: 'Saint Theodore Hall · Lab 2');
    expect(e.status, EventStatus.published);
    expect((await campus.loadEvent(mockTeacher, e.id))!.canManage, isTrue); // the adviser
    expect((await campus.loadEvent(plainMember, e.id))!.canManage, isFalse);
    // Older sample CSS events weren't made in the app: still register-only.
    expect((await campus.loadEvent(mockStudent, 'ev1'))!.canManage, isFalse);
    // Officers invite clubs and students, not class sections.
    expect((await campus.loadInviteOptions(mockStudent, e.id))!.sections, isEmpty);
  });

  test('giving up your own position ends your access', () async {
    await campus.setOfficerPosition(mockStudent, css, mockStudent.id, null);
    expect(await campus.loadClubAdmin(mockStudent, css), isNull);
  });

  group('screens', () {
    Future<void> push(WidgetTester tester, String path) async {
      GoRouter.of(tester.element(find.byType(Scaffold).last)).push(path);
      await tester.pumpAndSettle();
    }

    Future<void> openClub(WidgetTester tester, String orgId) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final campus = MockCampusService(delay: Duration.zero);
      await tester.pumpWidget(MichaeleanApp(
        userService: MockUserService(campus: campus),
        homeService: MockHomeService(delay: Duration.zero, campus: campus),
        campusService: campus,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with Microsoft (preview)')); // as Nicolas
      await tester.pumpAndSettle();
      // From Student Life, as a student reaches their club.
      await tester.tap(find.text('Student Life'));
      await tester.pumpAndSettle();
      await push(tester, '/life/organizations/$orgId');
    }

    testWidgets('Manage club shows for his club only', (tester) async {
      await openClub(tester, robotics);
      expect(find.text('Manage club'), findsNothing);
      await push(tester, '/life/organizations/$css');
      expect(find.text('Manage club'), findsOneWidget);
      await tester.tap(find.text('Manage club'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Changes stay in this preview'), findsOneWidget);
      expect(find.text("You're its Public Relations Officer"), findsOneWidget); // not "adviser"
    });

    testWidgets('giving up his position asks first, then leaves Manage club', (tester) async {
      await openClub(tester, css);
      await tester.tap(find.text('Manage club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();
      final options = find.byTooltip('Options for Nicolas Santos');
      await tester.scrollUntilVisible(options, 200, scrollable: find.byType(Scrollable).first);
      Scrollable.ensureVisible(tester.element(options), alignment: 0.5); // clear of the nav bar
      await tester.pumpAndSettle();
      await tester.tap(options);
      await tester.pumpAndSettle();
      expect(find.text('Leave club'), findsOneWidget);
      await tester.tap(find.text('Set position'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No position (member)'));
      await tester.pumpAndSettle();
      expect(find.textContaining("You'll lose access to managing this club."), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100)); // the club page reloads
      await tester.pumpAndSettle();
      expect(find.textContaining('Changes stay in this preview'), findsNothing); // left the page
      expect(find.text('Manage club'), findsNothing); // and the button is gone
    });
  });
}
