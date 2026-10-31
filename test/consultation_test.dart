// Consultations (decided 2026-10-30): teachers fill in a reason/intervention
// form with a student, signatures are uploaded photos (the student's is added
// when they show their QR), only the two of them see it, and it exports as a
// filled-in Excel form.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel_plus/excel_plus.dart' as xl;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:michaelean_app/main.dart';
import 'package:michaelean_app/mock/mock_users.dart';
import 'package:michaelean_app/models/consultation.dart';
import 'package:michaelean_app/models/user_profile.dart';
import 'package:michaelean_app/services/campus_service.dart';
import 'package:michaelean_app/services/home_service.dart';
import 'package:michaelean_app/services/photo_store.dart';
import 'package:michaelean_app/services/user_service.dart';
import 'package:michaelean_app/widgets/post_image.dart';
import 'package:michaelean_app/utils/consultation_excel.dart';

final _png = Uint8List.fromList(File('assets/images/SMCL_Emblem.png').readAsBytesSync());

void main() {
  late MockCampusService s;
  setUp(() async {
    s = MockCampusService(delay: Duration.zero);
    await s.saveSignature(mockTeacher, 'upload:teacher');
  });

  Future<Consultation> start({bool scanned = false}) => s.saveConsultation(mockTeacher,
      studentId: mockStudent.id,
      rows: [(reason: 'Late submissions', intervention: 'Set weekly check-ins')],
      expectedOutcome: 'Submits on time',
      scanned: scanned);

  group('service', () {
    test('scanning the QR adds both saved signatures', () async {
      await s.saveSignature(mockStudent, 'upload:student');
      final c = await start(scanned: true);
      expect((c.studentSignature, c.teacherSignature), ('upload:student', 'upload:teacher'));
      expect(c.studentSigned, isTrue);
    });

    test('found by name: unsigned until the student shows their QR', () async {
      await s.saveSignature(mockStudent, 'upload:student');
      final c = await start();
      expect(c.studentSigned, isFalse);
      expect(() => s.signConsultation(mockTeacher, c.id, 'stu-BSCS3A1'), throwsStateError);
      final signed = await s.signConsultation(mockTeacher, c.id, mockStudent.id);
      expect(signed.studentSignature, 'upload:student');
    });

    test('a teacher without an e-signature cannot start one', () async {
      await s.saveSignature(mockTeacher, null);
      expect(() => start(), throwsStateError);
    });

    test('a form keeps its signatures through edits and Settings changes', () async {
      await s.saveSignature(mockStudent, 'upload:student');
      final c = await start(scanned: true);
      await s.saveSignature(mockTeacher, 'upload:new');
      var edited = await s.saveConsultation(mockTeacher,
          id: c.id, studentId: c.studentId, rows: c.rows, expectedOutcome: 'Changed');
      expect(edited.teacherSignature, 'upload:teacher');
      // Removing it in Settings stops new forms, not edits to this one.
      await s.saveSignature(mockTeacher, null);
      await s.saveSignature(mockStudent, null);
      edited = await s.saveConsultation(mockTeacher,
          id: c.id, studentId: c.studentId, rows: c.rows, expectedOutcome: 'Again');
      expect((edited.teacherSignature, edited.studentSignature), ('upload:teacher', 'upload:student'));
    });

    test("a student's QR signs only with an e-signature on file", () async {
      final scanned = await start(scanned: true); // Nicolas has none yet
      expect(scanned.studentSigned, isFalse);
      expect(() => s.signConsultation(mockTeacher, scanned.id, mockStudent.id), throwsStateError);
      await s.saveSignature(mockStudent, 'upload:student');
      expect((await s.signConsultation(mockTeacher, scanned.id, mockStudent.id)).studentSigned,
          isTrue);
    });

    test('editing after signing is allowed and marked', () async {
      await s.saveSignature(mockStudent, 'upload:student');
      final c = await start(scanned: true);
      final edited = await s.saveConsultation(mockTeacher,
          id: c.id, studentId: c.studentId, rows: c.rows, expectedOutcome: 'Changed');
      expect(edited.studentSigned, isTrue);
      expect(edited.editedAfterSigning, isTrue);
    });

    test('only the teacher and the student see it; rows are checked', () async {
      final c = await start();
      expect(await s.loadConsultation(mockStudent, c.id), isNotNull);
      const other = UserProfile(
          id: 'stu-BSCS3A1', role: UserRole.student, firstName: 'Andrea', lastName: 'Bautista',
          designation: 'BSCS 3A', maskedId: '', email: '', qrToken: '', tags: []);
      expect(await s.loadConsultation(other, c.id), isNull);
      expect((await s.loadConsultations(mockStudent)).map((c) => c.id), contains(c.id));
      expect(
          () => s.saveConsultation(mockTeacher,
              studentId: mockStudent.id,
              rows: [(reason: '', intervention: 'Only an intervention')],
              expectedOutcome: ''),
          throwsArgumentError);
      expect(
          () => s.saveConsultation(mockStudent,
              studentId: mockStudent.id,
              rows: [(reason: 'x', intervention: 'y')],
              expectedOutcome: ''),
          throwsStateError); // students can't hold consultations
    });
  });

  test('the Excel form has the header, the table, and the signature pictures', () async {
    await s.saveSignature(mockStudent, 'upload:student');
    final c = await start(scanned: true);
    final bytes = consultationWorkbook(c, photo: (_) => _png);
    final sheet = xl.Excel.decodeBytes(bytes)['Consultation'];
    final text = [
      for (final row in sheet.rows)
        for (final cell in row)
          if (cell?.value case final v?) v.toString(),
    ];
    expect(text, containsAll([
      'CONSULTATION FORM',
      'Nicolas Santos · BSCS 3A',
      mockStudent.maskedId,
      'Reason/s for Consultation',
      'Intervention Made',
      'Late submissions',
      'Set weekly check-ins',
      'Submits on time',
      'Mark Villanueva',
    ]));
    expect(sheet.images, hasLength(2)); // both signatures

    // Pinned by two corners so iPhone's Files preview places them too
    // (found 2026-10-31); also after the download's round trip.
    for (final file in [bytes, xl.Excel.decodeBytes(bytes).encode()!]) {
      final drawing = utf8.decode(ZipDecoder()
          .decodeBytes(file)
          .files
          .singleWhere((f) => f.name == 'xl/drawings/drawing1.xml')
          .content);
      expect(drawing, isNot(contains('oneCellAnchor')));
      final from = RegExp(r'<xdr:from><xdr:col>(\d+)</xdr:col><xdr:colOff>0</xdr:colOff>'
              r'<xdr:row>(\d+)</xdr:row>')
          .allMatches(drawing)
          .map((m) => (m[1], m[2]))
          .toList();
      // Under "Student Signature" (A) and "Instructor/Professor Signature" (C).
      final labelRow = sheet.rows.indexWhere((r) => r.first?.value.toString() == 'Student Signature');
      expect(from, [('0', '${labelRow + 1}'), ('2', '${labelRow + 1}')]);
    }
    expect(consultationFileName(c), startsWith('Consultation_Nicolas_Santos_'));
  });

  group('screens', () {
    /// Signs in as [role] and opens [path]. [setUp] prepares the data first;
    /// by default the teacher has an e-signature.
    Future<GoRouter> open(WidgetTester tester, String role, String path,
        {Future<void> Function(MockCampusService)? setUp}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final campus = MockCampusService(delay: Duration.zero);
      await tester.runAsync(() => setUp != null
          ? setUp(campus)
          : campus.saveSignature(mockTeacher, 'upload:teacher'));
      await tester.pumpWidget(MichaeleanApp(
        userService: MockUserService(campus: campus),
        homeService: MockHomeService(delay: Duration.zero, campus: campus),
        campusService: campus,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text(role));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with Microsoft (preview)'));
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.push(path);
      await tester.pumpAndSettle();
      return router;
    }

    Future<void> fillAndSave(WidgetTester tester) async {
      await tester.enterText(find.widgetWithText(TextField, 'Reason for consultation'), 'Absences');
      await tester.enterText(find.widgetWithText(TextField, 'Intervention made'), 'Make-up plan');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('scan the QR, fill in the form: saved and signed', (tester) async {
      await open(tester, 'Teacher', '/life/consultations', setUp: (campus) async {
        await campus.saveSignature(mockTeacher, 'upload:teacher');
        await campus.saveSignature(mockStudent, 'upload:student');
      });
      await tester.tap(find.byTooltip('New consultation'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mock scanner'), findsOneWidget);
      await tester.tap(find.text("Nicolas Santos's QR"));
      await tester.pumpAndSettle();
      expect(find.textContaining('QR scanned'), findsOneWidget);
      await fillAndSave(tester);
      expect(find.text('Saved and signed in this preview only.'), findsOneWidget);
      expect(find.text('Absences'), findsOneWidget); // the saved form
      expect(find.text('Scan QR to Sign'), findsNothing);
      expect(find.text('Export to Excel'), findsOneWidget);
    });

    testWidgets('found by name: unsigned, then signed with the right QR', (tester) async {
      await open(tester, 'Teacher', '/life/consultations/new');
      await tester.tap(find.text('Find the student by name instead'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Aira');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aira Domingo'));
      await tester.pumpAndSettle();
      await fillAndSave(tester);
      expect(find.textContaining('Not signed yet'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5)); // the snackbar over the buttons goes away
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan QR to Sign'));
      await tester.pumpAndSettle();
      // Someone else's QR doesn't sign it.
      final other = find.byWidgetPredicate(
          (w) => w is ActionChip && !(w.label as Text).data!.startsWith('Aira'));
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(find.textContaining("This QR isn't Aira Domingo's"), findsOneWidget);
      // Aira has no e-signature yet, so her QR can't sign it.
      await tester.tap(find.text("Aira Domingo's QR"));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aira Domingo needs to add an e-signature first'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Scan QR to Sign'), findsOneWidget); // still unsigned
    });

    testWidgets('no e-signature: asked to add one first, then the scanner', (tester) async {
      final real = PhotoStore.picker;
      PhotoStore.picker = ({required int limit, required bool camera}) async => [_png];
      addTearDown(() => PhotoStore.picker = real);
      await open(tester, 'Teacher', '/life/consultations', setUp: (_) async {});
      await tester.tap(find.byTooltip('New consultation'));
      await tester.pumpAndSettle();
      expect(find.text('Add your e-signature before starting a consultation.'), findsOneWidget);
      expect(find.textContaining('Mock scanner'), findsNothing);

      await tester.tap(find.text('Add e-signature'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload signature'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mock scanner'), findsOneWidget);
    });

    testWidgets('students read their consultations; no editing', (tester) async {
      await open(tester, 'Student', '/life/consultations', setUp: (campus) async {
        await campus.saveSignature(mockTeacher, 'upload:teacher');
        await campus.saveConsultation(mockTeacher,
            studentId: mockStudent.id,
            rows: [(reason: 'Missed two CS 302 labs', intervention: 'Make-up schedule')],
            expectedOutcome: '');
      });
      expect(find.text('Mark Villanueva'), findsOneWidget);
      await tester.tap(find.text('Mark Villanueva'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Missed two CS 302 labs'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Export to Excel'), findsNothing);
    });

    testWidgets('upload an e-signature in Settings', (tester) async {
      final real = PhotoStore.picker;
      PhotoStore.picker = ({required int limit, required bool camera}) async => [_png];
      addTearDown(() => PhotoStore.picker = real);
      await open(tester, 'Student', '/profile/signature');
      expect(find.text('No e-signature yet'), findsOneWidget);
      await tester.tap(find.text('Upload signature'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
      expect(PhotoStore.isUpload(tester.widget<PostImage>(find.byType(PostImage)).path), isTrue);
      expect(find.text('Change signature'), findsOneWidget);
      expect(find.textContaining("Couldn't save"), findsNothing); // saving really worked
    });
  });
}
