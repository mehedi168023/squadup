import 'package:flutter/foundation.dart';

/// Centralized, structured logging utility for SquadUp.
/// In release mode, verbose/debug logs are completely muted.
class AppLogger {
  AppLogger._();

  static void debug(String tag, String message) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print('🟢 [SquadUp - DEBUG] [$tag] $message');
    }
  }

  static void info(String tag, String message) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print('🔵 [SquadUp - INFO] [$tag] $message');
    }
  }

  static void error(String tag, String message, [dynamic error, StackTrace? stack]) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print('🔴 [SquadUp - ERROR] [$tag] $message');
      if (error != null) {
        // ignore: avoid_print
        print('   Details: $error');
      }
      if (stack != null) {
        // ignore: avoid_print
        print('   Stack:\n$stack');
      }
    }
  }
}
