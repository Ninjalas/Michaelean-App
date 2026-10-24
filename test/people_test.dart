// Connect, step 1 (spec §10.1): the data and "who can see what" rules.

import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/feed.dart';
import 'package:michaelean_app/models/people.dart';
import 'package:michaelean_app/models/user_profile.dart';
import 'package:michaelean_app/screens/shared/going_screen.dart' show goingLine;
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';

const andrea = 'stu-BSCS3A1'; // connected to Nicolas; everything Public
const carlo = 'stu-BSCS3A2'; // connected; default settings
const bea = 'stu-BSCS3A3'; // asked Nicolas to connect; upcoming events Public
const erika = 'stu-BSCS3A5'; // connected; upcoming events Only me
const diego = 'stu-BSCS3A4'; // connected; history Only me, connections Public
const aira = 'stu-BSCS2A1'; // asked Nicolas to connect
const alyssa = 'stu-BSCS3B1'; // Nicolas asked her; upcoming and history Public
const celine = 'stu-BSCS3B3'; // a stranger to Nicolas; default settings

/// A sample student as a signed-in viewer, to act as someone else.
UserProfile asStudent(String id, String first, String last) => UserProfile(
      id: id,
      role: UserRole.student,
      firstName: first,
      lastName: last,
      designation: '',
      maskedId: '',
      email: '',
      qrToken: '',
      tags: const [],
    );

