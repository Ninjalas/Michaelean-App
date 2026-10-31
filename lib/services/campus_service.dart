import '../mock/mock_campus.dart';
import '../mock/mock_classes.dart';
import '../mock/mock_grades.dart';
import '../mock/mock_home.dart' show mockPosts;
import '../mock/mock_people.dart';
import '../mock/mock_users.dart' show mockEventHistory, mockStudent, mockTeacher;
import '../models/attendance.dart';
import '../models/campus.dart';
import '../models/consultation.dart';
import '../models/event_record.dart';
import '../models/feed.dart';
import '../models/grades.dart';
import '../models/people.dart';
import '../models/user_profile.dart';

/// Where class, event, organization, and clearance data comes from (spec §7,
/// §9). Screens use this, not mock data directly.
abstract class CampusService {
  /// The user's class sessions from the start of today through the next
  /// week, earliest first (today's ended ones included).
  Future<List<ClassSession>> loadClasses(UserProfile user);

  /// The user's class sessions starting in [from, to), earliest first.
  Future<List<ClassSession>> loadSchedule(UserProfile user, DateTime from, DateTime to);

  /// Classes on the timetable that the teacher is assigned to.
  Future<List<ClassInfo>> loadAssignedClasses(UserProfile teacher);

  /// A class page for its assigned teacher; null if not theirs to manage.
  Future<ClassDetail?> loadClassDetail(UserProfile teacher, String classId);

  /// The current semester's first and last day (Mon–Sat class days).
  Future<({String name, DateTime start, DateTime end})> loadSemester(UserProfile user);

  /// The student's own grades by semester, newest (current) first (spec
  /// §7.6). Empty for teachers, who don't see grades yet.
  Future<List<SemesterGrades>> loadGrades(UserProfile student);

  /// The student's finalized attendance records this semester, newest first
  /// (spec §7.2).
  Future<List<AttendanceRecord>> loadMyAttendance(UserProfile student);

  /// One session's roster and scans; null if not the teacher's to manage.
  Future<SessionAttendance?> loadSessionAttendance(UserProfile teacher, String sessionId);

  /// Applies the attendance rules to one scanned code (spec §7.2).
  /// [ignoreClock] is a preview tool for demoing outside class hours.
  Future<ScanResult> recordScan(UserProfile teacher, String sessionId, String qrToken,
      {bool ignoreClock = false});

  /// Closes the session: scanned students Present, everyone else Absent.
  Future<void> finalizeSession(UserProfile teacher, String sessionId);

  /// Changes one session's time or room (single session only: open
  /// decisions 1 and 3 are undecided, so recurring changes aren't offered).
  Future<ClassSession> updateSession(UserProfile teacher, String sessionId,
      {required DateTime start, required DateTime end, required String room, String? reason});

  /// Published events the user is eligible for, soonest first.
  Future<List<CampusEvent>> loadUpcomingEvents(UserProfile user);

  /// Upcoming events the user is allowed to manage, including drafts.
  Future<List<CampusEvent>> loadManagedEvents(UserProfile user);

  /// One of the events lists (spec §7.3, §9.2), with the user's
  /// registration on each. Upcoming events soonest first, then past ones
  /// newest first.
  Future<List<EventDetail>> loadEvents(UserProfile user, EventList list);

  /// One event; null if the user may not see it.
  Future<EventDetail?> loadEvent(UserProfile user, String eventId);

  /// Registers the student. Throws [StateError] with a reason when the
  /// event is full, closed, ineligible, or already registered.
  Future<void> register(UserProfile student, String eventId);

  Future<void> cancelRegistration(UserProfile student, String eventId);

  /// Creates ([eventId] null) or edits an event the user manages. Editing
  /// changes the same event, never a copy. A published event stays published.
  Future<CampusEvent> saveEvent(
    UserProfile user, {
    String? eventId,
    required bool publish,
    required String title,
    required DateTime start,
    required DateTime end,
    required String venue,
    String? audience,
    DateTime? deadline,
    int? capacity,
    String description,
    String? coverAsset,
    String? hostOrgId, // a new event hosted by a club the user advises
  });

  Future<void> cancelEvent(UserProfile user, String eventId);

  /// Registered students, for the event's managers; null for anyone else.
  Future<List<EventRegistrant>?> loadRegistrations(UserProfile user, String eventId);

  /// What the event's managers can pick on the Invite page; null for anyone else.
  Future<InviteOptions?> loadInviteOptions(UserProfile user, String eventId);

  /// Invites whole sections, whole clubs, and single students at once
  /// (decided 2026-10-30). Invited students are registered automatically
  /// (spec §7.3) and get a bell notice in this preview. Only eligible
  /// students; nobody if the spots left don't cover everyone. Returns how
  /// many students were newly registered.
  Future<int> invite(UserProfile user, String eventId,
      {List<String> sections, List<String> orgIds, List<String> studentIds});

  /// The user's official event records, newest first (Profile's Event
  /// History). Registration alone never appears here.
  Future<List<EventRecord>> loadEventHistory(UserProfile user);

  /// Event check-in for its managers; null for anyone else.
  Future<EventCheckIn?> loadEventCheckIn(UserProfile user, String eventId);

  /// One scanned code at event check-in. Only registered students are
  /// marked; a repeat counts once. [ignoreClock] is a preview tool.
  Future<ScanResult> recordEventScan(UserProfile user, String eventId, String qrToken,
      {bool ignoreClock = false});

  /// Closes check-in: every scanned student gets an Attended record in their
  /// Event History. Returns how many records were added.
  Future<int> finalizeEventAttendance(UserProfile user, String eventId);

  /// Organizations the user is a confirmed member of.
  Future<List<Organization>> loadMyOrganizations(UserProfile user);

  /// The Organizations directory (spec §7.4): the user's departmental
  /// society, school-wide clubs, and confirmed memberships.
  Future<OrgDirectory> loadOrganizationDirectory(UserProfile user);

  /// One organization page; null if the user may not see it (another
  /// department's society they don't belong to).
  Future<OrganizationPage?> loadOrganization(UserProfile user, String orgId);

  /// Records a request to join in this preview. It never makes the user a
  /// member: the club's adviser answers it (decided 2026-10-23).
  Future<void> requestToJoin(UserProfile user, String orgId);

  // Club advisers (decided 2026-10-23) and officers (2026-10-31): a teacher
  // assigned as a club's adviser, or a student with an officer position in
  // it, manages its members, officers, info, posts, and events; officers
  // what mockOfficerPowers allows. Each method below refuses anyone else.
  // Changes stay in this preview; notices appear only in this preview's bell.

  /// Clubs the user may manage (with [power], only where they have it), with
  /// how many students are waiting.
  Future<List<AdvisedClub>> loadAdvisedClubs(UserProfile user, {ClubPower? power});

  /// The Manage club page; null when the user can't manage this club.
  Future<ClubAdmin?> loadClubAdmin(UserProfile user, String orgId);

  /// Accepts or declines a request to join; [reason] goes to the student.
  Future<void> answerJoinRequest(UserProfile adviser, String orgId, String studentId,
      {required bool accept, String? reason});

  Future<void> addMember(UserProfile adviser, String orgId, String studentId);

  Future<void> removeMember(UserProfile adviser, String orgId, String studentId,
      {String? reason});

  /// Gives a member an officer position, or none ([position] null).
  Future<void> setOfficerPosition(
      UserProfile adviser, String orgId, String studentId, String? position);

  Future<void> updateClubInfo(UserProfile adviser, String orgId,
      {required String about, required List<OrgMeeting> meetings});

  /// Students who could be added: not members, not waiting; matched by name.
  Future<List<OrgMember>> searchStudents(UserProfile adviser, String orgId, String query);

  /// Membership news for the user's bell (accepted, declined, added, removed).
  Future<List<AppNotification>> loadMembershipNotices(UserProfile user);

  // Connect (spec §10.1): students connect with students by request and
  // acceptance. What a viewer may see of another student follows that
  // student's privacy settings; every teacher sees everything. Changes stay
  // in this preview; notices appear only in this preview's bell.

  /// Another student's profile as [viewer] may see it; null if there's no
  /// such student.
  Future<PersonProfile?> loadPerson(UserProfile viewer, String personId);

  /// The user's requests to answer, connections, and sent requests.
  Future<ConnectionsOverview> loadConnections(UserProfile user);

  /// Students whose name matches; blocked ones (either way) are left out.
  Future<List<PersonSummary>> searchPeople(UserProfile viewer, String query);

  /// "People you may know" for a student: mutual connections, the same
  /// section, shared clubs. Empty for teachers.
  Future<List<PersonSummary>> loadSuggestions(UserProfile viewer);

  /// Sends a request; if they already asked, it connects right away.
  Future<void> sendConnectRequest(UserProfile viewer, String personId);

  Future<void> cancelConnectRequest(UserProfile viewer, String personId);

  /// Declining is silent; accepting tells the sender.
  Future<void> answerConnectRequest(UserProfile viewer, String fromId, {required bool accept});

  /// Ends a connection silently.
  Future<void> removeConnection(UserProfile viewer, String personId);

  /// Hides each from the other and removes any connection or request.
  Future<void> blockStudent(UserProfile viewer, String personId);

  Future<void> unblockStudent(UserProfile viewer, String personId);

  Future<List<PersonSummary>> loadBlocked(UserProfile user);

