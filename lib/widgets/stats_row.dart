import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatItem {
  final String value; // e.g. "92%" or "3/6"
  final String label; // e.g. "Class attendance"
  final VoidCallback onTap; // opens the stat's detail

  const StatItem(this.value, this.label, {required this.onTap});
}

/// One compact, always-visible row of stats on a soft gray tile
/// (spec §6, §8). Numbers are navy; each stat taps through to its detail.
class StatsRow extends StatelessWidget {
  final List<StatItem> items;

  const StatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                    width: 1.5, thickness: 1.5, indent: 14, endIndent: 14, color: AppColors.white),
              Expanded(child: _Stat(items[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final StatItem item;

  const _Stat(this.item);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${item.label}: ${item.value}',
      excludeSemantics: true,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.value,
                  maxLines: 1,
                  style: text.headlineSmall?.copyWith(fontSize: 22, color: AppColors.navy)),
              const SizedBox(height: 2),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.25, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
