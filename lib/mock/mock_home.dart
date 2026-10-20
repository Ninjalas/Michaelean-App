// MOCK DATA — sample Home content for the frontend prototype.
// Post text is invented. Images are real SMCL posters used for illustration
// only; the text does not describe those real events.

import '../models/feed.dart';

const _css = 'Computer Science Society';
const _dcs = 'Department of Computer Studies';
const _cssLogo = 'assets/images/profiles/css_profile.jpg';

List<Post> mockPosts(DateTime now) => [
      // Announcements — everyone
      Post(
        id: 'a1',
        kind: PostKind.announcement,
        title: 'Midterm examination schedule posted',
        body: 'Sample announcement. The midterm examination schedule is now '
            'available. Check with your instructors for room assignments.',
        source: "Registrar's Office",
        publishedAt: now.subtract(const Duration(hours: 2)),
      ),
      Post(
        id: 'a2',
        kind: PostKind.announcement,
        title: 'Updated campus map for the new semester',
        body: 'Sample announcement. Use the updated map to find halls, the '
            'library commons, and the conference center.',
        source: 'Campus Services',
        imageAsset: 'assets/images/SMCL_MAP.png',
        publishedAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      Post(
        id: 'a3',
        kind: PostKind.announcement,
        title: 'Reminder: wear your school ID on campus',
        body: 'Sample announcement. Please keep your school ID visible while on '
            'campus.',
        source: 'Office of Student Affairs',
        publishedAt: now.subtract(const Duration(days: 2)),
      ),
      Post(
        id: 'a4',
        kind: PostKind.announcement,
        title: 'Enrollment for next semester opens soon',
        body: 'Sample announcement. Watch for the enrollment schedule for your '
            'school and year level.',
        source: "Registrar's Office",
        publishedAt: now.subtract(const Duration(days: 3, hours: 2)),
      ),

      // School news — everyone
      Post(
        id: 'n1',
        kind: PostKind.schoolNews,
        title: 'Students learn the basics of pitching a start-up',
        body: 'Sample story. A talk for students covered how to shape an idea '
            'into a pitch, what investors look for, and common first mistakes.',
        source: 'SMCL News',
        imageAsset: 'assets/images/events/css_startupevent.jpg',
        publishedAt: now.subtract(const Duration(hours: 5)),
      ),
      Post(
        id: 'n2',
        kind: PostKind.schoolNews,
        title: 'Machine learning session works through a classic dataset',
        body: 'Sample story. Participants explored a well-known dataset step by '
            'step using Python.',
        source: 'SMCL News',
        imageAsset: 'assets/images/events/css_unpackingevent.jpg',
        publishedAt: now.subtract(const Duration(days: 3)),
      ),
      Post(
        id: 'n3',
        kind: PostKind.schoolNews,
        title: 'Library commons extends evening hours',
        body: 'Sample story. The library commons will stay open later on '
            'weekdays during exam weeks.',
        source: 'SMCL News',
        publishedAt: now.subtract(const Duration(days: 4)),
      ),
      Post(
        id: 'n4',
        kind: PostKind.schoolNews,
        title: 'Students join a campus tree-planting drive',
        body: 'Sample story. Volunteers from every school planted seedlings '
            'around the campus grounds.',
        source: 'SMCL News',
        publishedAt: now.subtract(const Duration(days: 5)),
      ),

      // For You — matched by audience
      Post(
        id: 'o1',
        kind: PostKind.organizationNews,
        title: "Venue change for Friday's general meeting",
        body: "Sample post. Friday's meeting moves to Milagros Limaco Hall. "
            'Same time.',
        source: _css,
        sourceImage: _cssLogo,
        publishedAt: now.subtract(const Duration(hours: 1)),
        urgent: true,
        audience: _css,
      ),
      Post(
        id: 'o2',
        kind: PostKind.organizationNews,
        title: 'Recap: hands-on Git and collaboration seminar',
        body: 'Sample post. Members practiced committing, pushing, and working '
            'together on a shared repository.',
        source: _css,
        sourceImage: _cssLogo,
        imageAsset: 'assets/images/events/css_commitevent.jpg',
        publishedAt: now.subtract(const Duration(days: 1)),
        audience: _css,
      ),
      Post(
        id: 'd1',
        kind: PostKind.departmentNews,
        title: 'Thesis proposal consultation hours',
        body: 'Sample post. Faculty consultation slots for thesis proposals are '
            'open this week.',
        source: _dcs,
        publishedAt: now.subtract(const Duration(hours: 20)),
        audience: _dcs,
      ),
      Post(
        id: 'e1',
        kind: PostKind.eventUpdate,
        title: 'Coding challenge registration closes Friday',
        body: 'Sample update. Registration for the society coding challenge '
            'closes this Friday.',
        source: _css,
        sourceImage: _cssLogo,
        publishedAt: now.subtract(const Duration(days: 2, hours: 4)),
        audience: _css,
      ),
      Post(
        id: 'e2',
        kind: PostKind.eventUpdate,
        title: 'Department assembly moved to Friday afternoon',
        body: 'Sample update. The Department of Computer Studies assembly is '
            'now on Friday at 2:00 PM in Saint Mary\'s Conference Center.',
        source: _dcs,
        publishedAt: now.subtract(const Duration(hours: 9)),
        audience: _dcs,
      ),
      // Schedule and classroom changes (teacher Home)
      Post(
        id: 'c1',
        kind: PostKind.scheduleChange,
        title: 'CS 302 moves to Milagros Limaco 207 on Thursday',
        body: 'Sample change. Thursday\'s CS 302 session will be held in '
            'Milagros Limaco 207 instead of the usual room.',
        source: _dcs,
        publishedAt: now.subtract(const Duration(hours: 7)),
        audience: _dcs,
      ),
      // Not for Nicolas — other affiliations. Must be filtered out.
      Post(
        id: 'x1',
        kind: PostKind.departmentNews,
        title: 'Clinical duty schedule released',
        body: 'Sample post for nursing students.',
        source: 'School of Nursing',
        publishedAt: now.subtract(const Duration(hours: 3)),
        audience: 'SON',
      ),
      Post(
        id: 'x2',
        kind: PostKind.organizationNews,
        title: 'Dance Company auditions',
        body: 'Sample post for Dance Company members.',
        source: 'Dance Company',
        publishedAt: now.subtract(const Duration(hours: 4)),
        urgent: true,
        audience: 'Dance Company',
      ),
    ];

const mockTasks = [
  PendingTask(
    id: 't1',
    title: 'Library clearance',
    detail: 'Receipt photo is unreadable. Resubmit a clearer copy.',
    status: TaskStatus.needsCorrection,
  ),
  PendingTask(
    id: 't2',
    title: 'Event requirements',
    detail: '3 of 6 cleared. Attend 3 more required events.',
    status: TaskStatus.actionRequired,
  ),
];

const mockAttendance = AttendanceSummary(
  classPercent: 92,
  eventPercent: 80,
  eventsCompleted: 5,
  requirementsCleared: 3,
  requirementsTotal: 6,
);

/// Nicolas Santos's classes: three today, one tomorrow, at fixed hours.
/// Teacher names are invented sample data.
List<ClassSession> mockStudentClasses(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int dayOffset, int hour, int minute) =>
      today.add(Duration(days: dayOffset, hours: hour, minutes: minute));
  return [
    ClassSession(
      id: 's1',
      subject: 'CS 305 · Software Engineering',
      section: 'BSCS 3A',
      start: at(0, 7, 30),
      end: at(0, 9, 0),
      room: 'Saint Theodore Hall · Lab 1',
      teacher: 'Ana Reyes',
    ),
    ClassSession(
      id: 's2',
      subject: 'CS 302 · Algorithms',
      section: 'BSCS 3A',
      start: at(0, 10, 30),
      end: at(0, 12, 0),
      room: 'Segunda Limaco Hall · 301',
      teacher: 'Mark Villanueva',
    ),
    ClassSession(
      id: 's3',
      subject: 'GE 104 · Ethics',
      section: 'BSCS 3A',
      start: at(0, 13, 0),
      end: at(0, 14, 30),
      room: 'Pura Limaco Hall I · 110',
      teacher: 'Jose Cruz',
    ),
    ClassSession(
      id: 's4',
      subject: 'CS 305 · Software Engineering',
      section: 'BSCS 3A',
      start: at(1, 7, 30),
      end: at(1, 9, 0),
      room: 'Saint Theodore Hall · Lab 1',
      teacher: 'Ana Reyes',
    ),
  ];
}

