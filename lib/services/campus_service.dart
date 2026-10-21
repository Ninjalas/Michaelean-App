import '../mock/mock_campus.dart';
import '../mock/mock_classes.dart';
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

  /// The student's finalized attendance records, newest first (spec §7.2).
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

  /// Events the user is allowed to manage, including drafts.
  Future<List<CampusEvent>> loadManagedEvents(UserProfile user);

  /// Organizations the user is a confirmed member of.
  Future<List<Organization>> loadMyOrganizations(UserProfile user);

  /// The active clearance period; null when there is none.
  Future<ClearanceSummary?> loadClearance(UserProfile user);

  /// The clearance office the user processes; null when not assigned.
  Future<ClearanceOffice?> loadClearanceOffice(UserProfile user);
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
  Future<List<AttendanceRecord>> loadMyAttendance(UserProfile student) async {
    await _wait();
    final sessions = _sessions(_classesOf(student), _today.subtract(const Duration(days: 21)),
        clock(), forStudent: true);
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

  @override
  Future<List<CampusEvent>> loadUpcomingEvents(UserProfile user) async {
    await _wait();
    final now = clock();
    final myTags = user.tags.map((t) => t.label).toSet();
    return mockEvents(now)
        .where((e) =>
            e.status == EventStatus.published &&
            e.start.isAfter(now) &&
            (e.audience == null || myTags.contains(e.audience)))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<List<CampusEvent>> loadManagedEvents(UserProfile user) async {
    await _wait();
    if (!user.can(Permission.manageEvents)) return const [];
    final now = clock();
    return mockEvents(now)
        .where((e) => e.managerIds.contains(user.id) && e.start.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
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

  @override
  Future<ClearanceSummary?> loadClearance(UserProfile user) async {
    await _wait();
    return mockClearanceFor(user.id, clock());
  }

  @override
  Future<ClearanceOffice?> loadClearanceOffice(UserProfile user) async {
    await _wait();
    if (!user.can(Permission.processClearance)) return null;
    return mockClearanceOffices[user.id];
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
