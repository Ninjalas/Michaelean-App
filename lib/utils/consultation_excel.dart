import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel_plus/excel_plus.dart' as xl;

import '../models/consultation.dart';
import '../services/photo_store.dart';
import 'dates.dart';

// One consultation as a filled-in Excel copy of the school's official
// Academic Consultation Form, F-QMS-14 Rev5 (11/25/24) (decided 2026-10-31):
// the same fields, order, labels, and form code. Close to the printed form,
// not a pixel copy. A small line below it says it's from the preview.

const _sheet = 'Consultation';
final _line = xl.Border(borderStyle: xl.BorderStyle.Thin);

/// Columns: label, value (left half); label, value (right half). The table
/// uses A:B and C:D. Widths in Excel characters (about 7 px each).
const _widths = [15.0, 30.0, 11.0, 30.0];

/// "Consultation_Nicolas_Santos_2026-10-30.xlsx"
String consultationFileName(Consultation c) {
  final d = c.heldAt;
  String two(int n) => n.toString().padLeft(2, '0');
  return 'Consultation_${c.studentName.replaceAll(' ', '_')}_'
      '${d.year}-${two(d.month)}-${two(d.day)}.xlsx';
}

/// The .xlsx file's bytes. [photo] finds a signature picture's bytes.
List<int> consultationWorkbook(Consultation c,
        {Uint8List? Function(String path) photo = PhotoStore.bytes}) =>
    _twoCellAnchors(_build(c, photo).encode()!);

/// Saves the file; in the browser this downloads it. Reading the finished
/// bytes back keeps the pictures' two-cell anchors (excel_plus copies an
/// untouched drawing as it is) and lets excel_plus do the download.
void downloadConsultation(Consultation c) =>
    xl.Excel.decodeBytes(consultationWorkbook(c)).save(fileName: consultationFileName(c));

xl.Excel _build(Consultation c, Uint8List? Function(String path) photo) {
  final excel = xl.Excel.createExcel();
  excel.rename(excel.getDefaultSheet()!, _sheet);
  final s = excel[_sheet];
  for (final (col, w) in _widths.indexed) {
    s.setColumnWidth(col, w);
  }
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

  xl.CellStyle centered({bool bold = true, int? size}) => xl.CellStyle(
      bold: bold, fontSize: size, fontFamily: 'Arial', horizontalAlign: xl.HorizontalAlign.Center);
  final label = xl.CellStyle(bold: true, fontFamily: 'Arial');
  final filled = xl.CellStyle(fontFamily: 'Arial', bottomBorder: _line); // on the line

  // Header.
  put("SAINT MICHAEL'S COLLEGE OF LAGUNA", style: centered(size: 14));
  row++;
  put('OLD NATIONAL ROAD, PLATERO, CITY OF BIÑAN, LAGUNA', style: centered(size: 9));
  row += 2;
  put('ACADEMIC CONSULTATION FORM', style: centered(size: 11));
  row += 2;

  // The department ticks, all on one line; the chosen one is ticked.
  put(
      [for (final d in consultationDepartments) d == c.department ? '_✓_$d' : '___$d']
          .join('    '),
      style: centered());
  s.setRowHeight(row, 20);
  row += 2;

  // Details: Name, Course / Grade, Faculty on the left; Time, Date, Venue on the right.
  for (final (left, leftValue, right, rightValue) in [
    ('Name :', c.studentName, 'Time:', formatTime(c.heldAt)),
    ('Course / Grade :', c.studentSection, 'Date:', formatDate(c.heldAt)),
    ('Faculty', c.teacherName, 'Venue:', c.venue),
  ]) {
    put(left, to: 0, style: label);
    put(leftValue, from: 1, to: 1, style: filled);
    put(right, from: 2, to: 2, style: label);
    put(rightValue, from: 3, to: 3, style: filled);
    s.setRowHeight(row, 18);
    row++;
  }
  row++;

  // The table: a header, then the form's six lines.
  final box = xl.CellStyle(
      fontFamily: 'Arial', leftBorder: _line, rightBorder: _line, topBorder: _line, bottomBorder: _line);
  final head = xl.CellStyle(
      bold: true, fontFamily: 'Arial', horizontalAlign: xl.HorizontalAlign.Center,
      leftBorder: _line, rightBorder: _line, topBorder: _line, bottomBorder: _line);
  put('Reason/s for Consultation', to: 1, style: head);
  put('Intervention Made', from: 2, style: head);
  row++;
  final cell = xl.CellStyle(
      fontFamily: 'Arial', textWrapping: xl.TextWrapping.WrapText, verticalAlign: xl.VerticalAlign.Top,
      leftBorder: _line, rightBorder: _line, topBorder: _line, bottomBorder: _line);
  for (var i = 0; i < maxConsultationRows; i++) {
    final r = i < c.rows.length ? c.rows[i] : null;
    put(r?.reason ?? '', to: 1, style: r == null ? box : cell);
    put(r?.intervention ?? '', from: 2, style: r == null ? box : cell);
    s.setRowHeight(row, r == null ? 18 : 32);
    row++;
  }
  row++;

  // Expected Outcome, on two lines.
  put('Expected Outcome:', style: label);
  row++;
  put(c.expectedOutcome,
      style: xl.CellStyle(
          fontFamily: 'Arial', textWrapping: xl.TextWrapping.WrapText,
          verticalAlign: xl.VerticalAlign.Top, bottomBorder: _line));
  s.setRowHeight(row, 30);
  row++;
  put('', style: filled);
  s.setRowHeight(row, 20);
  row += 2;

  // Signatures: each picture sits above its line, the label below it.
  s.setRowHeight(row, 48);
  void signature(int col, int to, String? path, String missing) {
    final bytes = path == null ? null : photo(path);
    if (bytes == null) {
      put(missing,
          from: col, to: to,
          style: xl.CellStyle(italic: true, fontFamily: 'Arial', horizontalAlign: xl.HorizontalAlign.Center,
              verticalAlign: xl.VerticalAlign.Bottom));
      return;
    }
    try {
      // Small enough to stay inside its column (about 210 px wide).
      final (w, h) = _fit(bytes, maxWidth: 190, maxHeight: 60);
      s.insertImage(bytes, anchor: at(to, row), width: w, height: h);
    } on ArgumentError {
      put('E-signature on file (picture type not supported in Excel)',
          from: col, to: to, style: xl.CellStyle(italic: true, fontFamily: 'Arial'));
    }
  }

  signature(0, 1, c.studentSignature, c.studentSigned ? '' : 'Not yet signed');
  signature(2, 3, c.teacherSignature, '');
  row++;
  final signLabel = xl.CellStyle(
      bold: true, fontFamily: 'Arial', horizontalAlign: xl.HorizontalAlign.Center, topBorder: _line);
  put("Student's Signature", to: 1, style: signLabel);
  put("Instructor's/Professor's Signature", from: 2, style: signLabel);
  row += 3;

  // The form code, then the preview note below the form.
  final small = xl.CellStyle(fontFamily: 'Arial', fontSize: 9);
  put('F-QMS-14', to: 1, style: small);
  row++;
  put('Rev5(11/25/24)', to: 1, style: small);
  row += 2;
  final note = xl.CellStyle(italic: true, fontFamily: 'Arial', fontSize: 8);
  put('Made in the Michaelean preview with sample data. Not an official school record.',
      style: note);
  if (c.editedAfterSigning) {
    row++;
    put('Edited after the student signed.', style: note);
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
