import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel_plus/excel_plus.dart' as xl;

import '../models/consultation.dart';
import '../services/photo_store.dart';
import 'dates.dart';

// Consultations as filled-in Excel copies of the school's official Academic
// Consultation Form, F-QMS-14 Rev5 (11/25/24) (decided 2026-10-31): the same
// fields, order, labels, and form code. Close to the printed form, not a
// pixel copy. Two forms per A4 page, stacked with a dashed cut line, like
// the paper; an odd count leaves a blank form at the bottom. A small line at
// the foot of each page says it's from the preview.

const _sheet = 'Consultation';
final _line = xl.Border(borderStyle: xl.BorderStyle.Thin);

/// Columns: label, value (left half); label, value (right half). The table
/// uses A:B and C:D. Widths in Excel characters (about 7 px each), about an
/// A4 page wide.
const _widths = [18.0, 37.0, 13.0, 38.0];

/// The forms in page order: oldest first, two per page, a blank (null) at
/// the bottom of the last page when the count is odd. Signed ones only: the
/// paper copy is made after the student signs (decided 2026-10-31).
List<Consultation?> consultationForms(List<Consultation> list) {
  if (list.isEmpty) throw ArgumentError('Pick at least one consultation.');
  if (list.any((c) => !c.studentSigned)) throw ArgumentError('The student signs first.');
  final forms = <Consultation?>[...list]..sort((a, b) => a!.heldAt.compareTo(b!.heldAt));
  if (forms.length.isOdd) forms.add(null);
  return forms;
}

/// "Consultation_Nicolas_Santos_2026-10-30.xlsx" for one;
/// "Consultations_2026-10-28_to_2026-10-30.pdf" for several
/// ("Consultations_2026-10-30.pdf" if all on one day).
String consultationFileName(List<Consultation> list, String extension) {
  String day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  if (list.length == 1) {
    final c = list.single;
    return 'Consultation_${c.studentName.replaceAll(' ', '_')}_${day(c.heldAt)}.$extension';
  }
  final days = [for (final c in list) day(c.heldAt)]..sort();
  final range = days.first == days.last ? days.first : '${days.first}_to_${days.last}';
  return 'Consultations_$range.$extension';
}

/// The department line, the chosen one ticked: "___DBA    _✓_DCS    ...".
String consultationDepartmentLine(String? chosen) =>
    [for (final d in consultationDepartments) d == chosen ? '_✓_$d' : '___$d'].join('    ');

/// The .xlsx file's bytes. [photo] finds a signature picture's bytes.
List<int> consultationWorkbook(List<Consultation> list,
        {Uint8List? Function(String path) photo = PhotoStore.bytes}) =>
    _twoCellAnchors(_build(consultationForms(list), photo).encode()!);

/// Saves the file; in the browser this downloads it. Reading the finished
/// bytes back keeps the pictures' two-cell anchors (excel_plus copies an
/// untouched drawing as it is) and lets excel_plus do the download.
void downloadConsultations(List<Consultation> list) => xl.Excel.decodeBytes(consultationWorkbook(list))
    .save(fileName: consultationFileName(list, 'xlsx'));

