import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/feed.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';

Future<void> signIn(WidgetTester tester, String role, {MockHomeService? home}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final campus = MockCampusService(delay: Duration.zero);
  await tester.pumpWidget(MichaeleanApp(
    userService: MockUserService(),
    homeService: home ?? MockHomeService(delay: Duration.zero, campus: campus),
    campusService: campus,
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
}

/// Opens the + menu and picks [option].
Future<void> compose(WidgetTester tester, String option) async {
  await tester.tap(find.byTooltip('Create post'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('students get no + button', (tester) async {
    await signIn(tester, 'Student');
    expect(find.byTooltip('Create post'), findsNothing);
  });

  testWidgets('the + menu opens, shows three options, and closes', (tester) async {
    await signIn(tester, 'Teacher');
    await tester.tap(find.byTooltip('Create post'));
    await tester.pumpAndSettle();
    // Inside the menu (Home has its own "School News" section behind it).
    final menu = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Option');
    for (final o in ['Announcement', 'School News', 'Campus update']) {
      expect(find.descendant(of: menu, matching: find.text(o)), findsOneWidget);
    }
    await tester.binding.handlePopRoute(); // Android / browser Back closes it
    await tester.pumpAndSettle();
    expect(find.text('Campus update'), findsNothing);
    expect(find.byTooltip('Create post'), findsOneWidget);
  });

  testWidgets('post an urgent announcement; honest message; it shows on Home', (tester) async {
    await signIn(tester, 'Teacher');
    await compose(tester, 'Announcement');
    expect(find.text('New Announcement'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Post')).onPressed,
        isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Lab closed on Monday');
    await tester.enterText(
        find.widgetWithText(TextField, 'What should people know?'), 'Room 207 is being fixed.');
    await tester.tap(find.text('Mark as urgent'));
    await tester.pumpAndSettle();
    // Send it to one class only.
    await tester.tap(find.text('Everyone at SMCL').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CS 310 · Web Development · BSCS 3B').last);
    await tester.pumpAndSettle();
    expect(find.text('Just now · CS 310 · Web Development · BSCS 3B'), findsOneWidget); // preview
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Its audience gets a notification in this preview'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lab closed on Monday'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Lab closed on Monday'), findsOneWidget);
    expect(find.text('URGENT'), findsWidgets);
  });

  testWidgets('edit and delete your own post', (tester) async {
    await signIn(tester, 'Teacher');
    await compose(tester, 'Campus update');
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Robotics club meets today');
    await tester.enterText(
        find.widgetWithText(TextField, 'What should people know?'), 'Room 101 at 4 PM.');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5)); // let the snackbar go
    await tester.pumpAndSettle();

    final row = find.text('Robotics club meets today');
    await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
    // Mid-screen: clear of the pinned navy bar and the nav bar, whatever the feed holds.
    await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Posted in this preview only. Nobody was notified.'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Post'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Robotics club meets today'),
        'Robotics club meets at 5 PM');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Robotics club meets at 5 PM'), findsOneWidget);
    expect(find.textContaining('Edited'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // let the "saved" snackbar go
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Post deleted from this preview.'), findsOneWidget);
    expect(find.text('Robotics club meets at 5 PM'), findsNothing);
  });

  test('who sees a post, and who may post or edit', () async {
    final campus = MockCampusService(delay: Duration.zero);
    final home = MockHomeService(delay: Duration.zero, campus: campus);
    final studentClasses =
        (await campus.loadClasses(mockStudent)).map((c) => c.classId).toSet();
    final teacherClasses = await campus.loadAssignedClasses(mockTeacher);
    final theirs = teacherClasses.firstWhere((c) => studentClasses.contains(c.id));
    final notTheirs = teacherClasses.firstWhere((c) => !studentClasses.contains(c.id));

    Future<Post> post(String title, {String? classId, String? audience}) => home.savePost(
        mockTeacher,
        kind: PostKind.announcement,
        title: title,
        body: 'Sample.',
        classId: classId,
        audience: audience,
        sentTo: 'test');
    await post('For your class', classId: theirs.id);
    await post('For another class', classId: notTheirs.id);
    await post('For another department', audience: 'Department of Nursing');

    final seen = (await home.loadHome(mockStudent)).announcements.map((p) => p.title);
    expect(seen, contains('For your class'));
    expect(seen, isNot(contains('For another class')));
    expect(seen, isNot(contains('For another department')));
    // The author always sees their own posts.
    final mine = (await home.loadHome(mockTeacher)).announcements.map((p) => p.title);
    expect(mine, containsAll(['For your class', 'For another class', 'For another department']));

    // No permission → no post; nobody edits or deletes someone else's post.
    expect(
        () => home.savePost(mockStudent,
            kind: PostKind.announcement, title: 'x', body: 'y', sentTo: 'test'),
        throwsStateError);
    final p = await post('Mine');
    expect(
        () => home.savePost(mockStudent,
            postId: p.id, kind: PostKind.announcement, title: 'x', body: 'y', sentTo: 'test'),
        throwsStateError);
    expect(() => home.deletePost(mockStudent, p.id), throwsStateError);
    expect(() => home.deletePost(mockTeacher, 'a1'), throwsStateError); // a sample post
  });

  testWidgets("a student's bell shows a teacher's urgent announcement", (tester) async {
    final home = MockHomeService(delay: Duration.zero);
    // Real time: widget tests run on a fake clock that only moves when pumped.
    await tester.runAsync(() => home.savePost(mockTeacher,
        kind: PostKind.announcement,
        title: 'Campus closed tomorrow',
        body: 'Sample.',
        urgent: true,
        sentTo: 'Everyone at SMCL'));
    await signIn(tester, 'Student', home: home);
    // 3 sample notices, 2 Connect requests, and this one.
    expect(find.byTooltip('Notifications, 6 unread'), findsOneWidget);

    await tester.tap(find.byTooltip(RegExp('^Notifications')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgent: Campus closed tomorrow'));
    await tester.pumpAndSettle();
    expect(find.text('Campus closed tomorrow'), findsOneWidget); // the post opens
  });

  test('urgent announcements notify their audience; edits and deletes follow', () async {
    final campus = MockCampusService(delay: Duration.zero);
    final home = MockHomeService(delay: Duration.zero, campus: campus);
    final studentClasses =
        (await campus.loadClasses(mockStudent)).map((c) => c.classId).toSet();
    final teacherClasses = await campus.loadAssignedClasses(mockTeacher);
    final theirs = teacherClasses.firstWhere((c) => studentClasses.contains(c.id));
    final notTheirs = teacherClasses.firstWhere((c) => !studentClasses.contains(c.id));
    Future<List<AppNotification>> bell(user) async => (await home.loadNotifications(user))
        .where((n) => n.id.startsWith('post-'))
        .toList();

    final urgent = await home.savePost(mockTeacher,
        kind: PostKind.announcement, title: 'Quiz moved', body: 'Sample.',
        classId: theirs.id, urgent: true, sentTo: 'test');
    await home.savePost(mockTeacher,
        kind: PostKind.announcement, title: 'Other class', body: 'Sample.',
        classId: notTheirs.id, urgent: true, sentTo: 'test');
    await home.savePost(mockTeacher,
        kind: PostKind.announcement, title: 'Not urgent', body: 'Sample.', sentTo: 'test');

    var mine = await bell(mockStudent);
    expect(mine.map((n) => n.title), ['Urgent: Quiz moved']);
    expect(mine.single.read, isFalse);
    expect(await bell(mockTeacher), isEmpty); // the author isn't notified

    // Read it, then the teacher edits: it comes back unread with the new title.
    await home.markNotificationsRead(mockStudent, [mine.single.id]);
    expect((await bell(mockStudent)).single.read, isTrue);
    await home.savePost(mockTeacher,
        postId: urgent.id, kind: PostKind.announcement, title: 'Quiz moved to Friday',
        body: 'Sample.', classId: theirs.id, urgent: true, sentTo: 'test');
    mine = await bell(mockStudent);
    expect(mine.single.title, 'Updated: Quiz moved to Friday');
    expect(mine.single.read, isFalse);

    // Switching Urgent off removes it; so does deleting the post.
    await home.savePost(mockTeacher,
        postId: urgent.id, kind: PostKind.announcement, title: 'Quiz moved to Friday',
        body: 'Sample.', classId: theirs.id, sentTo: 'test');
    expect(await bell(mockStudent), isEmpty);
    final again = await home.savePost(mockTeacher,
        kind: PostKind.announcement, title: 'Fire drill', body: 'Sample.',
        urgent: true, sentTo: 'test');
    expect(await bell(mockStudent), hasLength(1));
    await home.deletePost(mockTeacher, again.id);
    expect(await bell(mockStudent), isEmpty);
  });
}