/// Mark Villanueva's classes: three today, one tomorrow, at fixed hours.
List<ClassSession> mockTeacherClasses(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int dayOffset, int hour, int minute) =>
      today.add(Duration(days: dayOffset, hours: hour, minutes: minute));
  return [
    ClassSession(
      id: 'k1',
      subject: 'CS 301 · Data Structures',
      section: 'BSCS 2A',
      start: at(0, 7, 30),
      end: at(0, 9, 0),
      room: 'Pura Limaco Hall I · 204',
      // Scanned during class but not finalized yet; only once the class is over.
      awaitingFinalization: now.isAfter(at(0, 9, 0)),
    ),
    ClassSession(
      id: 'k2',
      subject: 'CS 302 · Algorithms',
      section: 'BSCS 3A',
      start: at(0, 10, 30),
      end: at(0, 12, 0),
      room: 'Segunda Limaco Hall · 301',
    ),
    ClassSession(
      id: 'k3',
      subject: 'CS 310 · Web Development',
      section: 'BSCS 3B',
      start: at(0, 13, 0),
      end: at(0, 14, 30),
      room: 'Saint Theodore Hall · Lab 2',
    ),
    ClassSession(
      id: 'k4',
      subject: 'CS 301 · Data Structures',
      section: 'BSCS 2A',
      start: at(1, 9, 0),
      end: at(1, 10, 30),
      room: 'Pura Limaco Hall I · 204',
    ),
  ];
}

