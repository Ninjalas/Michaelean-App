// Consultations (decided 2026-10-30): teachers fill in a reason/intervention
// form with a student, signatures are uploaded photos (the student's is added
// when they show their QR), only the two of them see it, and signed ones
// export as copies of the official form, two per A4 page, in PDF and Excel.

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
import 'package:michaelean_app/utils/consultation_pdf.dart';

final _png = Uint8List.fromList(File('assets/images/SMCL_Emblem.png').readAsBytesSync());

void main() {
  late MockCampusService s;
  setUp(() async {
    s = MockCampusService(delay: Duration.zero);
    await s.saveSignature(mockTeacher, 'upload:teacher');
  });

  Future<Consultation> start({bool scanned = false}) => s.saveConsultation(mockTeacher,
      studentId: mockStudent.id, department: 'DCS', venue: 'Faculty Room',
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

    test('the official form needs a department and a venue; up to 6 reasons', () async {
      Future<Consultation> save({String department = 'DCS', String venue = 'Room 1', int rows = 1}) =>
          s.saveConsultation(mockTeacher,
              studentId: mockStudent.id,
              department: department,
              venue: venue,
              rows: [for (var i = 0; i < rows; i++) (reason: 'r$i', intervention: '')],
              expectedOutcome: '');
      expect(() => save(department: 'XYZ'), throwsArgumentError);
      expect(() => save(venue: '  '), throwsArgumentError);
      expect((await save(rows: 6)).rows, hasLength(6));
      expect(() => save(rows: 7), throwsArgumentError);
      expect((await save(department: 'SEAS')).department, 'SEAS');
      // Only what fits the printed form.
      expect(() => save(venue: 'x' * (maxConsultationVenueLength + 1)), throwsArgumentError);
      expect(
          () => s.saveConsultation(mockTeacher,
              studentId: mockStudent.id, department: 'DCS', venue: 'Room 1',
              rows: [(reason: 'r', intervention: 'x' * (maxConsultationCellLength + 1))],
              expectedOutcome: ''),
          throwsArgumentError);
      expect(
          () => s.saveConsultation(mockTeacher,
              studentId: mockStudent.id, department: 'DCS', venue: 'Room 1',
              rows: [(reason: 'r', intervention: '')],
              expectedOutcome: 'x' * (maxConsultationOutcomeLength + 1)),
          throwsArgumentError);
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
          id: c.id, studentId: c.studentId, department: 'DCS', venue: 'Faculty Room', rows: c.rows, expectedOutcome: 'Changed');
      expect(edited.teacherSignature, 'upload:teacher');
      // Removing it in Settings stops new forms, not edits to this one.
      await s.saveSignature(mockTeacher, null);
      await s.saveSignature(mockStudent, null);
      edited = await s.saveConsultation(mockTeacher,
          id: c.id, studentId: c.studentId, department: 'DCS', venue: 'Faculty Room', rows: c.rows, expectedOutcome: 'Again');
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
          id: c.id, studentId: c.studentId, department: 'DCS', venue: 'Faculty Room', rows: c.rows, expectedOutcome: 'Changed');
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
              studentId: mockStudent.id, department: 'DCS', venue: 'Faculty Room',
              rows: [(reason: '', intervention: 'Only an intervention')],
              expectedOutcome: ''),
          throwsArgumentError);
      expect(
          () => s.saveConsultation(mockStudent,
              studentId: mockStudent.id, department: 'DCS', venue: 'Faculty Room',
              rows: [(reason: 'x', intervention: 'y')],
              expectedOutcome: ''),
          throwsStateError); // students can't hold consultations
    });
  });

  test('the Excel copy of F-QMS-14: fields, ticked department, form code, pictures', () async {
    await s.saveSignature(mockStudent, 'upload:student');
    final c = await start(scanned: true);
    final bytes = consultationWorkbook([c], photo: (_) => _png);
    final sheet = xl.Excel.decodeBytes(bytes)['Consultation'];
    final text = [
      for (final row in sheet.rows)
        for (final cell in row)
          if (cell?.value case final v?) v.toString(),
    ];
    expect(text, containsAll([
      "SAINT MICHAEL'S COLLEGE OF LAGUNA",
      'OLD NATIONAL ROAD, PLATERO, CITY OF BIÑAN, LAGUNA',
      'ACADEMIC CONSULTATION FORM',
      'Name :', 'Nicolas Santos',
      'Course / Grade :', 'BSCS 3A',
      'Faculty', 'Mark Villanueva',
      'Time:', 'Date:', 'Venue:', 'Faculty Room',
      'Reason/s for Consultation',
      'Intervention Made',
      'Late submissions',
      'Set weekly check-ins',
      'Expected Outcome:',
      'Submits on time',
      "Student's Signature",
      "Instructor's/Professor's Signature",
      'F-QMS-14',
      'Rev5(11/25/24)',
    ]));
    // DCS is ticked; the others are blank. One form fills the top half; the
    // bottom one is blank, nothing ticked.
    final ticks = text.where((t) => t.contains('DHMAC')).toList();
    expect(ticks, hasLength(2));
    expect(ticks.first, contains('_✓_DCS'));
    expect(ticks.first, contains('___DBA'));
    expect(ticks.last, isNot(contains('✓')));
    expect(text.where((t) => t == 'Nicolas Santos'), hasLength(1));
    expect(text.any((t) => t.contains(mockStudent.maskedId)), isFalse); // not on the official form
    // The preview note sits at the foot of the page.
    expect(text.indexWhere((t) => t.contains('Not an official school record')),
        greaterThan(text.indexOf('Rev5(11/25/24)')));
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
      // Just above "Student's Signature" (B) and "Instructor's/Professor's
      // Signature" (D), on the line.
      final labelRow =
          sheet.rows.indexWhere((r) => r.first?.value.toString() == "Student's Signature");
      expect(from, [('1', '${labelRow - 1}'), ('3', '${labelRow - 1}')]);
    }
    expect(consultationFileName([c], 'xlsx'), startsWith('Consultation_Nicolas_Santos_'));
  });

  group('two forms per A4 page', () {
    /// Three signed consultations, saved a day apart in this order.
    Future<List<Consultation>> three() async {
      var day = DateTime(2026, 10, 1);
      s = MockCampusService(delay: Duration.zero, clock: () => day = day.add(const Duration(days: 1)));
      await s.saveSignature(mockTeacher, 'upload:teacher');
      await s.saveSignature(mockStudent, 'upload:student');
      return [
        for (final reason in ['First', 'Second', 'Third'])
          await s.saveConsultation(mockTeacher,
              studentId: mockStudent.id, department: 'DCS', venue: 'Room 1',
              rows: [(reason: reason, intervention: 'Plan')], expectedOutcome: '', scanned: true),
      ];
    }

    test('Excel: oldest first, two per A4 page, a blank form at the end', () async {
      final list = await three();
      final sheet =
          xl.Excel.decodeBytes(consultationWorkbook(list.reversed.toList(), photo: (_) => _png))['Consultation'];
      final text = [
        for (final row in sheet.rows)
          for (final cell in row)
            if (cell?.value case final v?) v.toString(),
      ];
      expect(text.where((t) => ['First', 'Second', 'Third'].contains(t)), ['First', 'Second', 'Third']);
      expect(text.where((t) => t == 'ACADEMIC CONSULTATION FORM'), hasLength(4)); // 3 + a blank
      expect(text.where((t) => t.contains('Not an official school record')), hasLength(2)); // per page
      expect(sheet.rowPageBreaks, hasLength(1)); // two pages
      expect(sheet.pageSetup?.paperSize, xl.PaperSize.a4);
      expect(sheet.pageSetup?.fitToHeight, 2);
      expect(consultationFileName(list, 'pdf'), matches(RegExp(r'^Consultations_.+_to_.+\.pdf$')));
    });

    test('only signed consultations export', () async {
      final unsigned = await start();
      expect(() => consultationWorkbook([unsigned]), throwsArgumentError);
      expect(() => consultationForms([]), throwsArgumentError);
    });

    test('PDF: one A4 page per two forms', () async {
      TestWidgetsFlutterBinding.ensureInitialized(); // for the bundled font
      final list = await three();
      final pdf = await consultationPdf(list, photo: (_) => _png);
      expect(latin1.decode(pdf.sublist(0, 5)), '%PDF-');
      final pages = RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(pdf)).length;
      expect(pages, 2);
    });
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
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DCS').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'e.g. Faculty Room'), 'Faculty Room');
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
      await tester.scrollUntilVisible(find.textContaining('QR scanned'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('QR scanned'), findsOneWidget);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000)); // back to the top
      await tester.pumpAndSettle();
      await fillAndSave(tester);
      expect(find.text('Saved and signed in this preview only.'), findsOneWidget);
      expect(find.text('Absences'), findsOneWidget); // the saved form
      expect(find.text('Scan QR to Sign'), findsNothing);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Export PDF')).onPressed,
          isNotNull);
      expect(find.text('Export Excel'), findsOneWidget);
    });

    testWidgets('Select signed consultations to export; unsigned ones can\'t be ticked',
        (tester) async {
      await open(tester, 'Teacher', '/life/consultations', setUp: (campus) async {
        await campus.saveSignature(mockTeacher, 'upload:teacher');
        await campus.saveSignature(mockStudent, 'upload:student');
        for (final scanned in [true, true, false]) {
          await campus.saveConsultation(mockTeacher,
              studentId: mockStudent.id, department: 'DCS', venue: 'Room 1',
              rows: [(reason: 'Absences', intervention: 'Plan')], expectedOutcome: '',
              scanned: scanned);
        }
      });
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(find.byTooltip('Select to export'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Only you and the student'), findsNothing); // one line while selecting
      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes.where((b) => b.onChanged == null), hasLength(1)); // the unsigned one
      expect(find.text('None selected'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Export PDF')).onPressed,
          isNull);
      await tester.tap(find.text('Select all signed'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected · 1 page'), findsOneWidget);
      // Tapping the unsigned one says why it can't be ticked.
      await tester.tap(find.text('Not signed'));
      await tester.pump();
      expect(find.text("Nicolas Santos hasn't signed yet. Open it and Scan QR to Sign."), findsOneWidget);
      expect(find.text('2 selected · 1 page'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Export PDF')).onPressed,
          isNotNull);
      await tester.pump(const Duration(seconds: 5)); // the snackbar goes away
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear selection'));
      await tester.pumpAndSettle();
      expect(find.text('None selected'), findsOneWidget);
      // One by one works too.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('1 selected · 1 page'), findsOneWidget);
      await tester.tap(find.byTooltip('Stop selecting'));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNothing);
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
      // Exports wait for the student's signature.
      expect(find.text('The student signs first (Scan QR to Sign).'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Export PDF')).onPressed,
          isNull);

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

    testWidgets('first e-signature: Start consultation opens the scanner', (tester) async {
      final real = PhotoStore.picker;
      PhotoStore.picker = ({required int limit, required bool camera}) async => [_png];
      addTearDown(() => PhotoStore.picker = real);
      await open(tester, 'Teacher', '/life/consultations', setUp: (_) async {});
      await tester.tap(find.byTooltip('New consultation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add e-signature'));
      await tester.pumpAndSettle();
      expect(find.text('Start consultation'), findsNothing); // nothing uploaded yet
      await tester.tap(find.text('Upload signature'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start consultation'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mock scanner'), findsOneWidget);
      // Back skips the old "add your e-signature" page and returns to the list.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Add your e-signature before starting a consultation.'), findsNothing);
      expect(find.byTooltip('New consultation'), findsOneWidget);
    });

    testWidgets('Settings › My e-signature has no Start consultation button', (tester) async {
      await open(tester, 'Teacher', '/profile/signature'); // the teacher has a signature
      expect(find.text('Change signature'), findsOneWidget);
      expect(find.text('Start consultation'), findsNothing);
    });

    testWidgets('students read their consultations; no editing', (tester) async {
      await open(tester, 'Student', '/life/consultations', setUp: (campus) async {
        await campus.saveSignature(mockTeacher, 'upload:teacher');
        await campus.saveConsultation(mockTeacher,
            studentId: mockStudent.id, department: 'DCS', venue: 'Faculty Room',
            rows: [(reason: 'Missed two CS 302 labs', intervention: 'Make-up schedule')],
            expectedOutcome: '');
      });
      expect(find.text('Mark Villanueva'), findsOneWidget);
      await tester.tap(find.text('Mark Villanueva'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Missed two CS 302 labs'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Export PDF'), findsNothing);
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
