import 'package:url_launcher/url_launcher.dart';
import 'app_toast.dart';

/// Opens an external link (Telegram, YouTube, any http/https or app scheme) in
/// the relevant app/browser. Fails gracefully with a toast instead of crashing.
class AppLinks {
  AppLinks._();

  static Future<void> open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppToast.error('Invalid link');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) AppToast.error('Could not open the link');
    } catch (_) {
      AppToast.error('Could not open the link');
    }
  }
}
