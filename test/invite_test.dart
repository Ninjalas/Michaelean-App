// Teachers invite their sections, all members of any club, or single
// students (decided 2026-10-30). Only eligible students; each once; invited
// students get a bell notice in this preview.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

void main() {
  late MockCampusService s;
  setUp(() => s = MockCampusService(delay: Duration.zero));

  test('a section and a club together count each student once', () async {
    // ev2 (Department Assembly) already has 5 of BSCS 3A. The section adds the
    // other 7; CSS adds its 3 members from other sections.
    expect(await s.invite(mockTeacher, 'ev2', sections: ['BSCS 3A'], orgIds: ['org1']), 10);
  });

  test('a single student is registered and gets a bell notice', () async {
    expect(await s.invite(mockTeacher, 'ev2', studentIds: [mockStudent.id]), 1);
    final mine = (await s.loadEvent(mockStudent, 'ev2'))!;
    expect((mine.registered, mine.invited), (true, true));
    final notice = (await s.loadMembershipNotices(mockStudent))
        .singleWhere((n) => n.title == 'Mark Villanueva registered you for Department Assembly.');
    expect(notice.route, '/life/events/ev2');
  });

  test('members-only events take only members; spots are checked', () async {
    final now = DateTime.now();
    final e = await s.saveEvent(mockTeacher,
        publish: true,
        title: 'Dance workshop',
        start: now.add(const Duration(days: 5)),
        end: now.add(const Duration(days: 5, hours: 2)),
        venue: 'Main Auditorium',
        audience: 'Dance Company',
        capacity: 5);
    final options = (await s.loadInviteOptions(mockTeacher, e.id))!;
    expect(options.spotsLeft, 5);
    expect(options.students.singleWhere((c) => c.id == mockStudent.id).unavailable,
        'Not a member of Dance Company');
    // Picked by name: refused. A whole club: only its eligible members (none here).
    expect(() => s.invite(mockTeacher, e.id, studentIds: [mockStudent.id]), throwsStateError);
    expect(await s.invite(mockTeacher, e.id, orgIds: ['org2']), 0); // Chorale
    // Dance Company has 8 members but only 5 spots: nobody is invited.
    expect(() => s.invite(mockTeacher, e.id, orgIds: ['org3']), throwsStateError);
    expect((await s.loadRegistrations(mockTeacher, e.id))!, isEmpty);
  });

  test('every school-wide club offers its member list; only managers get options', () async {
    final clubs = (await s.loadInviteOptions(mockTeacher, 'ev2'))!.clubs;
    expect(clubs.map((c) => c.name), containsAll([
      'Computer Science Society',
      'SMCL Chorale',
      'Dance Company',
      'Campus Ministry Volunteers',
      'SMCL Robotics Club',
    ]));
    expect(clubs.singleWhere((c) => c.name == 'Dance Company').detail, '8 members');
    expect(await s.loadInviteOptions(mockStudent, 'ev2'), isNull);
  });

  testWidgets('the page adds up a club and a student picked by name', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final campus = MockCampusService(delay: Duration.zero);
    await tester.pumpWidget(MichaeleanApp(
      userService: MockUserService(),
      homeService: MockHomeService(delay: Duration.zero, campus: campus),
      campusService: campus,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teacher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open preview'));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/life/events/ev2/invite');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clubs'));
    await tester.pumpAndSettle();
    // Diego is already going, so 5 of the Robotics Club's 6 would be registered.
    expect(find.text('6 members · 5 can be invited'), findsOneWidget);
    await tester.tap(find.text('SMCL Robotics Club'));
    await tester.pumpAndSettle();
    expect(find.text('Invite 5 Students'), findsOneWidget);

    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Aira');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aira Domingo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite 6 Students'));
    await tester.pumpAndSettle();
    expect(find.textContaining('6 students registered in this preview only'), findsOneWidget);
  });
}