  Future<PrivacySettings> loadPrivacy(UserProfile user);

  Future<void> savePrivacy(UserProfile user, PrivacySettings settings);

  /// Connect news for the user's bell: requests waiting, requests accepted.
  Future<List<AppNotification>> loadConnectNotices(UserProfile user);

  /// Who is going (or went, after it ends) to an event the viewer can see;
  /// null if they can't see it. Names follow each person's privacy setting.
  Future<EventAttendees?> loadEventAttendees(UserProfile viewer, String eventId);

  /// [user] with tags matching what they're associated with now: club
  /// memberships and officer positions from the member lists, and assigned
  /// roles (club adviser, clearance office). Applied each time a preview
  /// account loads, so changes show up the next time.
  UserProfile withAffiliations(UserProfile user);

  /// The active clearance period's progress; null when there is none.
  Future<ClearanceSummary?> loadClearance(UserProfile user);

  /// The student's Clearance screen (spec §7.5): the active period, if any,
  /// and past clearances.
  Future<ClearanceView> loadClearanceView(UserProfile user);

  /// The student says they did a requirement: it goes In review. It never
  /// clears anything; staff decide.
  Future<void> markSubmitted(UserProfile student, String itemId);

  /// The clearance office the user processes; null when not assigned.
  Future<ClearanceOffice?> loadClearanceOffice(UserProfile user);

  /// Offices to contact for help (Help & Support).
  Future<List<SupportContact>> loadSupportContacts();

  /// The staff verification desk (spec §9.3); null without permission or
  /// outside an active period.
  Future<ClearanceDesk?> loadClearanceDesk(UserProfile user);

  /// Finds the student for a scanned code; null when unknown. Scanning only
  /// identifies the student; it never approves anything.
  Future<String?> findStudentByQr(UserProfile user, String qrToken);

  /// One student's requirements for the staff member's office; null if
  /// unavailable.
  Future<ClearanceCase?> loadClearanceCase(UserProfile user, String studentId);

  /// Records Cleared, Needs Correction, or On Hold on one requirement of the
  /// staff member's office. A reason is required unless Cleared.
  Future<void> recordOutcome(UserProfile user, String studentId, String itemId,
      ClearanceStatus outcome, {String? reason});

  // ---------- Consultations (decided 2026-10-30) ----------

  /// The user's e-signature (an uploaded photo's path), or null.
  Future<String?> loadSignature(UserProfile user);

  /// Saves the user's e-signature, or removes it with null. Preview only.
  Future<void> saveSignature(UserProfile user, String? photo);

  /// Any sample student whose name contains [query], for a consultation.
  Future<List<OrgMember>> findStudents(UserProfile teacher, String query);

  /// The user's consultations, newest first: a teacher's own, or a student's.
  /// Nobody else sees them.
  Future<List<Consultation>> loadConsultations(UserProfile user);

  /// One consultation, if [user] is its teacher or its student.
  Future<Consultation?> loadConsultation(UserProfile user, String id);

  /// Saves a new consultation with [studentId], or edits [id] (the teacher's
  /// own; anytime). A new one needs the teacher's e-signature, and keeps it
  /// for good. [scanned]: the student showed their QR just now, which adds
  /// their e-signature if they have one. Needs [Permission.holdConsultations].
  Future<Consultation> saveConsultation(
    UserProfile teacher, {
    String? id,
    required String studentId,
    required String department,
    required String venue,
    required List<ConsultationRow> rows,
    required String expectedOutcome,
    bool scanned = false,
  });

  /// The student showed their QR after the form was saved: adds their
  /// e-signature, which they must have on file. MOCK scan: [scannedStudentId] must be the consultation's
  /// student; nothing verifies identity.
  Future<Consultation> signConsultation(UserProfile teacher, String id, String scannedStudentId);
}

class MockCampusService implements CampusService {
  final Duration delay; // pretend network time, so loading states show
  final bool fail; // tests use this to check the error state
  final DateTime Function() clock;