const mockTeacherTasks = [
  PendingTask(
    id: 't3',
    title: 'Review schedule change',
    detail: 'CS 302 on Thursday: confirm the new room.',
    status: TaskStatus.actionRequired,
  ),
];

const mockUpcomingEventCount = 2;

List<AppNotification> mockTeacherNotifications(DateTime now) => [
      AppNotification(
        id: 'm5',
        kind: NotificationKind.schedule,
        title: 'Schedule change: CS 302 moves to Milagros Limaco 207 on Thursday',
        time: now.subtract(const Duration(hours: 7)),
        postId: 'c1',
      ),
      AppNotification(
        id: 'm6',
        kind: NotificationKind.schedule,
        title: 'Department assembly moved to Friday afternoon',
        time: now.subtract(const Duration(hours: 9)),
        postId: 'e2',
      ),
      AppNotification(
        id: 'm7',
        kind: NotificationKind.attendance,
        title: 'CS 301 attendance is waiting to be finalized',
        time: now.subtract(const Duration(hours: 11)),
      ),
    ];

List<AppNotification> mockNotifications(DateTime now) => [
      AppNotification(
        id: 'm1',
        kind: NotificationKind.organization,
        title: "Computer Science Society: Venue change for Friday's meeting",
        time: now.subtract(const Duration(hours: 1)),
        postId: 'o1',
      ),
      AppNotification(
        id: 'm2',
        kind: NotificationKind.announcement,
        title: 'New announcement: Midterm examination schedule posted',
        time: now.subtract(const Duration(hours: 2)),
        postId: 'a1',
      ),
      AppNotification(
        id: 'm3',
        kind: NotificationKind.clearance,
        title: 'Library clearance needs correction',
        time: now.subtract(const Duration(hours: 6)),
      ),
      AppNotification(
        id: 'm4',
        kind: NotificationKind.organization,
        title: 'Recap posted: hands-on Git and collaboration seminar',
        time: now.subtract(const Duration(days: 1)),
        postId: 'o2',
      ),
    ];
