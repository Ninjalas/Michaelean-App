import 'feed.dart';

/// A class on the weekly timetable (spec §7.1, §9.1). Times are minutes
/// after midnight, e.g. 7:30 AM = 450.
class ClassInfo {
  final String id;
  final String subject;
  final String section; // e.g. "BSCS 3A"; students in it take this class
  final String room;
  final String teacherId; // assigned teacher (spec §12: assignment, not title)
  final String teacherName;
  final List<int> weekdays; // DateTime.monday … DateTime.saturday
  final int startMinute;
  final int endMinute;

  const ClassInfo({
    required this.id,
    required this.subject,
    required this.section,
    required this.room,
    required this.teacherId,
    required this.teacherName,
    required this.weekdays,
    required this.startMinute,
    required this.endMinute,
  });
}

/// A student on a class roster. QR content is a random mock token only.
class RosterStudent {
  final String id;
  final String name;
  final String maskedId;
  final String qrToken;
  final String? photoAsset;

  const RosterStudent({
    required this.id,
    required this.name,
    required this.maskedId,
    required this.qrToken,
    this.photoAsset,
  });
}

enum AttendanceMark { present, absent }

/// One finalized attendance record for a student. Only finalized sessions
/// produce records, so percentages never count unfinished ones (spec §7.2).
class AttendanceRecord {
  final ClassSession session;
  final AttendanceMark mark;

  const AttendanceRecord({required this.session, required this.mark});
}

/// The attendance state of one session, for the teacher's scanner and review.
class SessionAttendance {
  final ClassSession session;
  final List<RosterStudent> roster;
  final Set<String> presentIds;

  const SessionAttendance({
    required this.session,
    required this.roster,
    required this.presentIds,
  });

  int get presentCount => presentIds.length;
  int get uncheckedCount => roster.length - presentIds.length;
  List<RosterStudent> get unchecked =>
      roster.where((s) => !presentIds.contains(s.id)).toList();
}

/// What a scan did (spec §7.2). Only [present] changes anything.
enum ScanOutcome { present, duplicate, notEnrolled, notOpenYet, closed }

class ScanResult {
  final ScanOutcome outcome;
  final RosterStudent? student; // set for present and duplicate

  const ScanResult(this.outcome, [this.student]);
}

/// Everything the teacher's class page shows.
class ClassDetail {
  final ClassInfo info;
  final List<RosterStudent> roster;
  final ClassSession? current; // today's session, else the next one
  final List<SessionSummary> recent; // past sessions, newest first

  const ClassDetail({
    required this.info,
    required this.roster,
    required this.current,
    required this.recent,
  });
}

class SessionSummary {
  final ClassSession session;
  final int present;
  final int total;

  const SessionSummary({required this.session, required this.present, required this.total});
}
