/// Picks the right LocalNotifier at compile time: the native (mobile)
/// implementation when `dart:io` exists, otherwise the web no-op stub.
/// This keeps flutter_local_notifications out of the web build entirely.
library;

export 'notif_stub.dart' if (dart.library.io) 'notif_native.dart';
