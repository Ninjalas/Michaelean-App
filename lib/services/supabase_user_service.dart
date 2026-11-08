import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock/mock_people.dart';
import '../models/user_profile.dart';
import 'user_service.dart';

/// Real test accounts (docs/backend-plan.md, Stage 1): sign-in, sign-out and
/// password changes go to Supabase, and the profile is read from the
/// `profiles` table. The sample-data preview still works, inherited from
/// [MockUserService], for teachers until their accounts exist.
class SupabaseUserService extends MockUserService {
  SupabaseUserService({super.campus});

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  Future<UserProfile?> restoreSignIn() async {
    if (_auth.currentSession == null) return null;
    try {
      return await _loadProfile();
    } on Object {
      // Saved sign-in no longer works (e.g. account removed): start fresh.
      await _auth.signOut();
      return null;
    }
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (e) {
      throw SignInException(_message(e));
    }
    try {
      return await _loadProfile();
    } on Object {
      await _auth.signOut();
      throw const SignInException("Signed in, but your profile couldn't be loaded. Try again.");
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> changePassword(String current, String next) async {
    final email = _auth.currentUser?.email;
    if (email == null) throw const SignInException('You are signed out. Sign in again.');
    try {
      // Re-checking the current password stops someone holding an unlocked phone.
      await _auth.signInWithPassword(email: email, password: current);
    } on AuthException catch (e) {
      throw SignInException(e.code == 'invalid_credentials'
          ? 'Your current password is wrong.'
          : _message(e));
    }
    try {
      await _auth.updateUser(UserAttributes(password: next));
    } on AuthException catch (e) {
      throw SignInException(_message(e));
    }
  }

  Future<UserProfile> _loadProfile() async {
    final db = Supabase.instance.client;
    final id = _auth.currentUser!.id;
    final row = await db.from('profiles').select().eq('id', id).single();
    final qr = await db.from('qr_tokens').select('token').eq('user_id', id).single();
    final user = profileFromRow(row, qr['token'] as String);
    return campus?.withAffiliations(user) ?? user;
  }

  static String _message(AuthException e) {
    if (e is AuthRetryableFetchException) {
      return "Couldn't reach the server. Check your internet connection and try again.";
    }
    return switch (e.code) {
      'invalid_credentials' => 'Wrong email or password.',
      'same_password' => 'The new password must be different from the current one.',
      'weak_password' => 'That password is too weak. Use at least 8 characters.',
      'over_request_rate_limit' || 'over_email_send_rate_limit' =>
        'Too many tries. Wait a few minutes and try again.',
      _ => 'Something went wrong (${e.message}). Try again.',
    };
  }
}

const _programNames = {
  'BSCS': 'BS Computer Science',
  'ACS': 'Associate in Computer Science',
  'ACT-CS': 'Associate in Computer Technology (CS)',
  'ACT-IT': 'Associate in Computer Technology (IT)',
};

const _years = {1: '1st Year', 2: '2nd Year', 3: '3rd Year', 4: '4th Year'};

/// Turns a `profiles` row into the app's [UserProfile]. Students only for now;
/// club and officer tags are added from member lists (Stage 3).
UserProfile profileFromRow(Map<String, dynamic> row, String qrToken) {
  final suffix = row['suffix'] as String?;
  final last = row['last_name'] as String;
  return UserProfile(
    id: row['id'] as String,
    role: row['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
    firstName: row['first_name'] as String,
    lastName: suffix == null ? last : '$last $suffix', // e.g. "Diolata III"
    designation:
        '${_programNames[row['program']] ?? row['program']} · ${_years[row['year_level']] ?? ''}',
    maskedId: row['masked_id'] as String,
    email: row['email'] as String,
    qrToken: qrToken,
    about: row['about'] as String?,
    tags: mockSampleStudentTags,
  );
}
