import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/session.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/segmented_pills.dart';

/// Sign-in (docs/backend-plan.md, Stage 1): the department's test accounts,
/// `FirstName.LastName@smcl.edu.ph` with a password given by the team. Below
/// it, the sample-data preview (spec §1.1) stays for teachers until their
/// accounts exist. Neither is Microsoft 365 sign-in.
class PreviewScreen extends StatefulWidget {
  final UserService userService;

  const PreviewScreen({super.key, required this.userService});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.student;
  bool _busy = true; // checking for a saved sign-in first
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Signed in last time? Go straight in.
  Future<void> _restore() async {
    final user = await widget.userService.restoreSignIn();
    if (!mounted) return;
    if (user != null) return SessionScope.of(context).signIn(user);
    setState(() => _busy = false);
  }

  Future<void> _signIn() async {
    if (_busy) return;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await widget.userService.signIn(_email.text, _password.text);
      if (mounted) SessionScope.of(context).signIn(user);
    } on SignInException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _preview() async {
    setState(() => _busy = true);
    final user = await widget.userService.loadPreviewUser(_role);
    if (!mounted) return;
    SessionScope.of(context).startPreview(user);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.muted);
    return Scaffold(
      body: SafeArea(
        // Fills the screen when it fits; scrolls on short screens or large text.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const SizedBox(height: AppSpacing.lg),
                      Hero(
                        tag: 'smcl-emblem', // glides in from the opening intro
                        child: Image.asset('assets/images/SMCL_Emblem.png', height: 104,
                            semanticLabel: "Saint Michael's College of Laguna emblem"),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Michaelean', textAlign: TextAlign.center, style: text.displaySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text("Saint Michael's College of Laguna",
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(color: AppColors.muted)),
                      const Spacer(),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username, AutofillHints.email],
                        decoration: const InputDecoration(
                            labelText: 'School email', hintText: 'FirstName.LastName@smcl.edu.ph'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: !_showPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.go,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _signIn(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: _showPassword ? 'Hide password' : 'Show password',
                            icon: Icon(_showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(_error!,
                            style: text.bodyMedium?.copyWith(color: AppColors.red),
                            semanticsLabel: 'Error: $_error'),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _busy ? null : _signIn,
                        child: const Text('Sign in'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Test account for the Computer Science department trial. Use the '
                        'password the team gave you. It is not your Microsoft password.',
                        textAlign: TextAlign.center,
                        style: muted,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(color: AppColors.hairline),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Or preview with sample data', textAlign: TextAlign.center, style: muted),
                      const SizedBox(height: AppSpacing.md),
                      SegmentedPills<UserRole>(
                        segments: const [(UserRole.student, 'Student'), (UserRole.teacher, 'Teacher')],
                        selected: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: _busy ? null : _preview,
                        child: const Text('Open preview'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Preview only: no account, sample data, not official school records.',
                          textAlign: TextAlign.center, style: muted),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
