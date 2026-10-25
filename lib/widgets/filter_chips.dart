import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A row of pill chips, one selected (navy), that scrolls sideways when the
/// labels don't fit: Discover's filters, the Grades page's semesters.
class FilterChips<T> extends StatelessWidget {
  final List<(T, String)> options; // (value, label)
  final T selected;
  final ValueChanged<T> onChanged;

  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Semantics(
                button: true,
                selected: value == selected,
                child: Material(
                  color: value == selected ? AppColors.navy : AppColors.fill,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onChanged(value),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value == selected ? AppColors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
