// School News and department news hold real posts from SMCL's and the
// Computer Science Society's Facebook pages: bold captions,
// navy hashtags, several photos in one post, and dates shown as "3h ago"
// within the last day, else the date (decided 2026-10-26).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_home.dart';
import 'package:michaelean_app/models/feed.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/theme/app_theme.dart';
import 'package:michaelean_app/utils/dates.dart';
import 'package:michaelean_app/widgets/rich_caption.dart';

void main() {
  group('post times', () {
    final now = DateTime(2026, 10, 26, 12);
    test('within about a day: how long ago', () {
      expect(formatTimeAgo(now.subtract(const Duration(seconds: 30)), now), 'Just now');
      expect(formatTimeAgo(now.subtract(const Duration(minutes: 5)), now), '5m ago');
      expect(formatTimeAgo(now.subtract(const Duration(hours: 3)), now), '3h ago');
      expect(formatTimeAgo(now.subtract(const Duration(hours: 30)), now), '1d ago');
    });
    test('older: the date, with the year only when it is not this year', () {
      expect(formatTimeAgo(DateTime(2026, 10, 16, 15), now), '16 October');
      expect(formatTimeAgo(DateTime(2025, 12, 1), now), '1 December 2025');
    });
  });

  test('School News: the seven real SMCL posts, newest first, photos all present', () {
    final news = mockPosts(DateTime(2026, 10, 26))
        .where((p) => p.kind == PostKind.schoolNews)
        .toList();
    expect(news.length, 7);
    // The hackathon win is the newest, so it's Home's featured story.
    expect(news.first.title, 'MICHAELEAN INNOVATION AND EXCELLENCE');
    for (var i = 1; i < news.length; i++) {
      expect(news[i].publishedAt.isBefore(news[i - 1].publishedAt), isTrue, reason: news[i].title);
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final p in news) {
      expect(p.source, "Saint Michael's College of Laguna");
      expect(p.sourceImage, 'assets/images/SMCL_Emblem.png');
      expect(p.images, isNotEmpty, reason: p.title);
      for (final img in p.images) {
        expect(File(img).existsSync(), isTrue, reason: img);
        expect(pubspec, contains('- $img'), reason: '$img is declared');
      }
    }
    // The two psychology posts became one with both photos.
    final psych = news.singleWhere((p) => p.id == 'n-psychometricians');
    expect(psych.images, [
      'assets/images/news/psychometricians_just_in.jpg',
      'assets/images/news/psychometricians_100.jpg',
    ]);
  });

  test('department news: the four real posts, for DCS students, photos all present', () {
    final posts = mockPosts(DateTime(2026, 10, 26));
    final dcs = posts.where((p) => p.id.startsWith('d-')).toList();
    expect(dcs.map((p) => p.title), [
      'HUEFEST: THE PLAYLIST OF OUR GENERATION',
      'LEVEL UP YOUR IDEAS, CREATE YOUR FUTURE!',
      'LOOK: ANGELIC INNOVATORS ARE 1ST RUNNER-UP AT THE 24-HOUR HACKATHON',
      'A PROUD MOMENT TO CELEBRATE!',
    ]);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final p in dcs) {
      expect(p.kind, PostKind.departmentNews);
      expect(p.source, 'Department of Computer Studies');
      expect(p.audience, 'Department of Computer Studies');
      for (final img in p.images) {
        expect(File(img).existsSync(), isTrue, reason: img);
        expect(pubspec, contains('- $img'), reason: '$img is declared');
      }
    }
    // The invented text-only posts are gone; the urgent notice and the room
    // change stay as samples of those features.
    final ids = posts.map((p) => p.id);
    expect(ids, isNot(contains('d1')));
    expect(ids, isNot(contains('e1')));
    expect(ids, isNot(contains('e2')));
    expect(ids, containsAll(['o1', 'c1']));
  });

  testWidgets('links show in navy (not tappable in this preview)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: RichCaption('Submit here: https://forms.gle/abc 🔗')),
    ));
    final outer = tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
    final spans = (outer.children!.single as TextSpan).children!.cast<TextSpan>();
    final link = spans.singleWhere((s) => s.text == 'https://forms.gle/abc');
    expect(link.style?.color, AppColors.navy);
    expect(link.recognizer, isNull);
  });

  testWidgets('a caption shows **bold** parts bold and #hashtags in navy', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: RichCaption('Congratulations to the **ARCHANGELS**! #MichaeleanPride')),
    ));
    // Text.rich wraps the caption's span in one outer span.
    final outer = tester.widget<RichText>(find.byType(RichText)).text as TextSpan;
    final spans = (outer.children!.single as TextSpan).children!.cast<TextSpan>();
    expect(spans.map((s) => s.text), ['Congratulations to the ', 'ARCHANGELS', '! ', '#MichaeleanPride']);
    expect(spans[1].style?.fontWeight, FontWeight.w700);
    expect(spans[3].style?.color, AppColors.navy);
    expect(find.textContaining('**'), findsNothing); // the markers never show
  });

  testWidgets('the psychology post swipes between its two photos', (tester) async {
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
    await tester.tap(find.text('Open preview'));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/home/post/n-psychometricians');
    await tester.pumpAndSettle();
    expect(find.text('MICHAELEAN EXCELLENCE IN PSYCHOLOGY'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
  });
}
