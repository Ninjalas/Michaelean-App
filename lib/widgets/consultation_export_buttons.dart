import 'package:flutter/material.dart';

import '../models/consultation.dart';
import '../utils/consultation_excel.dart';
import '../utils/consultation_pdf.dart';
import '../theme/app_theme.dart';

/// Export PDF and Export Excel, side by side (decided 2026-10-31): copies of
/// the official form, two per A4 page. Off (null [list]) until there's
/// something signed to export.
class ConsultationExportButtons extends StatefulWidget {
  final List<Consultation>? list;

  const ConsultationExportButtons(this.list, {super.key});

  @override
  State<ConsultationExportButtons> createState() => _ConsultationExportButtonsState();
}

class _ConsultationExportButtonsState extends State<ConsultationExportButtons> {
  bool _busy = false;

  Future<void> _export(List<Consultation> list, {required bool pdf}) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = consultationFileName(list, pdf ? 'pdf' : 'xlsx');
    setState(() => _busy = true);
    try {
      if (pdf) {
        await shareConsultationsPdf(list);
      } else {
        downloadConsultations(list);
      }
      messenger.showSnackBar(SnackBar(content: Text('Saving $name')));
    } catch (_) {
      messenger.showSnackBar(
          SnackBar(content: Text("Couldn't make the ${pdf ? 'PDF' : 'Excel'} file.")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _busy ? null : widget.list;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: list == null ? null : () => _export(list, pdf: true),
            child: const Text('Export PDF'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton(
            onPressed: list == null ? null : () => _export(list, pdf: false),
            child: const Text('Export Excel'),
          ),
        ),
      ],
    );
  }
}
