// Posts can have up to 4 uploaded photos (decided 2026-10-30): announcements,
// School News, and club posts; not campus updates. Uploads stay in memory.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/feed.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/photo_store.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/widgets/photo_carousel.dart';
import 'package:michaelean_app/widgets/post_image.dart';

final _photo = Uint8List.fromList(File('assets/images/SMCL_Emblem.png').readAsBytesSync());

/// Pretends the user picked [count] photos; records whether the camera was asked.
bool? usedCamera;
void fakePicker(WidgetTester tester, int count) {
  final real = PhotoStore.picker;
  PhotoStore.picker = ({required int limit, required bool camera}) async {
    usedCamera = camera;
    return List.filled(count, _photo);
  };
  addTearDown(() => PhotoStore.picker = real);
}

Future<void> openForm(WidgetTester tester, String option) async {
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
  await tester.tap(find.text('Sign in with Microsoft (preview)'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Create post'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last); // the menu, not Home's section behind it
  await tester.pumpAndSettle();
}

/// The photos in the form's strip, in order.
List<String> strip(WidgetTester tester) => [
      for (final w in tester.widgetList<PostImage>(
          find.descendant(of: find.byType(ReorderableListView), matching: find.byType(PostImage))))
        w.path,
    ];

Future<void> addPhotos(WidgetTester tester, {bool camera = false}) async {
  await tester.ensureVisible(find.bySemanticsLabel('Add photos'));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel('Add photos'));
  await tester.pumpAndSettle();
  // Tests run as a phone, so it asks gallery or camera first.
  await tester.tap(find.text(camera ? 'Take a photo' : 'Choose from gallery'));
  await tester.pumpAndSettle();
}

void main() {
  test('the service keeps the photos in order and refuses more than 4', () async {
    final home = MockHomeService(delay: Duration.zero);
    final p = await home.savePost(mockTeacher,
        kind: PostKind.announcement, title: 'T', body: 'B', sentTo: 'test',
        images: ['upload:a', 'upload:b']);
    expect(p.imageAsset, 'upload:a'); // the cover
    expect(p.images, ['upload:a', 'upload:b']);
    expect(
        () => home.savePost(mockTeacher,
            kind: PostKind.announcement, title: 'T', body: 'B', sentTo: 'test',
            images: List.filled(5, 'upload:a')),
        throwsArgumentError);
  });

  testWidgets('add, remove, and reorder photos; the post shows them', (tester) async {
    fakePicker(tester, 3);
    await openForm(tester, 'Announcement');
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Lab photos');
    await tester.enterText(find.widgetWithText(TextField, 'What should people know?'), 'Sample.');
    await addPhotos(tester);
    expect(usedCamera, isFalse);
    expect(find.text('Photos · 3 of 4'), findsOneWidget);
    final [first, second, third] = strip(tester);

    await tester.tap(find.byTooltip('Remove photo 2'));
    await tester.pumpAndSettle();
    expect(strip(tester), [first, third]);

    // Hold the second photo and drag it in front of the first: it becomes the cover.
    final hold = await tester.startGesture(tester.getCenter(find.byType(PostImage).at(1)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    for (var i = 0; i < 6; i++) {
      await hold.moveBy(const Offset(-20, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await hold.up();
    await tester.pumpAndSettle();
    expect(strip(tester), [third, first]);

    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Lab photos'), 200,
        scrollable: find.byType(Scrollable).first);
    // Clear of the floating nav bar.
    Scrollable.ensureVisible(tester.element(find.text('Lab photos')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lab photos'));
    await tester.pumpAndSettle();
    expect(tester.widget<PhotoCarousel>(find.byType(PhotoCarousel)).images, [third, first]);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('at most 4 photos; then the Add button goes', (tester) async {
    fakePicker(tester, 6);
    await openForm(tester, 'School News');
    await addPhotos(tester, camera: true);
    expect(usedCamera, isTrue);
    expect(strip(tester), hasLength(4));
    expect(find.bySemanticsLabel('Add photos'), findsNothing);
  });

  testWidgets('campus updates stay text only', (tester) async {
    await openForm(tester, 'Campus update');
    expect(find.bySemanticsLabel('Add photos'), findsNothing);
  });
}
