import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/campus.dart';
import 'package:michaelean_app/services/campus_service.dart';

void main() {
  // 10:00 on a fixed day.
  final morning = DateTime(2026, 10, 20, 10, 0);
  final service = MockCampusService(delay: Duration.zero, clock: () => morning);

  test('students see only published events they are eligible for, soonest first', () async {
    final events = await service.loadUpcomingEvents(mockStudent);
    final ids = events.map((e) => e.id).toList();
    expect(ids, ['ev1', 'ev2', 'ev3', 'ev4', 'ev5']);
    expect(ids, isNot(contains('ev6'))); // Dance Company: not a member
    expect(ids, isNot(contains('ev7'))); // draft
  });

  test('managed events: only the teacher\'s own, drafts included', () async {
    final events = await service.loadManagedEvents(mockTeacher);
    expect(events.map((e) => e.id), ['ev2', 'ev7']);
    expect(events.last.status, EventStatus.draft);
    expect(await service.loadManagedEvents(mockStudent), isEmpty); // no permission
  });

  test('organizations come from confirmed membership tags', () async {
    final orgs = await service.loadMyOrganizations(mockStudent);
    expect(orgs.map((o) => o.name), ['Computer Science Society', 'SMCL Chorale']);
    expect(await service.loadMyOrganizations(mockTeacher), isEmpty);
  });

  test('clearance: active for the student; no office without permission', () async {
    final c = await service.loadClearance(mockStudent);
    expect(c!.cleared, 3);
    expect(c.total, 6);
    expect(await service.loadClearance(mockTeacher), isNull);
    expect(await service.loadClearanceOffice(mockTeacher), isNull);
  });

  test('classes: today (also ended ones) and later, in time order', () async {
    final classes = await service.loadClasses(mockStudent);
    expect(classes.map((c) => c.id), ['s1', 's2', 's3', 's4']);
  });
}
