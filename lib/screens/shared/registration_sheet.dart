import 'package:flutter/material.dart';

import '../../models/campus.dart';
import '../../models/guest.dart';
import '../../models/user_profile.dart';
import '../../services/campus_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/dates.dart';

/// Event registration pop-up (spec §7.3), shown inside [AppSheetPage].
///
/// The name comes from the school record and can't be edited here. Course and
/// year level are dropdowns, filled in from the user's program when it
/// matches a choice. Nothing is saved anywhere but this preview.
class RegistrationSheet extends StatefulWidget {
  final CampusService campusService;
  final String eventId;

  const RegistrationSheet({super.key, required this.campusService, required this.eventId});

  @override
  State<RegistrationSheet> createState() => _RegistrationSheetState();
}

class _RegistrationSheetState extends State<RegistrationSheet> {
  Future<CampusEvent?>? _event;
  String? _course;
  String? _year;
  bool _started = false;
  bool _submitting = false;
  String? _error; // shown under the fields; never a fake success

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final user = SessionScope.of(context).user;
    if (user == null) return;
    _event = widget.campusService.loadEvent(user, widget.eventId);
    // "BS Computer Science · 3rd Year" → preselect what matches the lists.
    final parts = user.designation.split('·').map((p) => p.trim()).toList();
    if (parts.isNotEmpty && registrationCourses.contains(parts.first)) _course = parts.first;
    if (parts.length > 1 && registrationYearLevels.contains(parts[1])) _year = parts[1];
  }

  void _reloadEvent() {
    final user = SessionScope.of(context).user!;
    setState(() => _event = widget.campusService.loadEvent(user, widget.eventId));
  }

  Future<void> _submit(UserProfile user) async {
    final course = _course;
    final year = _year;
    if (course == null || year == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.campusService.registerForEvent(user, widget.eventId,
          course: course, yearLevel: year);
      if (!mounted) return;
      final session = SessionScope.of(context);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      session.refresh(); // event page and guest list reload
      messenger.showSnackBar(const SnackBar(
        content: Text('Registered in this preview only. Nothing was sent to the school.'),
      ));
    } on RegistrationException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = "Couldn't register. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const SizedBox.shrink(); // preview just ended
    final text = Theme.of(context).textTheme;
    final label = text.labelMedium?.copyWith(color: AppColors.muted);

    return FutureBuilder<CampusEvent?>(
      future: _event,
      builder: (context, snap) {
        if (snap.hasError) {
          return _padded(Column(
            children: [
              const Text("Couldn't load this event."),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: _reloadEvent, child: const Text('Retry')),
            ],
          ));
        }
        if (snap.connectionState != ConnectionState.done) {
          return _padded(const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator())));
        }
        final event = snap.data;
        if (event == null) {
          return _padded(Text("This event isn't available.",
              style: text.bodyLarge?.copyWith(color: AppColors.muted)));
        }
        final ready = _course != null && _year != null && !_submitting;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('${formatDayMonth(event.start)} · ${formatTime(event.start)}',
                  style: text.bodyMedium?.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.lg),
              Text('Name', style: label),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(user.fullName, style: text.bodyLarge)),
                    const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.muted),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Course', style: label),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceField(
                value: _course,
                hint: 'Select your course',
                options: registrationCourses,
                onChanged: (v) => setState(() {
                  _course = v;
                  _error = null;
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Year level', style: label),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceField(
                value: _year,
                hint: 'Select your year level',
                options: registrationYearLevels,
                onChanged: (v) => setState(() {
                  _year = v;
                  _error = null;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!,
                      style: text.bodyMedium?.copyWith(color: AppColors.red)),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: ready ? () => _submit(user) : null,
                  child: Text(_submitting ? 'Registering…' : 'Confirm registration'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Preview only: nothing is sent to the school.',
                  style: text.bodyMedium?.copyWith(color: AppColors.muted)),
            ],
          ),
        );
      },
    );
  }

  Widget _padded(Widget child) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: child,
      );
}

/// A dropdown that looks like the app's other inputs (light gray, rounded).
class _ChoiceField extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _ChoiceField({
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(AppRadius.large),
          dropdownColor: AppColors.white,
          hint: Text(hint, style: const TextStyle(color: AppColors.muted)),
          items: [
            for (final o in options) DropdownMenuItem<String>(value: o, child: Text(o)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
