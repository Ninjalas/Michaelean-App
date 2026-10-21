import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/user_avatar.dart';

/// Edit Profile (spec §10): only presentation details. About is editable;
/// academic info, IDs, memberships, roles, and history are not. Saving
/// changes this preview only, and the confirmation says so.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const aboutMaxLength = 160;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _about = TextEditingController();
  String _original = '';
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _original = SessionScope.of(context).user?.about ?? '';
    _about.text = _original;
  }

  @override
  void dispose() {
    _about.dispose();
    super.dispose();
  }

  bool get _changed => _about.text.trim() != _original.trim();

  void _save() {
    final session = SessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final about = _about.text.trim();
    session.update(session.user!.withAbout(about.isEmpty ? null : about));
    context.pop();
    messenger.showSnackBar(const SnackBar(
      content: Text('Saved in this preview only. Nothing was sent to the school.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    final label = text.labelMedium?.copyWith(color: AppColors.muted);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('Edit Profile', style: text.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
                  Center(
                    child: UserAvatar(name: user.fullName, imageAsset: user.photoAsset, size: 96),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text("Changing your photo isn't available in this preview yet.",
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.section),
                  Text('About', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _about,
                    maxLength: EditProfileScreen.aboutMaxLength,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'A short line about you'),
                    onChanged: (_) => setState(() {}), // re-check the Save button
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Set by the school', style: label),
                  const SizedBox(height: AppSpacing.sm),
                  _locked('Name', user.fullName),
                  _locked('Program', user.designation),
                  _locked('ID', user.maskedId),
                  _locked('Tags and memberships', '${user.tags.length} official tags'),
                  const SizedBox(height: AppSpacing.sm),
                  Text("These come from school records and can't be changed here.",
                      style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _changed ? _save : null,
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locked(String label, String value) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                Text(value, style: text.bodyLarge),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.muted),
        ],
      ),
    );
  }
}
