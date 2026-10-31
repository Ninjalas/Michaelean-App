/// One reason for a consultation and the intervention made for it: a row of
/// the form's two-column table.
typedef ConsultationRow = ({String reason, String intervention});

/// Rows one consultation can have, like the paper form's lines (decided
/// 2026-10-30).
const maxConsultationRows = 5;

/// A teacher's consultation with one student (decided 2026-10-30). Only that
/// teacher and that student see it. Signatures are photos the two uploaded
/// in Settings; the student's is added when they show their QR.
class Consultation {
  final String id;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String studentSection;
  final String studentMaskedId; // never the full ID
  final DateTime heldAt;
  final List<ConsultationRow> rows;
  final String expectedOutcome;

  /// The teacher's e-signature (a photo path) from when the form was made.
  /// Required to start one, and kept for good (decided 2026-10-31).
  final String? teacherSignature;

  /// When the student showed their QR; null until then.
  final DateTime? studentSignedAt;

  /// The student's e-signature from when they showed their QR; null until
  /// then. Their QR signs only once they have one on file.
  final String? studentSignature;

  /// Changed after the student signed, so nobody takes a later edit for
  /// something the student saw.
  final bool editedAfterSigning;

  const Consultation({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.studentSection,
    required this.studentMaskedId,
    required this.heldAt,
    required this.rows,
    required this.expectedOutcome,
    this.teacherSignature,
    this.studentSignedAt,
    this.studentSignature,
    this.editedAfterSigning = false,
  });

  bool get studentSigned => studentSignedAt != null;
}
