import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_header.dart';

/// Change password (docs/backend-plan.md, Stage 1): for test accounts only.
/// The current password is checked first; the change is saved in Supabase.
class ChangePasswordScreen extends StatefulWidget {
  final UserService userService;

  const ChangePasswordScreen({super.key, required this.userService});

  static const minLength = 8;

  /// What's wrong with the entries, or null when they can be sent.
  static String? problem(String current, String next, String confirm) {
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) return 'Fill in all three fields.';
    if (next.length < minLength) return 'Use at least $minLength characters.';
    if (next == current) return 'The new password must be different from the current one.';
    if (next != confirm) return "The new passwords don't match.";
    return null;
  }

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final problem = ChangePasswordScreen.problem(_current.text, _next.text, _confirm.text);
    setState(() => _error = problem);
    if (problem != null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.userService.changePassword(_current.text, _next.text);
      if (!mounted) return;
      context.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Password changed. Use the new one next time you sign in.')));
    } on SignInException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Widget _field(String label, TextEditingController c, List<String> hints,
          {TextInputAction action = TextInputAction.next}) =>
      TextField(
        controller: c,
        enabled: !_busy,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: hints,
        textInputAction: action,
        onSubmitted: action == TextInputAction.done ? (_) => _save() : null,
        decoration: InputDecoration(labelText: label),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader('Change password'),
            Expanded(
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: [
                    _field('Current password', _current, const [AutofillHints.password]),
                    const SizedBox(height: AppSpacing.sm),
                    _field('New password', _next, const [AutofillHints.newPassword]),
                    const SizedBox(height: AppSpacing.sm),
                    _field('Type the new password again', _confirm,
                        const [AutofillHints.newPassword],
                        action: TextInputAction.done),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(_error!,
                          style: text.bodyMedium?.copyWith(color: AppColors.red),
                          semanticsLabel: 'Error: $_error'),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'At least ${ChangePasswordScreen.minLength} characters. Don\'t reuse your '
                      'Microsoft 365 password: this test account is separate from it.',
                      style: muted,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Changing…' : 'Change password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
