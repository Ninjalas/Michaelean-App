import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The shared rounded pop-up (spec §2.1, §7.4, §11): dimmed background,
/// X button, closes on outside tap, scrolls inside.
///
/// It is a router page (not showModalBottomSheet) so the pop-up gets its own
/// browser-history entry: the browser / Android Back gesture then closes the
/// pop-up instead of changing the page underneath it.
class AppSheetPage<T> extends Page<T> {
  final String title;
  final Widget child;

  const AppSheetPage({super.key, required this.title, required this.child});

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
        settings: this,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppColors.white,
        modalBarrierColor: const Color(0x66000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        builder: (sheetContext) => _SheetBody(title: title, child: child),
      );
}

class _SheetBody extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetBody({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, 0, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(backgroundColor: AppColors.fill),
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
