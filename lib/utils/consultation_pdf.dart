import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/consultation.dart';
import '../services/photo_store.dart';
import 'consultation_excel.dart';
import 'dates.dart';

// Consultations as a PDF copy of the official F-QMS-14 Rev5 form (decided
// 2026-10-31): the same layout as the Excel export, two forms per A4 page
// with a dashed cut line, a blank form when the count is odd, and the
// preview note at the foot of each page. Uses the bundled Inter font, which
// has the ✓ and Ñ the PDF's built-in fonts lack.

/// The PDF file's bytes. [photo] finds a signature picture's bytes.
Future<Uint8List> consultationPdf(List<Consultation> list,
    {Uint8List? Function(String path) photo = PhotoStore.bytes}) async {
  final forms = consultationForms(list);
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf')),
    bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf')),
  );
  final doc = pw.Document(title: 'Academic Consultation Forms', creator: 'Michaelean preview');
  for (var i = 0; i < forms.length; i += 2) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.fromLTRB(40, 28, 40, 18),
      build: (_) => pw.Column(children: [
        pw.Expanded(child: _form(forms[i], photo)),
        // The cut line between the two halves.
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 18),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(width: 0.6, style: pw.BorderStyle.dashed, color: PdfColors.grey600))),
        ),
        pw.Expanded(child: _form(forms[i + 1], photo)),
        pw.Text('Made in the Michaelean preview with sample data. Not an official school record.',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
      ]),
    ));
  }
  return doc.save();
}

/// Saves the PDF: downloads it on a computer, opens the share/save sheet on
/// a phone.
Future<void> shareConsultationsPdf(List<Consultation> list) async => Printing.sharePdf(
    bytes: await consultationPdf(list), filename: consultationFileName(list, 'pdf'));

const _size = 8.0;
final _bold = pw.TextStyle(fontSize: _size, fontWeight: pw.FontWeight.bold);
const _thin = pw.BorderSide(width: 0.6);

/// One form; [c] null is a blank one.
pw.Widget _form(Consultation? c, Uint8List? Function(String path) photo) {
  pw.Widget onLine(String? value) => pw.Container(
        height: 12,
        padding: const pw.EdgeInsets.only(left: 3),
        alignment: pw.Alignment.bottomLeft,
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: _thin)),
        child: pw.Text(value ?? '', maxLines: 1, style: const pw.TextStyle(fontSize: _size)),
      );
  pw.Widget detail(String left, String? leftValue, String right, String? rightValue) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.SizedBox(width: 72, child: pw.Text(left, style: _bold)),
          pw.Expanded(child: onLine(leftValue)),
          pw.SizedBox(width: 14),
          pw.SizedBox(width: 34, child: pw.Text(right, style: _bold)),
          pw.Expanded(child: onLine(rightValue)),
        ]),
      );
  pw.Widget cell(String text, {bool head = false}) => pw.Container(
        height: head ? 12 : 23, // two lines of text
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
        alignment: head ? pw.Alignment.center : pw.Alignment.topLeft,
        child: pw.Text(text, maxLines: head ? 1 : 2, style: head ? _bold : const pw.TextStyle(fontSize: _size)),
      );
  pw.Widget signature(String? path, String label) {
    pw.Widget picture = pw.SizedBox();
    final bytes = path == null ? null : photo(path);
    if (bytes != null) {
      try {
        picture = pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain);
      } catch (_) {
        picture = pw.Text('E-signature on file (picture type not supported)',
            style: const pw.TextStyle(fontSize: 6.5));
      }
    }
    return pw.Expanded(
      child: pw.Column(children: [
        pw.Container(height: 32, alignment: pw.Alignment.bottomCenter, child: picture),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(top: 1.5),
          decoration: const pw.BoxDecoration(border: pw.Border(top: _thin)),
          child: pw.Text(label, textAlign: pw.TextAlign.center, style: _bold),
        ),
      ]),
    );
  }

  final rows = [
    for (var i = 0; i < maxConsultationRows; i++)
      c != null && i < c.rows.length ? c.rows[i] : null,
  ];
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
    // Header.
    pw.Text("SAINT MICHAEL'S COLLEGE OF LAGUNA",
        textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    pw.Text('OLD NATIONAL ROAD, PLATERO, CITY OF BIÑAN, LAGUNA',
        textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 5),
    pw.Text('ACADEMIC CONSULTATION FORM',
        textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 5),
    // The department ticks, all on one line; the chosen one is ticked.
    pw.Text(consultationDepartmentLine(c?.department), textAlign: pw.TextAlign.center, style: _bold),
    pw.SizedBox(height: 6),
    // Details: Name, Course / Grade, Faculty on the left; Time, Date, Venue on the right.
    detail('Name :', c?.studentName, 'Time:', c == null ? null : formatTime(c.heldAt)),
    detail('Course / Grade :', c?.studentSection, 'Date:', c == null ? null : formatDate(c.heldAt)),
    detail('Faculty', c?.teacherName, 'Venue:', c?.venue),
    pw.SizedBox(height: 5),
    // The table: a header, then the form's six lines.
    pw.Table(
        border: pw.TableBorder.all(width: 0.6),
        columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()}, // halves, like the paper
        children: [
      pw.TableRow(children: [
        cell('Reason/s for Consultation', head: true),
        cell('Intervention Made', head: true),
      ]),
      for (final r in rows) pw.TableRow(children: [cell(r?.reason ?? ''), cell(r?.intervention ?? '')]),
    ]),
    pw.SizedBox(height: 5),
    // Expected Outcome, on two lines.
    pw.Text('Expected Outcome:', style: _bold),
    pw.Container(
      height: 19,
      padding: const pw.EdgeInsets.only(left: 3, top: 1.5),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: _thin)),
      child: pw.Text(c?.expectedOutcome ?? '', maxLines: 2, style: const pw.TextStyle(fontSize: _size)),
    ),
    pw.Container(height: 12, decoration: const pw.BoxDecoration(border: pw.Border(bottom: _thin))),
    pw.SizedBox(height: 2),
    // Signatures: each picture sits above its line, the label below it.
    pw.Row(children: [
      signature(c?.studentSignature, "Student's Signature"),
      pw.SizedBox(width: 24),
      signature(c?.teacherSignature, "Instructor's/Professor's Signature"),
    ]),
    pw.SizedBox(height: 4),
    // The form code.
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
      pw.Text('F-QMS-14\nRev5(11/25/24)', style: const pw.TextStyle(fontSize: 7)),
      pw.Spacer(),
      if (c != null && c.editedAfterSigning)
        pw.Text('Edited after the student signed.',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
    ]),
  ]);
}