void main() {
  late MockCampusService campus;
  setUp(() => campus = MockCampusService(delay: Duration.zero));
  final me = mockStudent; // Nicolas

  group('who can see what', () {
    test('a connection sees what is set to Connections', () async {
      final p = (await campus.loadPerson(me, carlo))!;
      expect(p.person.status, ConnectionStatus.connected);
      expect(p.upcoming, isNotNull);
      expect(p.history!.map((r) => r.eventId), containsAll(['past-git', 'past-iris']));
      expect(p.connections, isNotNull);
    });

    test('Only me hides it even from connections', () async {
      expect((await campus.loadPerson(me, erika))!.upcoming, isNull);
      expect((await campus.loadPerson(me, diego))!.history, isNull);
    });

    test('a stranger sees the basics and Public parts only', () async {
      final p = (await campus.loadPerson(me, celine))!;
      expect(p.person.status, ConnectionStatus.none);
      expect(p.tags.map((t) => t.label), contains('Department of Computer Studies'));
      expect(p.connectionCount, 1);
      expect(p.upcoming, isNull);
      expect(p.history, isNull);
      expect(p.connections, isNull);

      final a = (await campus.loadPerson(me, alyssa))!; // Public upcoming and history
      expect(a.upcoming, isNotNull);
      expect(a.history, isNotNull);
      expect(a.connections, isNull); // still Connections only
    });

    test('mutual connections are shown, and counted in lists', () async {
      final p = (await campus.loadPerson(me, bea))!;
      expect(p.mutualConnections.map((m) => m.name), ['Andrea Bautista', 'Carlo Mendoza']);
      expect(p.person.mutual, 2);
    });

    test('teachers see everything, whatever the settings', () async {
      final p = (await campus.loadPerson(mockTeacher, erika))!;
      expect(p.upcoming, isNotNull); // Only me for students
      expect((await campus.loadPerson(mockTeacher, diego))!.history, isNotNull);
      expect((await campus.loadPerson(mockTeacher, celine))!.connections, isNotNull);
      expect(p.person.status, ConnectionStatus.none); // teachers don't connect
    });

    test('a student sees all of their own profile', () async {
      final p = (await campus.loadPerson(me, me.id))!;
      expect(p.history, isNotNull);
      expect(p.upcoming, isNotNull);
      expect(p.connections!.length, 4);
    });

    test('members-only events stay hidden from those who cannot see them', () async {
      // Andrea's upcoming events are Public; ev1 is for CSS members only.
      final ids = (await campus.loadPerson(asStudent(celine, 'Celine', 'Yap'), andrea))!
          .upcoming!
          .map((e) => e.id);
      expect(ids, isNot(contains('ev1')));
      expect((await campus.loadPerson(me, andrea))!.upcoming!.map((e) => e.id), contains('ev1'));
    });
  });

  group('connecting', () {
    test('Nicolas starts with 4 connections, 2 to answer, 1 sent', () async {
      final c = await campus.loadConnections(me);
      expect(c.connections.length, 4);
      expect(c.incoming.map((p) => p.id), [aira, bea]); // oldest first
      expect(c.sent.single.id, alyssa);
    });

    test('send, then the other accepts: connected, and the sender is told', () async {
      await campus.sendConnectRequest(me, celine);
      expect((await campus.loadPerson(me, celine))!.person.status, ConnectionStatus.requestSent);
      final celineUser = asStudent(celine, 'Celine', 'Yap');
      expect((await campus.loadConnectNotices(celineUser)).single.title,
          'Nicolas Santos wants to connect.');

      await campus.answerConnectRequest(celineUser, me.id, accept: true);
      expect((await campus.loadPerson(me, celine))!.person.status, ConnectionStatus.connected);
      expect((await campus.loadConnectNotices(me)).map((n) => n.title),
          contains('Celine Yap accepted your request to connect.'));
      await expectLater(
          campus.answerConnectRequest(celineUser, me.id, accept: true), throwsStateError);
    });

    test('declining is silent and the request is gone', () async {
      await campus.answerConnectRequest(me, aira, accept: false);
      expect((await campus.loadConnections(me)).incoming.map((p) => p.id), [bea]);
      expect((await campus.loadConnectNotices(asStudent(aira, 'Aira', 'Domingo'))), isEmpty);
    });

    test('asking someone who already asked you connects right away', () async {
      await campus.sendConnectRequest(me, bea);
      expect((await campus.loadPerson(me, bea))!.person.status, ConnectionStatus.connected);
    });

    test('cancel a sent request; remove a connection', () async {
      await campus.cancelConnectRequest(me, alyssa);
      expect((await campus.loadConnections(me)).sent, isEmpty);
      await campus.removeConnection(me, carlo);
      expect((await campus.loadPerson(me, carlo))!.person.status, ConnectionStatus.none);
      expect((await campus.loadPerson(me, carlo))!.history, isNull); // no longer a connection
      await expectLater(campus.removeConnection(me, carlo), throwsStateError);
    });

    test('invalid requests are refused', () async {
      for (final act in <Future<void> Function()>[
        () => campus.sendConnectRequest(me, me.id), // yourself
        () => campus.sendConnectRequest(me, andrea), // already connected
        () => campus.sendConnectRequest(me, alyssa), // already sent
        () => campus.sendConnectRequest(mockTeacher, andrea), // teachers don't connect
        () => campus.sendConnectRequest(me, 'nobody'),
        () => campus.cancelConnectRequest(me, celine),
      ]) {
        await expectLater(act(), throwsStateError);
      }
    });
  });

  group('blocking', () {
    test('blocking removes the connection and hides each from the other', () async {
      await campus.blockStudent(me, andrea);
      final mine = (await campus.loadPerson(me, andrea))!;
      expect(mine.person.status, ConnectionStatus.blocked);
      expect(mine.limited, isTrue);
      expect(mine.tags, isEmpty);

      final andreaUser = asStudent(andrea, 'Andrea', 'Bautista');
      expect((await campus.loadPerson(andreaUser, me.id))!.limited, isTrue);
      expect((await campus.searchPeople(andreaUser, 'Nicolas')), isEmpty);
      expect((await campus.searchPeople(me, 'Andrea')), isEmpty);
      await expectLater(campus.sendConnectRequest(andreaUser, me.id), throwsStateError);
      expect((await campus.loadBlocked(me)).single.id, andrea);
      // Teachers still see both normally.
      expect((await campus.loadPerson(mockTeacher, me.id))!.limited, isFalse);
    });

    test('blocking clears requests both ways; unblocking restores visibility', () async {
      await campus.blockStudent(me, bea);
      expect((await campus.loadConnections(me)).incoming.map((p) => p.id), [aira]);
      await campus.unblockStudent(me, bea);
      final p = (await campus.loadPerson(me, bea))!;
      expect(p.limited, isFalse);
      expect(p.person.status, ConnectionStatus.none); // the request is gone
      await expectLater(campus.unblockStudent(me, bea), throwsStateError);
    });
  });

  group('finding people', () {
    test('search by name leaves out yourself', () async {
      expect((await campus.searchPeople(me, 'mendoza')).single.name, 'Carlo Mendoza');
      expect((await campus.searchPeople(me, 'Nicolas')), isEmpty);
      expect((await campus.searchPeople(mockTeacher, 'Nicolas')).single.id, me.id);
    });

    test('suggestions: not connected, not pending, best match first', () async {
      final s = await campus.loadSuggestions(me);
      expect(s, isNotEmpty);
      expect(s.length, lessThanOrEqualTo(6));
      expect(s.every((p) => p.status == ConnectionStatus.none), isTrue);
      expect(s.map((p) => p.id), isNot(contains(andrea)));
      expect(await campus.loadSuggestions(mockTeacher), isEmpty);
    });
  });

  test('privacy settings: defaults, saving, and the effect', () async {
    expect((await campus.loadPrivacy(me)).eventHistory, PrivacyLevel.connections);
    final carloUser = asStudent(carlo, 'Carlo', 'Mendoza');
    expect((await campus.loadPerson(carloUser, me.id))!.history, isNotNull);
    await campus.savePrivacy(me, const PrivacySettings(eventHistory: PrivacyLevel.onlyMe));
    expect((await campus.loadPerson(carloUser, me.id))!.history, isNull);
    await expectLater(campus.savePrivacy(mockTeacher, const PrivacySettings()), throwsStateError);
  });

  test("event totals didn't change when sample people registered by name", () async {
    // ev3 (opening ceremony): 235 anonymous + Nicolas + 5 sample people.
    final ev3 = (await campus.loadEvent(me, 'ev3'))!;
    expect(ev3.going, 241);
  });

  test('requests show in the bell as Connections notices', () async {
    final home = MockHomeService(delay: Duration.zero, campus: campus);
    final bell = await home.loadNotifications(me);
    final connect = bell.where((n) => n.kind == NotificationKind.connection).map((n) => n.title);
    expect(connect, containsAll(['Bea Villareal wants to connect.', 'Aira Domingo wants to connect.']));
  });

  group('Going and Went lists', () {
    test('names who the viewer may see, connections first; counts the rest', () async {
      final a = (await campus.loadEventAttendees(me, 'ev3'))!; // opening ceremony
      expect(a.past, isFalse);
      // Carlo and Diego are connections; Alyssa and Bea set upcoming events
      // to Public; Aira (Connections) isn't Nicolas's connection.
      expect(a.shown.map((p) => p.name),
          ['Carlo Mendoza', 'Diego Ramos', 'Alyssa Go', 'Bea Villareal']);
      expect(a.includesViewer, isTrue);
      expect(a.total, 241);
      expect(a.others, 236); // 235 unnamed sample registrations + Aira
    });

    test('Only me hides someone even from connections; teachers see all', () async {
      final mine = (await campus.loadEventAttendees(me, 'ev1'))!.shown.map((p) => p.name);
      expect(mine, ['Andrea Bautista', 'Carlo Mendoza']); // Erika: Only me
      // Teachers see everyone named (ev1 is members-only, so use the ceremony).
      expect((await campus.loadEventAttendees(mockTeacher, 'ev3'))!.shown.length, 6);
    });

    test('after the event it is Went, from attendance records', () async {
      final a = (await campus.loadEventAttendees(me, 'past-git'))!;
      expect(a.past, isTrue);
      expect(a.shown.map((p) => p.name), ['Andrea Bautista', 'Carlo Mendoza', 'Erika Lim']);
      expect(a.includesViewer, isTrue);
      expect(a.total, 4); // students only; registration isn't attendance
    });

    test('blocked students are counted, never named', () async {
      await campus.blockStudent(me, 'stu-BSCS3A1');
      final a = (await campus.loadEventAttendees(me, 'ev1'))!;
      expect(a.shown.map((p) => p.name), ['Carlo Mendoza']);
    });

    test('the summary line reads naturally', () {
      PersonSummary p(String name) => PersonSummary(id: name, name: name, section: '');
      expect(
          goingLine(EventAttendees(
              past: false, shown: [p('Andrea B'), p('Carlo M')], includesViewer: false, total: 16)),
          'Andrea, Carlo and 14 others are going');
      expect(
          goingLine(EventAttendees(
              past: false, shown: [p('Andrea B')], includesViewer: true, total: 241)),
          'You, Andrea and 239 others are going');
      expect(
          goingLine(const EventAttendees(past: false, shown: [], includesViewer: false, total: 60)),
          '60 going');
      expect(goingLine(EventAttendees(past: false, shown: [p('Bea V')], includesViewer: false, total: 1)),
          'Bea is going');
      expect(
          goingLine(EventAttendees(
              past: true, shown: [p('Andrea B'), p('Carlo M')], includesViewer: false, total: 2)),
          'Andrea and Carlo went');
      expect(goingLine(const EventAttendees(past: true, shown: [], includesViewer: false, total: 0)),
          'No recorded attendance yet.');
    });
  });
}
