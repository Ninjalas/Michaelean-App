import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';
import '../../widgets/photo_source.dart';
import '../../widgets/post_image.dart';

/// Settings › My e-signature (decided 2026-10-30): a photo of the user's
/// signature on paper, used on consultation forms. Kept in this preview's
/// memory only.
class SignatureScreen extends StatefulWidget {
  final CampusService campusService;

  const SignatureScreen({super.key, required this.campusService});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  Future<String?>? _signature;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _signature ??= widget.campusService.loadSignature(SessionScope.of(context).user!);
  }

  Future<void> _set(String? photo) async {
    setState(() => _busy = true);
    final user = SessionScope.of(context).user!;
    try {
      await widget.campusService.saveSignature(user, photo);
      setState(() {
        _signature = Future.value(photo);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't save your e-signature.")));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    try {
      final picked = await pickPhotos(context, limit: 1);
      if (picked.isNotEmpty) await _set(picked.first);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't add the photo. Try another one.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('My e-signature'),
            Expanded(
              child: FutureBuilder<String?>(
                future: _signature,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Align(
                        alignment: Alignment.topCenter, child: LinearProgressIndicator());
                  }
                  final photo = snap.data;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 120),
                    children: [
                      Text(
                        'Upload a photo of your signature on white paper. It goes on '
                        'consultation forms you sign.',
                        style: muted,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        height: 160,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.large),
                          boxShadow: AppColors.cardShadow,
                        ),
                        alignment: Alignment.center,
                        child: photo == null
                            ? Text('No e-signature yet', style: muted)
                            : Semantics(
                                image: true,
                                label: 'Your e-signature',
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: PostImage(photo, fit: BoxFit.contain),
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _busy ? null : _upload,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(photo == null ? 'Upload signature' : 'Change signature'),
                      ),
                      if (photo != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: _busy ? null : () => _set(null),
                          child: const Text('Remove signature'),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Kept in this preview only, never uploaded anywhere. Forms already '
                        'signed keep the signature they were signed with.',
                        style: muted,
                      ),
                      if (SessionScope.of(context).user!.can(Permission.holdConsultations)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'You need an e-signature to start a consultation. Removing it '
                          "doesn't change forms you already made.",
                          style: muted,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
