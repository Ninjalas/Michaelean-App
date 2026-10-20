import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

/// The user's QR code, opened by long-pressing the middle tab (spec §1.3).
/// It holds only the account's random mock token, never personal data, and
/// showing it never verifies identity or attendance.
class QrSheet extends StatelessWidget {
  const QrSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.screen),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.hairline, width: 1.5),
            ),
            // Black on white with a quiet zone: the easiest QR for a camera to read.
            child: QrImageView(
              data: user.qrToken,
              size: 220,
              backgroundColor: AppColors.white,
              semanticsLabel: 'Your QR code',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserAvatar(name: user.fullName, imageAsset: user.photoAsset, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(user.fullName, style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user.role == UserRole.student
                ? 'Show this code to your teacher.'
                : 'Your Michaelean identity code.',
            textAlign: TextAlign.center,
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Sample code for the prototype. Showing it doesn't verify your identity "
            'or record attendance.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
