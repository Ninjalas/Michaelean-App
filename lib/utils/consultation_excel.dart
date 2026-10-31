import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel_plus/excel_plus.dart' as xl;

import '../models/consultation.dart';
import '../services/photo_store.dart';
import 'dates.dart';

// One consultation as a filled-in Excel form (decided 2026-10-30): a simple
// sheet in SMCL navy that follows the professors' paper layout, until the
// school's official template arrives.

const _sheet = 'Consultation';
final _navy = xl.ExcelColor.fromHexString('#242A5E');
final _white = xl.ExcelColor.fromHexString('#FFFFFF');
final _line = xl.Border(borderStyle: xl.BorderStyle.Thin);

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
  for (final col in [0, 1, 2, 3]) {
    s.setColumnWidth(col, 22);
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

  final title = xl.CellStyle(
      bold: true, fontSize: 14, fontColorHex: _navy, horizontalAlign: xl.HorizontalAlign.Center);
  put("SAINT MICHAEL'S COLLEGE OF LAGUNA", style: title);
  row++;
  put('CONSULTATION FORM',
      style: xl.CellStyle(bold: true, fontColorHex: _navy, horizontalAlign: xl.HorizontalAlign.Center));
  row++;
  put('Made in the Michaelean preview with sample data. Not an official school record.',
      style: xl.CellStyle(italic: true, fontSize: 9, horizontalAlign: xl.HorizontalAlign.Center));
  row += 2;

  final label = xl.CellStyle(bold: true);
  for (final (k, v) in [
    ('Date and time', '${formatDate(c.heldAt)} · ${formatTime(c.heldAt)}'),
    ('Student', '${c.studentName} · ${c.studentSection}'),
    ('Student ID', c.studentMaskedId),
    ('Instructor', c.teacherName),
  ]) {
    put(k, to: 0, style: label);
    put(v, from: 1);
    row++;
  }
  row++;

  // The two-column table: a navy header, then one line per reason, with
  // empty lines up to the paper form's five.
  final head = xl.CellStyle(
      bold: true, fontColorHex: _white, backgroundColorHex: _navy,
      horizontalAlign: xl.HorizontalAlign.Center, verticalAlign: xl.VerticalAlign.Center);
  put('Reason/s for Consultation', to: 1, style: head);
  put('Intervention Made', from: 2, style: head);
  s.setRowHeight(row, 24);
  row++;
  final cell = xl.CellStyle(
      textWrapping: xl.TextWrapping.WrapText, verticalAlign: xl.VerticalAlign.Top,
      leftBorder: _line, rightBorder: _line, topBorder: _line, bottomBorder: _line);
  for (var i = 0; i < maxConsultationRows; i++) {
    final r = i < c.rows.length ? c.rows[i] : null;
    put(r?.reason ?? '', to: 1, style: cell);
    put(r?.intervention ?? '', from: 2, style: cell);
    s.setRowHeight(row, 48);
    row++;
  }
  row++;

  put('Expected outcome:', style: label);
  row++;
  put(c.expectedOutcome, style: cell);
  s.setRowHeight(row, 60);
  row += 2;

  // Signatures: the uploaded pictures above each signer's name.
  put('Student Signature', to: 1, style: label);
  put('Instructor/Professor Signature', from: 2, style: label);
  row++;
  s.setRowHeight(row, 50);
  void signature(int col, String? path, String missing) {
    final bytes = path == null ? null : photo(path);
    if (bytes == null) {
      put(missing, from: col, to: col + 1, style: xl.CellStyle(italic: true));
      return;
    }
    try {
      // Small enough to stay inside its column (about 160 px wide).
      final (w, h) = _fit(bytes, maxWidth: 150, maxHeight: 60);
      s.insertImage(bytes, anchor: at(col, row), width: w, height: h);
    } on ArgumentError {
      put('E-signature on file (picture type not supported in Excel)',
          from: col, to: col + 1, style: xl.CellStyle(italic: true));
    }
  }

  signature(0, c.studentSignature,
      c.studentSigned ? 'No e-signature on file' : 'Not yet signed');
  signature(2, c.teacherSignature, 'No e-signature on file');
  row++;
  final name = xl.CellStyle(topBorder: _line);
  put(c.studentName, to: 1, style: name);
  put(c.teacherName, from: 2, style: name);
  if (c.editedAfterSigning) {
    row += 2;
    put('Edited after the student signed.', style: xl.CellStyle(italic: true, fontSize: 9));
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
