import '../mock/mock_campus.dart';
import '../mock/mock_classes.dart';
import '../mock/mock_home.dart' show mockPosts;
import '../models/attendance.dart';
import '../models/campus.dart';
import '../models/feed.dart';
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
  });

  Future<void> cancelEvent(UserProfile user, String eventId);

  /// Cover photos a teacher can pick for an event.
  List<String> get eventCovers;

  /// Registered students, for the event's managers; null for anyone else.
  Future<List<EventRegistrant>?> loadRegistrations(UserProfile user, String eventId);

  /// Invites whole sections; invited students are registered automatically
  /// (spec §7.3). Returns how many students were newly registered.
  Future<int> inviteSections(UserProfile user, String eventId, List<String> sections);

  /// Organizations the user is a confirmed member of.
  Future<List<Organization>> loadMyOrganizations(UserProfile user);

  /// The Organizations directory (spec §7.4): the user's departmental
  /// society, school-wide clubs, and confirmed memberships.
  Future<OrgDirectory> loadOrganizationDirectory(UserProfile user);

  /// One organization page; null if the user may not see it (another
  /// department's society they don't belong to).
  Future<OrganizationPage?> loadOrganization(UserProfile user, String orgId);

  /// Records a request to join in this preview. It never makes the user a
  /// member: memberships are confirmed by administrators (spec §5).
  Future<void> requestToJoin(UserProfile user, String orgId);

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
  final _registered = mockRegistrations();
  final _invited = <String, Set<String>>{}; // event id → invited student ids
  var _newEvents = 0;

  bool _eligible(UserProfile user, CampusEvent e) =>
      e.audience == null || user.tags.any((t) => t.label == e.audience);

  bool _manages(UserProfile user, CampusEvent e) =>
      user.can(Permission.manageEvents) && e.managerIds.contains(user.id);

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
          EventList.mine =>
            e.status != EventStatus.draft && (_registered[e.id]?.contains(user.id) ?? false),
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
  }) async {
    await _wait();
    if (!user.can(Permission.manageEvents)) throw StateError("You can't manage events.");
    final old = eventId == null ? null : _events[eventId];
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
    final host = old?.host ??
        user.tags.where((t) => t.kind == TagKind.department).firstOrNull?.label ??
        user.fullName;
    return _events[id] = CampusEvent(
      id: id,
      title: title.trim(),
      host: host,
      hostLogo: old?.hostLogo,
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
    );
  }

  @override
  List<String> get eventCovers => mockEventCovers;

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
            name: s.name,
            maskedId: s.maskedId,
            photoAsset: s.photoAsset,
            invited: invited.contains(id),
          ),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<int> inviteSections(UserProfile user, String eventId, List<String> sections) async {
    await _wait();
    final e = _events[eventId];
    if (e == null || !_manages(user, e)) throw StateError("You can't manage this event.");
    if (e.status != EventStatus.published || !e.start.isAfter(clock())) {
      throw StateError('Only upcoming published events can take invitations.');
    }
    // Mock assumption: a teacher invites only sections they teach, and every
    // student in them belongs to the teacher's department.
    final mine = _classesOf(user).map((c) => c.section).toSet();
    if (!sections.every(mine.contains)) throw StateError('You can only invite your sections.');
    if (e.audience != null && !user.tags.any((t) => t.label == e.audience)) {
      throw StateError("These students aren't eligible for this event.");
    }
    final registered = _registered.putIfAbsent(eventId, () => {});
    final added = {
      for (final s in sections)
        for (final st in mockRosters[s] ?? const <RosterStudent>[])
          if (!registered.contains(st.id)) st.id,
    };
    if (e.capacity != null && _going(e) + added.length > e.capacity!) {
      throw StateError('Not enough spots left for everyone in these sections.');
    }
    registered.addAll(added);
    _invited.putIfAbsent(eventId, () => {}).addAll(added);
    return added.length;
  }

  @override
  Future<List<Organization>> loadMyOrganizations(UserProfile user) async {
    await _wait();
    // Confirmed memberships are the user's organization tags (spec §5).
    final memberOf = user.tags
        .where((t) => t.kind == TagKind.organization)
        .map((t) => t.label)
        .toSet();
    return mockOrganizations.where((o) => memberOf.contains(o.name)).toList();
  }

  // ---------- Organizations ----------

  final _joinRequests = <String, Set<String>>{}; // org id → user ids

  bool _isMember(UserProfile user, Organization o) =>
      user.tags.any((t) => t.kind == TagKind.organization && t.label == o.name);

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
      society: mockOrganizations
          .where((o) => o.kind == OrgKind.society && _inDepartmentOf(user, o))
          .toList(),
      // Other departments' societies are never listed as school-wide clubs.
      clubs: mockOrganizations.where((o) => o.kind == OrgKind.club).toList(),
      mine: mockOrganizations.where((o) => _isMember(user, o)).toList(),
    );
  }

  @override
  Future<OrganizationPage?> loadOrganization(UserProfile user, String orgId) async {
    await _wait();
    final o = mockOrganizations.where((o) => o.id == orgId).firstOrNull;
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
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