  MockCampusService({
    this.delay = const Duration(milliseconds: 500),
    this.fail = false,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  Future<void> _wait() async {
    await Future.delayed(delay);
    if (fail) throw Exception('Mock load failure');
  }

  // ---------- Classes and attendance (in memory, this preview only) ----------

  final _present = <String, Set<String>>{}; // session id → scanned student ids
  final _finalized = <String>{};
  final _overrides = <String, ({DateTime start, DateTime end, String room, String? reason})>{};

  DateTime get _today {
    final now = clock();
    return DateTime(now.year, now.month, now.day);
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<ClassInfo> _classesOf(UserProfile user) => user.role == UserRole.student
      ? mockTimetable.where((c) => c.section == mockStudentSection[user.id]).toList()
      : mockTimetable.where((c) => c.teacherId == user.id).toList();

  /// Scanned students for a session. The first time a session is looked at,
  /// past days are filled in as finalized and today's CS 301 as scanned.
  Set<String> _presentFor(ClassInfo c, String id, DateTime start) {
    final known = _present[id];
    if (known != null) return known;
    final roster = mockRosters[c.section] ?? const [];
    final now = clock();
    Set<String> seeded = {};
    if (start.isBefore(_today)) {
      seeded = {for (final s in roster) if (!mockWasAbsent(id, s.id)) s.id};
      _finalized.add(id);
    } else if (c.id == mockSeededOpenClassId && now.isAfter(start)) {
      seeded = roster.take(mockSeededScanCount).map((s) => s.id).toSet();
    }
    return _present[id] = seeded;
  }

  ClassSession _session(ClassInfo c, DateTime day, {required bool forStudent}) {
    final id = '${c.id}@${_ymd(day)}';
    final o = _overrides[id];
    final start = o?.start ?? day.add(Duration(minutes: c.startMinute));
    final end = o?.end ?? day.add(Duration(minutes: c.endMinute));
    final present = _presentFor(c, id, start);
    final finalized = _finalized.contains(id);
    return ClassSession(
      id: id,
      classId: c.id,
      subject: c.subject,
      section: c.section,
      start: start,
      end: end,
      room: o?.room ?? c.room,
      teacher: forStudent ? c.teacherName : null,
      // Scanned, ended, not closed yet: a real task (spec §8).
      awaitingFinalization: !finalized && present.isNotEmpty && !end.isAfter(clock()),
      finalized: finalized,
    );
  }

  List<ClassSession> _sessions(List<ClassInfo> classes, DateTime from, DateTime to,
      {required bool forStudent}) {
    final out = <ClassSession>[];
    for (var day = DateTime(from.year, from.month, from.day);
        day.isBefore(to);
        day = DateTime(day.year, day.month, day.day + 1)) {
      for (final c in classes) {
        if (!c.weekdays.contains(day.weekday)) continue;
        final s = _session(c, day, forStudent: forStudent);
        if (!s.start.isBefore(from) && s.start.isBefore(to)) out.add(s);
      }
    }
    return out..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Finds a teacher's session by id; null if it isn't theirs to manage.
  (ClassInfo, ClassSession)? _managed(UserProfile teacher, String sessionId) {
    if (!teacher.can(Permission.manageAssignedClasses)) return null;
    final at = sessionId.lastIndexOf('@');
    if (at < 0) return null;
    final classId = sessionId.substring(0, at);
    final day = DateTime.tryParse(sessionId.substring(at + 1));
    final c = _classesOf(teacher).where((c) => c.id == classId).firstOrNull;
    if (c == null || day == null || !c.weekdays.contains(day.weekday)) return null;
    return (c, _session(c, day, forStudent: false));
  }

  @override
  Future<List<ClassSession>> loadClasses(UserProfile user) async {
    await _wait();
    return _sessions(_classesOf(user), _today, _today.add(const Duration(days: 8)),
        forStudent: user.role == UserRole.student);
  }

  @override
  Future<List<ClassSession>> loadSchedule(UserProfile user, DateTime from, DateTime to) async {
    await _wait();
    return _sessions(_classesOf(user), from, to, forStudent: user.role == UserRole.student);
  }

  @override
  Future<List<ClassInfo>> loadAssignedClasses(UserProfile teacher) async {
    await _wait();
    return teacher.role == UserRole.teacher ? _classesOf(teacher) : const [];
  }

  @override
  Future<ClassDetail?> loadClassDetail(UserProfile teacher, String classId) async {
    await _wait();
    if (!teacher.can(Permission.manageAssignedClasses)) return null;
    final c = _classesOf(teacher).where((c) => c.id == classId).firstOrNull;
    if (c == null) return null;
    final now = clock();
    final sessions = _sessions([c], _today.subtract(const Duration(days: 21)),
        _today.add(const Duration(days: 8)), forStudent: false);
    final roster = mockRosters[c.section] ?? const [];
    final current = sessions.where((s) => _sameDay(s.start, now)).firstOrNull ??
        sessions.where((s) => s.start.isAfter(now)).firstOrNull;
    final recent = sessions.where((s) => !s.end.isAfter(now)).toList().reversed.take(6);
    return ClassDetail(
      info: c,
      roster: roster,
      current: current,
      recent: [
        for (final s in recent)
          SessionSummary(session: s, present: _present[s.id]!.length, total: roster.length),
      ],
    );
  }

  @override
  Future<({String name, DateTime start, DateTime end})> loadSemester(UserProfile user) async {
    await _wait();
    return mockSemester(clock());
  }

  @override
  Future<List<AttendanceRecord>> loadMyAttendance(UserProfile student) async {
    await _wait();
    final sessions = _sessions(_classesOf(student), mockSemester(clock()).start, clock(),
        forStudent: true);
    return [
      for (final s in sessions.reversed)
        if (s.finalized) // unfinished sessions never count (spec §7.2)
          AttendanceRecord(
            session: s,
            mark: _present[s.id]!.contains(student.id)
                ? AttendanceMark.present
                : AttendanceMark.absent,
          ),
    ];
  }

  @override
  Future<SessionAttendance?> loadSessionAttendance(UserProfile teacher, String sessionId) async {
    await _wait();
    final found = _managed(teacher, sessionId);
    if (found == null) return null;
    final (c, s) = found;
    return SessionAttendance(
      session: s,
      roster: mockRosters[c.section] ?? const [],
      presentIds: Set.of(_present[s.id]!),
    );
  }

  @override
  Future<ScanResult> recordScan(UserProfile teacher, String sessionId, String qrToken,
      {bool ignoreClock = false}) async {
    await _wait();
    final found = _managed(teacher, sessionId);
    if (found == null) throw StateError("You can't take attendance for this class.");
    final (c, s) = found;
    final now = clock();
    if (s.finalized) return const ScanResult(ScanOutcome.closed);
    if (!ignoreClock && now.isBefore(s.start)) return const ScanResult(ScanOutcome.notOpenYet);
    if (!ignoreClock && !now.isBefore(s.end)) return const ScanResult(ScanOutcome.closed);
    final student = (mockRosters[c.section] ?? const <RosterStudent>[])
        .where((r) => r.qrToken == qrToken)
        .firstOrNull;
    if (student == null) return const ScanResult(ScanOutcome.notEnrolled);
    // A Set ignores repeats: a second scan never counts twice.
    final added = _present[s.id]!.add(student.id);
    return ScanResult(added ? ScanOutcome.present : ScanOutcome.duplicate, student);
  }

  @override
  Future<void> finalizeSession(UserProfile teacher, String sessionId) async {
    await _wait();
    if (_managed(teacher, sessionId) == null) {
      throw StateError("You can't finalize attendance for this class.");
    }
    _finalized.add(sessionId);
  }

  @override
  Future<ClassSession> updateSession(UserProfile teacher, String sessionId,
      {required DateTime start, required DateTime end, required String room, String? reason}) async {
    await _wait();
    final found = _managed(teacher, sessionId);
    if (found == null) throw StateError("You can't edit this class.");
    if (!end.isAfter(start)) throw ArgumentError('The class must end after it starts.');
    if (room.trim().isEmpty) throw ArgumentError('Enter a room.');
    final (c, s) = found;
    _overrides[sessionId] = (start: start, end: end, room: room.trim(), reason: reason);
    return _session(c, DateTime(s.start.year, s.start.month, s.start.day), forStudent: false);
  }

  // ---------- Events (in memory, this preview only) ----------

  late final _events = {for (final e in mockEvents(clock())) e.id: e};
  final _registered = {
    for (final e in {...mockRegistrations().keys, ...mockPeopleRegistrations.keys})
      e: {...?mockRegistrations()[e], ...?mockPeopleRegistrations[e]},
  };
  final _invited = <String, Set<String>>{}; // event id → invited student ids
  final _history = {
    for (final e in {...mockEventHistory, ...mockPeopleHistory}.entries) e.key: [...e.value],
  };
  final _eventPresent = <String, Set<String>>{}; // event id → scanned student ids
  final _eventFinalized = {...mockFinalizedEvents};

  EventRecord? _recordOf(String userId, String eventId) =>
      _history[userId]?.where((r) => r.eventId == eventId).firstOrNull;

  int _attendedCount(String eventId) =>
      _history.values.expand((list) => list).where((r) => r.eventId == eventId).length;
  var _newEvents = 0;

  bool _eligible(UserProfile user, CampusEvent e) =>
      e.audience == null ||
      user.tags.any((t) => t.label == e.audience) ||
      // A club's adviser counts as a member for its members-only events
      // (decided 2026-10-24); advising isn't membership otherwise.
      mockOrganizations.any((o) => o.name == e.audience && o.adviserIds.contains(user.id));

  bool _manages(UserProfile user, CampusEvent e) =>
      (user.can(Permission.manageEvents) && e.managerIds.contains(user.id)) ||
      // A club event made in this app is managed by the club's adviser and
      // officers (decided 2026-10-31).
      (e.clubId != null && _advisedOrNull(user, e.clubId!, ClubPower.events) != null);

  int _going(CampusEvent e) =>
      (mockOtherRegistrations[e.id] ?? 0) + (_registered[e.id]?.length ?? 0);

  EventDetail _detail(UserProfile user, CampusEvent e) {
    final registered = _registered[e.id]?.contains(user.id) ?? false;
    final now = clock();
    final going = _going(e);
    String? closed;
    if (e.status == EventStatus.cancelled) {
      closed = 'This event was cancelled.';
    } else if (e.status == EventStatus.draft) {
      closed = "This event isn't published yet.";
    } else if (!e.start.isAfter(now)) {
      closed = e.end.isAfter(now) ? 'This event has started.' : 'This event has ended.';
    } else if (!registered) {
      if (user.role != UserRole.student) {
        closed = 'Only students register for events.';
      } else if (!_eligible(user, e)) {
        closed = "You aren't eligible for this event.";
      } else if (e.deadline != null && !e.deadline!.isAfter(now)) {
        closed = 'Registration closed.';
      } else if (e.capacity != null && going >= e.capacity!) {
        closed = 'This event is full.';
      }
    }
    return EventDetail(
      event: e,
      registered: registered,
      invited: _invited[e.id]?.contains(user.id) ?? false,
      going: going,
      canManage: _manages(user, e),
      closedReason: closed,
      record: _recordOf(user.id, e.id),
      attendanceFinalized: _eventFinalized.contains(e.id),
      attendedCount: _attendedCount(e.id),
    );
  }

  @override
  Future<List<CampusEvent>> loadUpcomingEvents(UserProfile user) async {
    await _wait();
    final now = clock();
    return _events.values
        .where((e) =>
            e.status == EventStatus.published && e.start.isAfter(now) && _eligible(user, e))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<List<CampusEvent>> loadManagedEvents(UserProfile user) async {
    await _wait();
    final now = clock();
    return _events.values
        .where((e) =>
            _manages(user, e) && e.status != EventStatus.cancelled && e.start.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<List<EventDetail>> loadEvents(UserProfile user, EventList list) async {
    await _wait();
    final now = clock();
    final events = _events.values.where((e) => switch (list) {
          EventList.discover =>
            e.status == EventStatus.published && e.start.isAfter(now) && _eligible(user, e),
          // Kept even if the student left the organization (spec §7.3).
          EventList.mine => e.status != EventStatus.draft &&
              ((_registered[e.id]?.contains(user.id) ?? false) ||
                  _recordOf(user.id, e.id) != null),
          EventList.managed => _manages(user, e),
        });
    final upcoming = events.where((e) => e.end.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final past = events.where((e) => !e.end.isAfter(now)).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    return [for (final e in [...upcoming, ...past]) _detail(user, e)];
  }

  @override
  Future<EventDetail?> loadEvent(UserProfile user, String eventId) async {
    await _wait();
    final e = _events[eventId];
    if (e == null) return null;
    final registered = _registered[e.id]?.contains(user.id) ?? false;
    final visible = _manages(user, e) ||
        _recordOf(user.id, e.id) != null ||
        (e.status != EventStatus.draft && (registered || _eligible(user, e)));
    return visible ? _detail(user, e) : null;
  }

  @override
  Future<void> register(UserProfile student, String eventId) async {
    await _wait();
    final e = _events[eventId];
    if (e == null) throw StateError('This event no longer exists.');
    final d = _detail(student, e);
    if (d.registered) throw StateError("You're already registered.");
    if (d.closedReason != null) throw StateError(d.closedReason!);
    _registered.putIfAbsent(eventId, () => {}).add(student.id);
  }

  @override
  Future<void> cancelRegistration(UserProfile student, String eventId) async {
    await _wait();
    final e = _events[eventId];
    if (e == null || !e.start.isAfter(clock())) {
      throw StateError("This registration can't be cancelled.");
    }
    _registered[eventId]?.remove(student.id);
    _invited[eventId]?.remove(student.id);
  }

  @override
  Future<CampusEvent> saveEvent(
    UserProfile user, {
    String? eventId,
    required bool publish,
    required String title,
    required DateTime start,
    required DateTime end,
    required String venue,
    String? audience,
    DateTime? deadline,
    int? capacity,
    String description = '',
    String? coverAsset,
    String? hostOrgId,
  }) async {
    await _wait();
    final club = hostOrgId == null ? null : _advised(user, hostOrgId, ClubPower.events);
    final old = eventId == null ? null : _events[eventId];
    // A new event needs the events permission, or a club the user manages.
    if (old == null && club == null && !user.can(Permission.manageEvents)) {
      throw StateError("You can't manage events.");
    }
    if (eventId != null && (old == null || !_manages(user, old))) {
      throw StateError("You can't edit this event.");
    }
    if (old?.status == EventStatus.cancelled) throw StateError('This event was cancelled.');
    final problem = eventFormProblem(
      title: title,
      venue: venue,
      start: start,
      end: end,
      deadline: deadline,
      capacity: capacity,
      registered: _registered[eventId]?.length ?? 0,
      publishing: old?.status == EventStatus.published || publish,
      now: clock(),
    );
    if (problem != null) throw ArgumentError(problem);
    final published = old?.status == EventStatus.published || publish;
    final moved = old != null &&
        old.status == EventStatus.published &&
        (old.start != start || old.end != end || old.venue != venue.trim());
    final id = old?.id ?? 'new-${++_newEvents}';
    // Mock assumption: an event a teacher creates is hosted by their department.
    // A club event is hosted by the club.
    final host = old?.host ??
        club?.name ??
        user.tags.where((t) => t.kind == TagKind.department).firstOrNull?.label ??
        user.fullName;
    return _events[id] = CampusEvent(
      id: id,
      title: title.trim(),
      host: host,
      hostLogo: old?.hostLogo ?? club?.logoAsset,
      start: start,
      end: end,
      venue: venue.trim(),
      coverAsset: coverAsset,
      status: published ? EventStatus.published : EventStatus.draft,
      description: description.trim(),
      deadline: deadline,
      capacity: capacity,
      updateNote: moved ? 'The time or venue changed.' : old?.updateNote,
      audience: audience,
      managerIds: old?.managerIds ?? {user.id},
      postedAt: old?.postedAt ?? (published ? clock() : null),
      clubId: old?.clubId ?? club?.id,
    );
  }

  @override
  Future<void> cancelEvent(UserProfile user, String eventId) async {
    await _wait();
    final e = _events[eventId];
    if (e == null || !_manages(user, e)) throw StateError("You can't cancel this event.");
    _events[eventId] = e.copyWith(status: EventStatus.cancelled);
  }

  RosterStudent? _rosterStudent(String id) {
    for (final roster in mockRosters.values) {
      for (final s in roster) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  @override
  Future<List<EventRegistrant>?> loadRegistrations(UserProfile user, String eventId) async {
    await _wait();
    final e = _events[eventId];
    if (e == null || !_manages(user, e)) return null;
    final invited = _invited[eventId] ?? const <String>{};
    return [
      for (final id in _registered[eventId] ?? const <String>{})
        if (_rosterStudent(id) case final s?)
          EventRegistrant(
            id: s.id,
            name: s.name,
            maskedId: s.maskedId,
            photoAsset: s.photoAsset,
            invited: invited.contains(id),
          ),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  /// The event, if [user] may invite to it now.
  CampusEvent _invitable(UserProfile user, String eventId) {
    final e = _events[eventId];
    if (e == null || !_manages(user, e)) throw StateError("You can't manage this event.");
    if (e.status != EventStatus.published || !e.start.isAfter(clock())) {
      throw StateError('Only upcoming published events can take invitations.');
    }
    return e;
  }

  /// Why a sample student can't be invited to [e], or null.
  String? _cantInvite(CampusEvent e, OrgMember m) {
    if (_registered[e.id]?.contains(m.id) ?? false) return 'Already going';
    if (_eligible(_asProfile(m), e)) return null;
    final club = mockOrganizations.any((o) => o.name == e.audience);
    return club ? 'Not a member of ${e.audience}' : 'Not in ${e.audience}';
  }

  @override
  Future<InviteOptions?> loadInviteOptions(UserProfile user, String eventId) async {
    await _wait();
    final CampusEvent e;
    try {
      e = _invitable(user, eventId);
    } on StateError {
      return null;
    }
    // One row per section, with the subjects taught there.
    final subjects = <String, List<String>>{};
    // Only a teacher's own sections; an officer invites clubs and students.
    for (final c in user.role == UserRole.teacher ? _classesOf(user) : const <ClassInfo>[]) {
      subjects.putIfAbsent(c.section, () => []).add(c.subject);
    }
    return InviteOptions(
      sections: [
        for (final MapEntry(key: section, value: taught) in subjects.entries)
          (
            id: section,
            name: section,
            detail: taught.join(' · '),
            studentIds: [for (final s in mockRosters[section] ?? const <RosterStudent>[]) s.id],
          ),
      ],
      clubs: [
        for (final o in _orgs)
          if (_members[o.id] case final members?)
            (
              id: o.id,
              name: o.name,
              detail: '${members.length} members',
              studentIds: members.keys.toList(),
            ),
      ],
      students: [
        for (final m in _people)
          InviteCandidate(
            id: m.id,
            name: m.name,
            maskedId: m.maskedId,
            section: m.section,
            photoAsset: m.photoAsset,
            unavailable: _cantInvite(e, m),
          ),
      ]..sort((a, b) => a.name.compareTo(b.name)),
      spotsLeft: e.capacity == null ? null : e.capacity! - _going(e),
    );
  }

  @override
  Future<int> invite(UserProfile user, String eventId,
      {List<String> sections = const [],
      List<String> orgIds = const [],
      List<String> studentIds = const []}) async {
    await _wait();
    final e = _invitable(user, eventId);
    final mine = user.role == UserRole.teacher
        ? _classesOf(user).map((c) => c.section).toSet()
        : const <String>{};
    if (!sections.every(mine.contains)) throw StateError('You can only invite your sections.');
    final picked = {
      for (final s in sections)
        for (final st in mockRosters[s] ?? const <RosterStudent>[]) st.id,
      for (final id in orgIds)
        ...(_members[id]?.keys ?? (throw StateError('No member list for this club.'))),
      ...studentIds,
    };
    final people = [for (final id in picked) _student(id) ?? (throw StateError('No such student.'))];
    // Whole groups skip who can't come; a student picked by name must be invitable.
    final added = [for (final m in people) if (_cantInvite(e, m) == null) m];
    for (final id in studentIds) {
      final why = _cantInvite(e, _student(id)!);
      if (why != null && why != 'Already going') throw StateError("Can't invite: $why.");
    }
    if (e.capacity != null && _going(e) + added.length > e.capacity!) {
      throw StateError('Not enough spots left for everyone you picked.');
    }
    _registered.putIfAbsent(eventId, () => {}).addAll(added.map((m) => m.id));
    _invited.putIfAbsent(eventId, () => {}).addAll(added.map((m) => m.id));
    for (final m in added) {
      _notices.putIfAbsent(m.id, () => []).insert(
            0,
            AppNotification(
              id: 'invite-${++_noticeCount}',
              kind: NotificationKind.event,
              title: '${user.fullName} registered you for ${e.title}.',
              time: clock(),
              route: '/life/events/${e.id}',
            ),
          );
    }
    return added.length;
  }

  @override
  Future<List<Organization>> loadMyOrganizations(UserProfile user) async {
    await _wait();
    return _orgs.where((o) => _isMember(user, o)).toList();
  }

  // ---------- Event history and check-in ----------

  @override
  Future<List<SemesterGrades>> loadGrades(UserProfile student) async {
    await _wait();
    // shortcut: every previewed student gets the same sample grades; real
    // grades come per student from the registrar later.
    return student.role == UserRole.student ? mockGrades(clock()) : const [];
  }

  @override
  Future<List<EventRecord>> loadEventHistory(UserProfile user) async {
    await _wait();
    return [...?_history[user.id]]..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<EventCheckIn?> loadEventCheckIn(UserProfile user, String eventId) async {
    await _wait();
    final e = _events[eventId];
    if (e == null || !_manages(user, e)) return null;
    final registrants = [
      for (final id in _registered[eventId] ?? const <String>{})
        ?_rosterStudent(id),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return EventCheckIn(
      event: e,
      registrants: registrants,
      present: {...?_eventPresent[eventId]},
      finalized: _eventFinalized.contains(eventId),
    );
  }

  @override
  Future<ScanResult> recordEventScan(UserProfile user, String eventId, String qrToken,
      {bool ignoreClock = false}) async {
    await _wait();
    final e = _events[eventId];
    if (e == null || !_manages(user, e)) throw StateError("You can't take attendance here.");
    if (_eventFinalized.contains(eventId) || e.status != EventStatus.published) {
      return const ScanResult(ScanOutcome.closed);
    }
    final now = clock();
    // Check-in opens 30 minutes before the start and closes at the end.
    if (!ignoreClock) {
      if (now.isBefore(e.start.subtract(const Duration(minutes: 30)))) {
        return const ScanResult(ScanOutcome.notOpenYet);
      }
      if (!now.isBefore(e.end)) return const ScanResult(ScanOutcome.closed);
    }
    final student = mockRosters.values
        .expand((roster) => roster)
        .where((s) => s.qrToken == qrToken)
        .firstOrNull;
    // Only registered students are marked (registration, then attendance).
    if (student == null || !(_registered[eventId]?.contains(student.id) ?? false)) {
      return const ScanResult(ScanOutcome.notEnrolled);
    }
    final present = _eventPresent.putIfAbsent(eventId, () => {});
    return ScanResult(
        present.add(student.id) ? ScanOutcome.present : ScanOutcome.duplicate, student);
  }

  @override
  Future<int> finalizeEventAttendance(UserProfile user, String eventId) async {
    await _wait();
    final e = _events[eventId];
    if (e == null || !_manages(user, e)) throw StateError("You can't take attendance here.");
    if (!_eventFinalized.add(eventId)) throw StateError('Attendance is already finalized.');
    var added = 0;
    for (final id in _eventPresent[eventId] ?? const <String>{}) {
      if (_recordOf(id, eventId) != null) continue;
      _history.putIfAbsent(id, () => []).add(EventRecord(
            id: 'rec-$eventId-$id',
            eventId: eventId,
            eventName: e.title,
            date: e.start,
            imageAsset: e.coverAsset,
            status: ParticipationStatus.attended,
            role: EventRole.participant,
          ));
      added++;
    }
    return added;
  }

  // ---------- People and Connect (spec §10.1) ----------

  /// Connected pairs, stored as "a|b" with the smaller id first.
  final _connected = {for (final (a, b) in mockConnections) _pair(a, b)};

  /// Waiting requests: "from>to" → when it was sent.
  late final _connectRequests = {
    for (final (from, to, hoursAgo) in mockConnectRequests)
      '$from>$to': clock().subtract(Duration(hours: hoursAgo)),
  };
  final _blocks = <String, Set<String>>{}; // blocker → students they blocked
  final _privacy = Map<String, PrivacySettings>.of(mockPrivacy);
  final _connectNotices = <String, List<AppNotification>>{}; // e.g. "… accepted"

  static String _pair(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  bool _isConnected(String a, String b) => _connected.contains(_pair(a, b));

  bool _blockedEither(String a, String b) =>
      (_blocks[a]?.contains(b) ?? false) || (_blocks[b]?.contains(a) ?? false);

  Set<String> _connectionsOf(String id) => {
        for (final p in _connected)
          if (p.split('|') case [final a, final b] when a == id || b == id) a == id ? b : a,
      };

  ConnectionStatus _statusWith(UserProfile viewer, String id) {
    if (viewer.role != UserRole.student) return ConnectionStatus.none; // teachers don't connect
    if (_blocks[viewer.id]?.contains(id) ?? false) return ConnectionStatus.blocked;
    if (_isConnected(viewer.id, id)) return ConnectionStatus.connected;
    if (_connectRequests.containsKey('${viewer.id}>$id')) return ConnectionStatus.requestSent;
    if (_connectRequests.containsKey('$id>${viewer.id}')) return ConnectionStatus.requestReceived;
    return ConnectionStatus.none;
  }

  Set<String> _mutualWith(UserProfile viewer, String id) => viewer.role == UserRole.student
      ? _connectionsOf(viewer.id).intersection(_connectionsOf(id))
      : const {};

  PersonSummary _summary(UserProfile viewer, OrgMember m) => PersonSummary(
        id: m.id,
        name: m.name,
        section: m.section,
        photoAsset: m.photoAsset,
        status: _statusWith(viewer, m.id),
        mutual: _mutualWith(viewer, m.id).length,
      );

  List<PersonSummary> _summaries(UserProfile viewer, Iterable<String> ids) =>
      [for (final id in ids) if (_student(id) case final m?) _summary(viewer, m)]
        ..sort((a, b) => a.name.compareTo(b.name));

  /// Every sample student (the class lists), as people.
  Iterable<OrgMember> get _people => [
        for (final roster in mockRosters.values)
          for (final s in roster) ?_student(s.id),
      ];

  /// The one visibility rule (spec §10.1): may [viewer] see a part of
  /// [ownerId]'s profile that is set to [level]?
  bool _mayView(UserProfile viewer, String ownerId, PrivacyLevel level) {
    if (viewer.id == ownerId) return true;
    // Every teacher sees everything (decided 2026-10-24).
    if (viewer.role == UserRole.teacher) return true;
    if (_blockedEither(viewer.id, ownerId)) return false;
    return switch (level) {
      PrivacyLevel.public => true,
      PrivacyLevel.connections => _isConnected(viewer.id, ownerId),
      PrivacyLevel.onlyMe => false,
    };
  }

  PrivacySettings _privacyOf(String id) => _privacy[id] ?? const PrivacySettings();

  /// A sample student as a profile, with tags from their memberships.
  UserProfile _asProfile(OrgMember m) {
    if (m.id == mockStudent.id) return withAffiliations(mockStudent);
    final names = m.name.split(' ');
    return withAffiliations(UserProfile(
      id: m.id,
      role: UserRole.student,
      firstName: names.first,
      lastName: names.skip(1).join(' '),
      designation: m.section,
      maskedId: m.maskedId,
      email: '',
      qrToken: '',
      photoAsset: m.photoAsset,
      tags: mockSampleStudentTags,
    ));
  }

  void _requireStudent(UserProfile user) {
    if (user.role != UserRole.student) {
      throw StateError('Only students connect with each other.');
    }
  }

  OrgMember _otherStudent(UserProfile viewer, String id) {
    final m = _student(id);
    if (m == null || id == viewer.id) throw StateError('No such student.');
    return m;
  }

  @override
  Future<PersonProfile?> loadPerson(UserProfile viewer, String personId) async {
    await _wait();
    final m = _student(personId);
    if (m == null) return null;
    final summary = _summary(viewer, m);
    if (viewer.role == UserRole.student &&
        viewer.id != personId &&
        _blockedEither(viewer.id, personId)) {
      return PersonProfile(person: summary, maskedId: m.maskedId, limited: true);
    }
    final now = clock();
    final settings = _privacyOf(personId);
    final profile = _asProfile(m);
    return PersonProfile(
      person: summary,
      maskedId: m.maskedId,
      tags: profile.tags,
      about: mockPeopleAbout[personId] ?? (personId == mockStudent.id ? mockStudent.about : null),
      connectionCount: _connectionsOf(personId).length,
      mutualConnections: _summaries(viewer, _mutualWith(viewer, personId)),
      connections: _mayView(viewer, personId, settings.connections)
          ? _summaries(viewer, _connectionsOf(personId))
          : null,
      upcoming: _mayView(viewer, personId, settings.upcomingEvents)
          ? (_events.values
              .where((e) =>
                  (_registered[e.id]?.contains(personId) ?? false) &&
                  e.status == EventStatus.published &&
                  e.start.isAfter(now) &&
                  // Members-only events stay hidden from those who can't see them.
                  (viewer.role == UserRole.teacher ||
                      viewer.id == personId ||
                      _eligible(viewer, e)))
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start)))
          : null,
      history: _mayView(viewer, personId, settings.eventHistory)
          ? ([...?_history[personId]]..sort((a, b) => b.date.compareTo(a.date)))
          : null,
    );
  }

  @override
  Future<ConnectionsOverview> loadConnections(UserProfile user) async {
    await _wait();
    List<String> requests(bool incoming) {
      final waiting = _connectRequests.entries.where((e) {
        final [from, to] = e.key.split('>');
        return incoming ? to == user.id : from == user.id;
      }).toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      return [for (final e in waiting) e.key.split('>')[incoming ? 0 : 1]];
    }

    PersonSummary? one(String id) =>
        _student(id) == null ? null : _summary(user, _student(id)!);
    return ConnectionsOverview(
      incoming: [for (final id in requests(true)) ?one(id)],
      connections: _summaries(user, _connectionsOf(user.id)),
      sent: [for (final id in requests(false)) ?one(id)],
    );
  }

  @override
  Future<List<PersonSummary>> searchPeople(UserProfile viewer, String query) async {
    await _wait();
    final q = query.trim().toLowerCase();
    return _summaries(viewer, [
      for (final m in _people)
        if (m.id != viewer.id &&
            !_blockedEither(viewer.id, m.id) &&
            m.name.toLowerCase().contains(q))
          m.id,
    ]);
  }

  @override
  Future<List<PersonSummary>> loadSuggestions(UserProfile viewer) async {
    await _wait();
    if (viewer.role != UserRole.student) return const [];
    final me = _student(viewer.id);
    final myClubs = {
      for (final e in _members.entries)
        if (e.value.containsKey(viewer.id)) e.key,
    };
    // Mutual connections count most, then the same section, then shared clubs.
    int score(OrgMember m) =>
        _mutualWith(viewer, m.id).length * 3 +
        (m.section == me?.section ? 2 : 0) +
        myClubs.where((c) => _members[c]!.containsKey(m.id)).length;
    final candidates = [
      for (final m in _people)
        if (m.id != viewer.id &&
            _statusWith(viewer, m.id) == ConnectionStatus.none &&
            !_blockedEither(viewer.id, m.id) &&
            score(m) > 0)
          m,
    ]..sort((a, b) {
        final s = score(b).compareTo(score(a));
        return s != 0 ? s : a.name.compareTo(b.name);
      });
    return [for (final m in candidates.take(6)) _summary(viewer, m)];
  }

  @override
  Future<void> sendConnectRequest(UserProfile viewer, String personId) async {
    await _wait();
    _requireStudent(viewer);
    _otherStudent(viewer, personId);
    if (_blockedEither(viewer.id, personId)) {
      throw StateError("You can't connect with this student.");
    }
    switch (_statusWith(viewer, personId)) {
      case ConnectionStatus.connected:
        throw StateError("You're already connected.");
      case ConnectionStatus.requestSent:
        throw StateError('You already sent a request.');
      case ConnectionStatus.requestReceived:
        // They already asked: connecting both ways is the same as accepting.
        _accept(viewer, personId);
      default:
        _connectRequests['${viewer.id}>$personId'] = clock();
    }
  }

  void _accept(UserProfile viewer, String fromId) {
    _connectRequests.remove('$fromId>${viewer.id}');
    _connected.add(_pair(viewer.id, fromId));
    _connectNotices.putIfAbsent(fromId, () => []).insert(
          0,
          AppNotification(
            id: 'connect-ok-${viewer.id}-${_connected.length}',
            kind: NotificationKind.connection,
            title: '${viewer.fullName} accepted your request to connect.',
            time: clock(),
            route: '/life/people/${viewer.id}',
          ),
        );
  }

  @override
  Future<void> cancelConnectRequest(UserProfile viewer, String personId) async {
    await _wait();
    if (_connectRequests.remove('${viewer.id}>$personId') == null) {
      throw StateError('There is no request to cancel.');
    }
  }

  @override
  Future<void> answerConnectRequest(UserProfile viewer, String fromId,
      {required bool accept}) async {
    await _wait();
    _requireStudent(viewer);
    if (!_connectRequests.containsKey('$fromId>${viewer.id}')) {
      throw StateError('This request was already answered.');
    }
    if (accept) {
      _accept(viewer, fromId);
    } else {
      _connectRequests.remove('$fromId>${viewer.id}'); // silent: no notice
    }
  }

  @override
  Future<void> removeConnection(UserProfile viewer, String personId) async {
    await _wait();
    if (!_connected.remove(_pair(viewer.id, personId))) {
      throw StateError("You aren't connected.");
    }
  }

  @override
  Future<void> blockStudent(UserProfile viewer, String personId) async {
    await _wait();
    _requireStudent(viewer);
    _otherStudent(viewer, personId);
    _blocks.putIfAbsent(viewer.id, () => {}).add(personId);
    _connected.remove(_pair(viewer.id, personId));
    _connectRequests.remove('${viewer.id}>$personId');
    _connectRequests.remove('$personId>${viewer.id}');
  }

  @override
  Future<void> unblockStudent(UserProfile viewer, String personId) async {
    await _wait();
    if (!(_blocks[viewer.id]?.remove(personId) ?? false)) {
      throw StateError("This student isn't blocked.");
    }
  }

  @override
  Future<List<PersonSummary>> loadBlocked(UserProfile user) async {
    await _wait();
    return _summaries(user, _blocks[user.id] ?? const {});
  }

  @override
  Future<PrivacySettings> loadPrivacy(UserProfile user) async {
    await _wait();
    return _privacyOf(user.id);
  }

  @override
  Future<void> savePrivacy(UserProfile user, PrivacySettings settings) async {
    await _wait();
    _requireStudent(user);
    _privacy[user.id] = settings;
  }

  @override
  Future<EventAttendees?> loadEventAttendees(UserProfile viewer, String eventId) async {
    final d = await loadEvent(viewer, eventId); // the same "who can see the event" rule
    if (d == null) return null;
    final past = !d.event.end.isAfter(clock());
    // Went: attendance records (registration isn't attendance). Going: registrations.
    final ids = (past
            ? {
                for (final e in _history.entries)
                  if (e.value.any((r) => r.eventId == eventId)) e.key,
              }
            : {...?_registered[eventId]})
        .where((id) => _student(id) != null)
        .toSet();
    PrivacyLevel level(String id) =>
        past ? _privacyOf(id).eventHistory : _privacyOf(id).upcomingEvents;
    final shown = _summaries(
        viewer, ids.where((id) => id != viewer.id && _mayView(viewer, id, level(id))))
      // Connections first; each part stays by name.
      ..sort((a, b) {
        final c = (b.status == ConnectionStatus.connected ? 1 : 0)
            .compareTo(a.status == ConnectionStatus.connected ? 1 : 0);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
    return EventAttendees(
      past: past,
      shown: shown,
      includesViewer: ids.contains(viewer.id),
      // Upcoming totals include the unnamed sample registrations.
      total: past ? ids.length : d.going,
    );
  }

  @override
  Future<List<AppNotification>> loadConnectNotices(UserProfile user) async {
    await _wait();
    return [
      ...?_connectNotices[user.id],
      // A waiting request shows until it's answered (or cancelled).
      for (final e in _connectRequests.entries)
        if (e.key.split('>') case [final from, final to] when to == user.id)
          if (_student(from) case final m?)
            AppNotification(
              id: 'connect-req-$from',
              kind: NotificationKind.connection,
              title: '${m.name} wants to connect.',
              time: e.value,
              route: '/profile',
            ),
    ];
  }

  // ---------- Organizations ----------

  // Org id → user ids waiting, oldest first (a Set keeps insertion order).
  final _joinRequests = {
    for (final e in mockJoinRequests.entries) e.key: {...e.value},
  };

  /// Member lists of clubs with an adviser: org id → student id → position.
  final _members = {
    for (final e in mockClubMembers.entries) e.key: Map<String, String?>.of(e.value),
  };
  final _orgEdits = <String, Organization>{}; // About and meetings, as advisers edited them
  final _notices = <String, List<AppNotification>>{}; // student id → membership news
  var _noticeCount = 0;

  /// Clubs with a member list use it; others use the user's membership tags.
  bool _isMember(UserProfile user, Organization o) =>
      _members[o.id]?.containsKey(user.id) ??
      user.tags.any((t) => t.kind == TagKind.organization && t.label == o.name);

  /// The organizations as they are now: edited info, and for clubs with a
  /// member list, its count and officers (positions, then advisers).
  List<Organization> get _orgs => [
        for (final base in mockOrganizations)
          if (_members[base.id] == null)
            _orgEdits[base.id] ?? base
          else
            (_orgEdits[base.id] ?? base).copyWith(
              memberCount: _members[base.id]!.length,
              officers: [
                for (final m in _memberList(base.id))
                  if (m.position != null)
                    OrgOfficer(name: m.name, position: m.position!, photoAsset: m.photoAsset),
                for (final id in base.adviserIds)
                  if (id == mockTeacher.id)
                    OrgOfficer(
                        name: mockTeacher.fullName,
                        position: 'Adviser',
                        photoAsset: mockTeacher.photoAsset),
              ],
            ),
      ];

  /// A sample student from the class rosters, as a club sees them.
  OrgMember? _student(String id, {String? position}) {
    for (final e in mockRosters.entries) {
      for (final s in e.value) {
        if (s.id == id) {
          return OrgMember(
            id: s.id,
            name: s.name,
            section: e.key,
            maskedId: s.maskedId,
            photoAsset: s.photoAsset,
            position: position,
          );
        }
      }
    }
    return null;
  }

  /// Officers first (in [officerPositions] order), then members by name.
  List<OrgMember> _memberList(String orgId) {
    int rank(OrgMember m) {
      if (m.position == null) return 999;
      final i = officerPositions.indexOf(m.position!);
      return i < 0 ? officerPositions.length : i;
    }

    return [
      for (final e in (_members[orgId] ?? const <String, String?>{}).entries)
        ?_student(e.key, position: e.value),
    ]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
  }

  /// The club, if [user] may use [power] in it (any power when null): its
  /// advisers always; its officers when mockOfficerPowers allows it. Being an
  /// officer comes from the member list, not from the tag that shows it.
  Organization? _advisedOrNull(UserProfile user, String orgId, [ClubPower? power]) {
    final o = _orgs.where((o) => o.id == orgId).firstOrNull;
    final members = o == null ? null : _members[o.id];
    if (o == null || members == null) return null;
    if (o.adviserIds.contains(user.id)) return o;
    final officer = members[user.id] != null;
    final allowed = power == null ? mockOfficerPowers.isNotEmpty : mockOfficerPowers.contains(power);
    return officer && allowed ? o : null;
  }

  Organization _advised(UserProfile user, String orgId, [ClubPower? power]) =>
      _advisedOrNull(user, orgId, power) ?? (throw StateError("You can't manage this club."));

  void _notify(String studentId, String orgId, String title) {
    _notices.putIfAbsent(studentId, () => []).insert(
          0,
          AppNotification(
            id: 'club-${++_noticeCount}',
            kind: NotificationKind.organization,
            title: title,
            time: clock(),
            route: '/life/organizations/$orgId',
          ),
        );
  }

  String _withReason(String text, String? reason) =>
      reason == null || reason.trim().isEmpty ? text : '$text Reason: ${reason.trim()}';

  @override
  Future<List<AdvisedClub>> loadAdvisedClubs(UserProfile user, {ClubPower? power}) async {
    await _wait();
    return [
      for (final o in _orgs)
        if (_advisedOrNull(user, o.id, power) != null)
          AdvisedClub(org: o, requests: _joinRequests[o.id]?.length ?? 0),
    ];
  }

  @override
  Future<ClubAdmin?> loadClubAdmin(UserProfile user, String orgId) async {
    await _wait();
    final o = _advisedOrNull(user, orgId);
    if (o == null) return null;
    return ClubAdmin(
      org: o,
      members: _memberList(o.id),
      requests: [
        for (final id in _joinRequests[o.id] ?? const <String>{})
          ?_student(id),
      ],
      events: _events.values.where((e) => e.host == o.name).toList()
        ..sort((a, b) => b.start.compareTo(a.start)),
    );
  }

  @override
  Future<void> answerJoinRequest(UserProfile adviser, String orgId, String studentId,
      {required bool accept, String? reason}) async {
    await _wait();
    final o = _advised(adviser, orgId, ClubPower.members);
    if (!(_joinRequests[orgId]?.remove(studentId) ?? false)) {
      throw StateError('This request was already answered.');
    }
    if (accept) {
      _members[orgId]![studentId] = null;
      _notify(studentId, orgId, 'Your request to join ${o.name} was accepted.');
    } else {
      _notify(studentId, orgId,
          _withReason('Your request to join ${o.name} was declined.', reason));
    }
  }

  @override
  Future<void> addMember(UserProfile adviser, String orgId, String studentId) async {
    await _wait();
    final o = _advised(adviser, orgId, ClubPower.members);
    if (_student(studentId) == null) throw StateError('No such student.');
    if (_members[orgId]!.containsKey(studentId)) throw StateError('Already a member.');
    _joinRequests[orgId]?.remove(studentId);
    _members[orgId]![studentId] = null;
    _notify(studentId, orgId, 'You were added to ${o.name}.');
  }

  @override
  Future<void> removeMember(UserProfile adviser, String orgId, String studentId,
      {String? reason}) async {
    await _wait();
    final o = _advised(adviser, orgId, ClubPower.members);
    if (!_members[orgId]!.containsKey(studentId)) throw StateError('Not a member.');
    _members[orgId]!.remove(studentId);
    _notify(studentId, orgId, _withReason('You were removed from ${o.name}.', reason));
  }

  @override
  Future<void> setOfficerPosition(
      UserProfile adviser, String orgId, String studentId, String? position) async {
    await _wait();
    _advised(adviser, orgId, ClubPower.members);
    if (!_members[orgId]!.containsKey(studentId)) throw StateError('Not a member.');
    _members[orgId]![studentId] =
        position == null || position.trim().isEmpty ? null : position.trim();
  }

  @override
  Future<void> updateClubInfo(UserProfile adviser, String orgId,
      {required String about, required List<OrgMeeting> meetings}) async {
    await _wait();
    _advised(adviser, orgId, ClubPower.info);
    if (meetings.any((m) => m.title.trim().isEmpty || m.when.trim().isEmpty)) {
      throw ArgumentError('Each meeting needs a name and a time.');
    }
    final base = _orgEdits[orgId] ?? mockOrganizations.firstWhere((o) => o.id == orgId);
    _orgEdits[orgId] = base.copyWith(about: about.trim(), meetings: [
      for (final m in meetings)
        OrgMeeting(title: m.title.trim(), when: m.when.trim(), place: m.place.trim()),
    ]);
  }

  @override
  Future<List<OrgMember>> searchStudents(
      UserProfile adviser, String orgId, String query) async {
    await _wait();
    _advised(adviser, orgId, ClubPower.members);
    final q = query.trim().toLowerCase();
    final taken = {..._members[orgId]!.keys, ...?_joinRequests[orgId]};
    return [
      for (final roster in mockRosters.values)
        for (final s in roster)
          if (!taken.contains(s.id) && s.name.toLowerCase().contains(q)) ?_student(s.id),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<AppNotification>> loadMembershipNotices(UserProfile user) async {
    await _wait();
    return [...?_notices[user.id]];
  }

  @override
  UserProfile withAffiliations(UserProfile user) {
    // Clubs with a member list: their tags follow the list, in place.
    final lists = {
      for (final o in mockOrganizations)
        o.name: ?_members[o.id],
    };
    bool member(String club) => lists[club]!.containsKey(user.id);
    final kept = [
      for (final t in user.tags)
        if (t.kind == TagKind.organization && lists.containsKey(t.label))
          ...[if (member(t.label)) t]
        else if (t.kind == TagKind.officer &&
            lists.keys.any((club) => t.label == '$club Officer'))
          ...[]
        else if (t.kind != TagKind.role) // rebuilt below from assignments
          t,
    ];
    return user.withTags([
      ...kept,
      // Assigned roles, so a teacher's tags show what they're responsible for.
      for (final o in _orgs)
        if (o.adviserIds.contains(user.id)) IdentityTag('${o.name} Adviser', TagKind.role),
      if (_officeOf(user) case final office?) IdentityTag('$office Clearance Staff', TagKind.role),
      for (final e in lists.entries)
        if (e.value.containsKey(user.id)) ...[
          if (!kept.any((t) => t.kind == TagKind.organization && t.label == e.key))
            IdentityTag(e.key, TagKind.organization),
          if (e.value[user.id] != null) IdentityTag('${e.key} Officer', TagKind.officer),
        ],
    ]);
  }

  bool _inDepartmentOf(UserProfile user, Organization o) =>
      o.department != null &&
      user.tags.any((t) => t.kind == TagKind.department && t.label == o.department);

  /// Clubs are open to all; a society only to its own department (and members).
  bool _canSee(UserProfile user, Organization o) =>
      o.kind == OrgKind.club || _inDepartmentOf(user, o) || _isMember(user, o);

  @override
  Future<OrgDirectory> loadOrganizationDirectory(UserProfile user) async {
    await _wait();
    return OrgDirectory(
      society: _orgs
          .where((o) => o.kind == OrgKind.society && _inDepartmentOf(user, o))
          .toList(),
      // Other departments' societies are never listed as school-wide clubs.
      clubs: _orgs.where((o) => o.kind == OrgKind.club).toList(),
      mine: _orgs.where((o) => _isMember(user, o)).toList(),
    );
  }

  @override
  Future<OrganizationPage?> loadOrganization(UserProfile user, String orgId) async {
    await _wait();
    final o = _orgs.where((o) => o.id == orgId).firstOrNull;
    if (o == null || !_canSee(user, o)) return null;
    final now = clock();
    final events = _events.values
        .where((e) => e.host == o.name && e.status == EventStatus.published && e.end.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final visibleEvents = events
        .where((e) => _eligible(user, e) || (_registered[e.id]?.contains(user.id) ?? false))
        .toList();
    final posts = mockPosts(now).where((p) => p.source == o.name).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    final visiblePosts = posts
        .where((p) => p.audience == null || user.tags.any((t) => t.label == p.audience))
        .toList();
    return OrganizationPage(
      org: o,
      isMember: _isMember(user, o),
      requested: _joinRequests[o.id]?.contains(user.id) ?? false,
      canManage: _advisedOrNull(user, o.id) != null,
      // Memberships are visible to all (spec §12); blocked students are left out.
      members: _members[o.id] == null
          ? null
          : _summaries(user, _members[o.id]!.keys.where((id) => !_blockedEither(user.id, id))),
      events: [for (final e in visibleEvents) _detail(user, e)],
      news: visiblePosts,
      membersOnlyHidden:
          events.length - visibleEvents.length + posts.length - visiblePosts.length,
    );
  }

  @override
  Future<void> requestToJoin(UserProfile user, String orgId) async {
    await _wait();
    final o = mockOrganizations.where((o) => o.id == orgId).firstOrNull;
    if (o == null || !_canSee(user, o)) throw StateError("This organization isn't available.");
    if (_isMember(user, o)) throw StateError("You're already a member.");
    if (!_joinRequests.putIfAbsent(orgId, () => {}).add(user.id)) {
      throw StateError('You already asked to join.');
    }
  }

  @override
  Future<List<SupportContact>> loadSupportContacts() async {
    await _wait();
    return mockSupportContacts;
  }

  // ---------- Clearance (in memory, this preview only) ----------

  final _clearance = mockClearanceStatuses();

  /// The student's requirements with their current statuses.
  List<ClearanceItem> _itemsOf(String studentId) => [
        for (final t in mockClearanceItems)
          if (_clearance[studentId]?[t.id] case final s?)
            ClearanceItem(
              id: t.id,
              office: t.office,
              title: t.title,
              instructions: t.instructions,
              status: s.$1,
              reason: s.$2,
              evidenceRequired: t.evidenceRequired,
            )
          else
            t,
      ];

  /// The office a staff member may process; null without permission.
  String? _officeOf(UserProfile user) =>
      user.can(Permission.processClearance) ? mockClearanceOffices[user.id] : null;

  ClearanceStudent? _clearanceStudent(String id) {
    for (final MapEntry(key: section, value: roster) in mockRosters.entries) {
      for (final s in roster) {
        if (s.id == id) {
          return ClearanceStudent(
              id: s.id,
              name: s.name,
              maskedId: s.maskedId,
              section: section,
              photoAsset: s.photoAsset,
              qrToken: s.qrToken);
        }
      }
    }
    return null;
  }

  @override
  Future<ClearanceSummary?> loadClearance(UserProfile user) async {
    final view = await loadClearanceView(user);
    final p = view.active;
    if (p == null) return null;
    return ClearanceSummary(
      periodName: p.name,
      deadline: p.deadline,
      cleared: p.cleared,
      total: p.applicable.length,
      needsCorrection:
          p.items.where((i) => i.status == ClearanceStatus.needsCorrection).length,
    );
  }

  @override
  Future<ClearanceView> loadClearanceView(UserProfile user) async {
    await _wait();
    final period = mockClearancePeriod(clock());
    final isStudent = user.role == UserRole.student;
    return ClearanceView(
      active: period == null || !isStudent
          ? null
          : ClearancePeriod(name: period.name, deadline: period.deadline, items: _itemsOf(user.id)),
      past: mockPastClearances[user.id] ?? const [],
    );
  }

  @override
  Future<void> markSubmitted(UserProfile student, String itemId) async {
    await _wait();
    if (student.role != UserRole.student || mockClearancePeriod(clock()) == null) {
      throw StateError('There is no active clearance period.');
    }
    final item = _itemsOf(student.id).where((i) => i.id == itemId).firstOrNull;
    if (item == null) throw StateError('This requirement no longer exists.');
    const open = {
      ClearanceStatus.notStarted,
      ClearanceStatus.actionRequired,
      ClearanceStatus.needsCorrection,
    };
    if (!open.contains(item.status)) throw StateError('There is nothing to submit for this.');
    // Submitting only sends it for review; it never clears anything.
    _clearance.putIfAbsent(student.id, () => {})[itemId] = (ClearanceStatus.inReview, null);
  }

  @override
  Future<ClearanceOffice?> loadClearanceOffice(UserProfile user) async {
    final desk = await loadClearanceDesk(user);
    return desk == null
        ? null
        : ClearanceOffice(name: desk.office, pendingCount: desk.pending.length);
  }

  @override
  Future<ClearanceDesk?> loadClearanceDesk(UserProfile user) async {
    await _wait();
    final office = _officeOf(user);
    final period = mockClearancePeriod(clock());
    if (office == null || period == null) return null;
    final pending = <ClearanceCase>[];
    for (final id in _clearance.keys) {
      final items = _itemsOf(id).where((i) => i.office == office).toList();
      final student = _clearanceStudent(id);
      if (student != null && items.any((i) => i.status == ClearanceStatus.inReview)) {
        pending.add(ClearanceCase(student: student, items: items));
      }
    }
    pending.sort((a, b) => a.student.name.compareTo(b.student.name));
    return ClearanceDesk(office: office, periodName: period.name, pending: pending);
  }

  @override
  Future<String?> findStudentByQr(UserProfile user, String qrToken) async {
    await _wait();
    if (_officeOf(user) == null) throw StateError("You aren't assigned to a clearance area.");
    for (final roster in mockRosters.values) {
      for (final s in roster) {
        if (s.qrToken == qrToken) return s.id;
      }
    }
    return null;
  }

  @override
  Future<ClearanceCase?> loadClearanceCase(UserProfile user, String studentId) async {
    await _wait();
    final office = _officeOf(user);
    final student = _clearanceStudent(studentId);
    if (office == null || student == null || mockClearancePeriod(clock()) == null) return null;
    return ClearanceCase(
      student: student,
      items: _itemsOf(studentId).where((i) => i.office == office).toList(),
    );
  }

  @override
  Future<void> recordOutcome(UserProfile user, String studentId, String itemId,
      ClearanceStatus outcome, {String? reason}) async {
    await _wait();
    final office = _officeOf(user);
    if (office == null) throw StateError("You aren't assigned to a clearance area.");
    if (mockClearancePeriod(clock()) == null) throw StateError('There is no active clearance period.');
    final item = _itemsOf(studentId).where((i) => i.id == itemId).firstOrNull;
    if (item == null || _clearanceStudent(studentId) == null) {
      throw StateError('This requirement no longer exists.');
    }
    // Staff process only their own office's requirements (spec §7.5).
    if (item.office != office) throw StateError("This requirement isn't yours to process.");
    const outcomes = {
      ClearanceStatus.cleared,
      ClearanceStatus.needsCorrection,
      ClearanceStatus.onHold,
    };
    if (!outcomes.contains(outcome)) throw ArgumentError('Pick Cleared, Needs Correction, or On Hold.');
    final why = reason?.trim() ?? '';
    if (outcome != ClearanceStatus.cleared && why.isEmpty) {
      throw ArgumentError('Give a reason so the student knows what to fix.');
    }
    _clearance.putIfAbsent(studentId, () => {})[itemId] = (outcome, why.isEmpty ? null : why);
  }

  // ---------- Consultations (decided 2026-10-30) ----------

  final _signatures = <String, String>{}; // user id → photo path, this preview only
  final _consultations = <String, Consultation>{}; // no samples: each needs real signatures
  var _nextConsultation = 0;

  @override
  Future<String?> loadSignature(UserProfile user) async {
    await _wait();
    return _signatures[user.id];
  }

  @override
  Future<void> saveSignature(UserProfile user, String? photo) async {
    await _wait();
    if (photo == null) {
      _signatures.remove(user.id);
    } else {
      _signatures[user.id] = photo;
    }
  }

  void _requireConsulting(UserProfile teacher) {
    if (!teacher.can(Permission.holdConsultations)) {
      throw StateError("You can't hold consultations.");
    }
  }

  @override
  Future<List<OrgMember>> findStudents(UserProfile teacher, String query) async {
    await _wait();
    _requireConsulting(teacher);
    final q = query.trim().toLowerCase();
    return [for (final m in _people) if (m.name.toLowerCase().contains(q)) m]
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  bool _canSeeConsultation(UserProfile user, Consultation c) =>
      c.teacherId == user.id || c.studentId == user.id;

  @override
  Future<List<Consultation>> loadConsultations(UserProfile user) async {
    await _wait();
    return [for (final c in _consultations.values) if (_canSeeConsultation(user, c)) c]
      ..sort((a, b) => b.heldAt.compareTo(a.heldAt));
  }

  @override
  Future<Consultation?> loadConsultation(UserProfile user, String id) async {
    await _wait();
    final c = _consultations[id];
    return c != null && _canSeeConsultation(user, c) ? c : null;
  }

  @override
  Future<Consultation> saveConsultation(
    UserProfile teacher, {
    String? id,
    required String studentId,
    required String department,
    required String venue,
    required List<ConsultationRow> rows,
    required String expectedOutcome,
    bool scanned = false,
  }) async {
    await _wait();
    _requireConsulting(teacher);
    final old = id == null ? null : _consultations[id];
    if (id != null && (old == null || old.teacherId != teacher.id)) {
      throw StateError('You can only edit your own consultations.');
    }
    final student = _student(old?.studentId ?? studentId);
    if (student == null) throw StateError('No such student.');
    final kept = [
      for (final r in rows)
        if (r.reason.trim().isNotEmpty || r.intervention.trim().isNotEmpty)
          (reason: r.reason.trim(), intervention: r.intervention.trim()),
    ];
    if (kept.isEmpty) throw ArgumentError('Add at least one reason.');
    if (kept.any((r) => r.reason.isEmpty)) throw ArgumentError('Every row needs a reason.');
    if (kept.length > maxConsultationRows) {
      throw ArgumentError('Add up to $maxConsultationRows reasons.');
    }
    if (!consultationDepartments.contains(department)) throw ArgumentError('Pick a department.');
    if (venue.trim().isEmpty) throw ArgumentError('Add the venue.');
    // Longer text would be cut off on the printed form.
    if (venue.trim().length > maxConsultationVenueLength ||
        expectedOutcome.trim().length > maxConsultationOutcomeLength ||
        kept.any((r) =>
            r.reason.length > maxConsultationCellLength ||
            r.intervention.length > maxConsultationCellLength)) {
      throw ArgumentError('Some text is too long for the form.');
    }
    // A new form needs the teacher's e-signature (decided 2026-10-31); it
    // keeps that one for good, through edits and later changes in Settings.
    final teacherSignature = old?.teacherSignature ?? _signatures[teacher.id];
    if (teacherSignature == null) {
      throw StateError('Add your e-signature before starting a consultation.');
    }
    final now = clock();
    // The student's QR signs only when they have an e-signature on file.
    final signs = scanned && !(old?.studentSigned ?? false) && _signatures[student.id] != null;
    final c = Consultation(
      id: old?.id ?? 'cons-new-${++_nextConsultation}',
      teacherId: teacher.id,
      teacherName: teacher.fullName,
      studentId: student.id,
      studentName: student.name,
      studentSection: student.section,
      studentMaskedId: student.maskedId,
      heldAt: old?.heldAt ?? now,
      department: department,
      venue: venue.trim(),
      rows: kept,
      expectedOutcome: expectedOutcome.trim(),
      teacherSignature: teacherSignature,
      studentSignedAt: signs ? now : old?.studentSignedAt,
      studentSignature: signs ? _signatures[student.id] : old?.studentSignature,
      editedAfterSigning: (old?.editedAfterSigning ?? false) || (old?.studentSigned ?? false),
    );
    return _consultations[c.id] = c;
  }

  @override
  Future<Consultation> signConsultation(
      UserProfile teacher, String id, String scannedStudentId) async {
    await _wait();
    _requireConsulting(teacher);
    final old = _consultations[id];
    if (old == null || old.teacherId != teacher.id) {
      throw StateError('You can only sign your own consultations.');
    }
    if (old.studentSigned) throw StateError('The student already signed.');
    if (scannedStudentId != old.studentId) {
      throw StateError("This QR isn't ${old.studentName}'s.");
    }
    if (_signatures[old.studentId] == null) {
      throw StateError('${old.studentName} needs to add an e-signature first '
          '(Settings › My e-signature).');
    }
    return _consultations[id] = Consultation(
      id: old.id,
      teacherId: old.teacherId,
      teacherName: old.teacherName,
      studentId: old.studentId,
      studentName: old.studentName,
      studentSection: old.studentSection,
      studentMaskedId: old.studentMaskedId,
      heldAt: old.heldAt,
      department: old.department,
      venue: old.venue,
      rows: old.rows,
      expectedOutcome: old.expectedOutcome,
      teacherSignature: old.teacherSignature,
      studentSignedAt: clock(),
      studentSignature: _signatures[old.studentId],
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