xl.Excel _build(List<Consultation?> forms, Uint8List? Function(String path) photo) {
  final excel = xl.Excel.createExcel();
  excel.rename(excel.getDefaultSheet()!, _sheet);
  final s = excel[_sheet];
  for (final (col, w) in _widths.indexed) {
    s.setColumnWidth(col, w);
  }
  // A4 portrait, one page wide and as many tall as there are pairs: Excel
  // shrinks the forms a little if a pair doesn't quite fit.
  s.pageSetup = xl.PageSetup(
    orientation: xl.PageOrientation.portrait,
    paperSize: xl.PaperSize.a4,
    fitToWidth: 1,
    fitToHeight: forms.length ~/ 2,
    horizontalCentered: true,
    margins: const xl.PageMargins.narrow(),
  );
  var row = 0;
  xl.CellIndex at(int col, int r) => xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r);

  /// Text across columns [from]..[to] of the current row.
  void put(String text, {int from = 0, int to = 3, xl.CellStyle? style}) {
    // Every cell of a merged range gets the style, so borders run all along.
    for (var col = from; col <= to; col++) {
      s.updateCell(at(col, row), col == from ? xl.TextCellValue(text) : null, cellStyle: style);
    }
    if (to > from) {
      s.merge(at(from, row), at(to, row));
      // Merging keeps only the first cell's look; this restyles the whole range.
      if (style != null) s.setMergedCellStyle(at(from, row), style);
    }
  }

  /// A thin empty row between parts of the form.
  void gap([double height = 5]) {
    s.setRowHeight(row, height);
    row++;
  }

  // Small type so a form fits half a page, like the paper.
  xl.CellStyle centered({int size = 9}) => xl.CellStyle(
      bold: true, fontSize: size, fontFamily: 'Arial', horizontalAlign: xl.HorizontalAlign.Center);
  final label = xl.CellStyle(bold: true, fontSize: 9, fontFamily: 'Arial');
  final filled = xl.CellStyle(fontSize: 9, fontFamily: 'Arial', bottomBorder: _line); // on the line
  xl.CellStyle boxed({bool bold = false, bool wrap = false}) => xl.CellStyle(
      bold: bold, fontSize: 9, fontFamily: 'Arial',
      horizontalAlign: bold ? xl.HorizontalAlign.Center : xl.HorizontalAlign.Left,
      textWrapping: wrap ? xl.TextWrapping.WrapText : null,
      verticalAlign: xl.VerticalAlign.Top,
      leftBorder: _line, rightBorder: _line, topBorder: _line, bottomBorder: _line);
  final small = xl.CellStyle(fontSize: 8, fontFamily: 'Arial');
  final note = xl.CellStyle(italic: true, fontSize: 7, fontFamily: 'Arial');

  /// One form; [c] null is a blank one.
  void form(Consultation? c) {
    // Header.
    put("SAINT MICHAEL'S COLLEGE OF LAGUNA", style: centered(size: 12));
    s.setRowHeight(row, 16);
    row++;
    put('OLD NATIONAL ROAD, PLATERO, CITY OF BIÑAN, LAGUNA', style: centered(size: 7));
    s.setRowHeight(row, 11);
    row++;
    gap();
    put('ACADEMIC CONSULTATION FORM', style: centered(size: 10));
    s.setRowHeight(row, 14);
    row++;
    gap();

    // The department ticks, all on one line; the chosen one is ticked.
    put(consultationDepartmentLine(c?.department), style: centered());
    s.setRowHeight(row, 14);
    row++;
    gap();

    // Details: Name, Course / Grade, Faculty on the left; Time, Date, Venue on the right.
    for (final (left, leftValue, right, rightValue) in [
      ('Name :', c?.studentName, 'Time:', c == null ? null : formatTime(c.heldAt)),
      ('Course / Grade :', c?.studentSection, 'Date:', c == null ? null : formatDate(c.heldAt)),
      ('Faculty', c?.teacherName, 'Venue:', c?.venue),
    ]) {
      put(left, to: 0, style: label);
      put(leftValue ?? '', from: 1, to: 1, style: filled);
      put(right, from: 2, to: 2, style: label);
      put(rightValue ?? '', from: 3, to: 3, style: filled);
      s.setRowHeight(row, 14);
      row++;
    }
    gap();

    // The table: a header, then the form's six lines.
    put('Reason/s for Consultation', to: 1, style: boxed(bold: true));
    put('Intervention Made', from: 2, style: boxed(bold: true));
    s.setRowHeight(row, 13);
    row++;
    for (var i = 0; i < maxConsultationRows; i++) {
      final r = c != null && i < c.rows.length ? c.rows[i] : null;
      put(r?.reason ?? '', to: 1, style: boxed(wrap: true));
      put(r?.intervention ?? '', from: 2, style: boxed(wrap: true));
      s.setRowHeight(row, 25); // two lines of text
      row++;
    }
    gap();

    // Expected Outcome, on two lines.
    put('Expected Outcome:', style: label);
    s.setRowHeight(row, 13);
    row++;
    put(c?.expectedOutcome ?? '',
        style: xl.CellStyle(
            fontSize: 9, fontFamily: 'Arial', textWrapping: xl.TextWrapping.WrapText,
            verticalAlign: xl.VerticalAlign.Top, bottomBorder: _line));
    s.setRowHeight(row, 22);
    row++;
    put('', style: filled);
    s.setRowHeight(row, 13);
    row++;
    gap();

    // Signatures: each picture sits above its line, the label below it.
    s.setRowHeight(row, 34);
    void signature(int col, int to, String? path) {
      final bytes = path == null ? null : photo(path);
      if (bytes == null) return; // a blank line to sign by hand
      try {
        // Small enough to stay inside its cell (about 260 x 45 px).
        final (w, h) = _fit(bytes, maxWidth: 220, maxHeight: 40);
        s.insertImage(bytes, anchor: at(to, row), width: w, height: h);
      } on ArgumentError {
        put('E-signature on file (picture type not supported in Excel)',
            from: col, to: to, style: xl.CellStyle(italic: true, fontSize: 8, fontFamily: 'Arial'));
      }
    }

    signature(0, 1, c?.studentSignature);
    signature(2, 3, c?.teacherSignature);
    row++;
    final signLabel = xl.CellStyle(
        bold: true, fontSize: 9, fontFamily: 'Arial', horizontalAlign: xl.HorizontalAlign.Center,
        topBorder: _line);
    put("Student's Signature", to: 1, style: signLabel);
    put("Instructor's/Professor's Signature", from: 2, style: signLabel);
    s.setRowHeight(row, 13);
    row++;
    gap();

    // The form code.
    put('F-QMS-14', to: 1, style: small);
    s.setRowHeight(row, 11);
    row++;
    put('Rev5(11/25/24)', to: 1, style: small);
    if (c != null && c.editedAfterSigning) {
      put('Edited after the student signed.', from: 2, style: note);
    }
    s.setRowHeight(row, 11);
    row++;
  }

  for (var i = 0; i < forms.length; i += 2) {
    form(forms[i]);
    // The cut line between the two halves.
    gap(8);
    put('', style: xl.CellStyle(bottomBorder: xl.Border(borderStyle: xl.BorderStyle.Dashed)));
    s.setRowHeight(row, 8);
    row++;
    gap(14);
    form(forms[i + 1]);
    gap(8);
    put('Made in the Michaelean preview with sample data. Not an official school record.',
        style: note);
    s.setRowHeight(row, 10);
    if (i + 2 < forms.length) s.insertRowPageBreak(row + 1); // the next pair starts a page
    row++;
  }
  return excel;
}

