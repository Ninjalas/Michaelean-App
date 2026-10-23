import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:michaelean_app/services/hint_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs before every test file: a fresh device storage for each test, so
/// screens that read saved settings never wait on a real one. The one-time
/// QR tip counts as seen, so it doesn't cover what tests tap.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() => SharedPreferences.setMockInitialValues({HintStore.quickQr: true}));
  await testMain();
}