/// A size within the box that keeps the picture's shape. The picture's own
/// size is read by inserting it into a scratch sheet, since excel_plus keeps
/// its size reader private.
(int, int) _fit(Uint8List bytes, {required int maxWidth, required int maxHeight}) {
  final probe = xl.Excel.createExcel();
  final sheet = probe[probe.getDefaultSheet()!];
  sheet.insertImage(bytes, anchor: xl.CellIndex.indexByString('A1'));
  final img = sheet.images.single;
  final scale = [maxWidth / img.width, maxHeight / img.height, 1.0].reduce((a, b) => a < b ? a : b);
  return ((img.width * scale).round(), (img.height * scale).round());
}

/// Pins each picture by two corners instead of excel_plus's one: iPhone's
/// Files preview ignores one-corner pictures' position and draws them at the
/// top-left (found 2026-10-31). Each picture stays inside its cell, so its
/// far corner is in that same cell.
List<int> _twoCellAnchors(List<int> xlsx) {
  final anchor = RegExp(r'<xdr:oneCellAnchor><xdr:from><xdr:col>(\d+)</xdr:col>'
      r'<xdr:colOff>(\d+)</xdr:colOff><xdr:row>(\d+)</xdr:row><xdr:rowOff>(\d+)</xdr:rowOff>'
      r'</xdr:from><xdr:ext cx="(\d+)" cy="(\d+)"/>(.*?)</xdr:oneCellAnchor>');
  final zip = ZipDecoder().decodeBytes(xlsx);
  final out = Archive();
  for (final f in zip.files) {
    if (!f.name.startsWith('xl/drawings/drawing') || !f.name.endsWith('.xml')) {
      out.addFile(f);
      continue;
    }
    final xml = utf8.decode(f.content).replaceAllMapped(anchor, (m) {
      final from = '<xdr:col>${m[1]}</xdr:col><xdr:colOff>${m[2]}</xdr:colOff>'
          '<xdr:row>${m[3]}</xdr:row><xdr:rowOff>${m[4]}</xdr:rowOff>';
      final to = '<xdr:col>${m[1]}</xdr:col>'
          '<xdr:colOff>${int.parse(m[2]!) + int.parse(m[5]!)}</xdr:colOff>'
          '<xdr:row>${m[3]}</xdr:row>'
          '<xdr:rowOff>${int.parse(m[4]!) + int.parse(m[6]!)}</xdr:rowOff>';
      return '<xdr:twoCellAnchor editAs="oneCell"><xdr:from>$from</xdr:from>'
          '<xdr:to>$to</xdr:to>${m[7]}</xdr:twoCellAnchor>';
    });
    final bytes = utf8.encode(xml);
    out.addFile(ArchiveFile(f.name, bytes.length, bytes));
  }
  return ZipEncoder().encode(out);
}
