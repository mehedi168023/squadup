import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app/core/app_constants.dart';
import 'app/core/initial_binding.dart';
import 'app/core/theme_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_colors.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // Register always-on services once, before the first frame, so `.to`
  // accessors resolve immediately. Doing it here (instead of inside build())
  // keeps it off the rebuild path — the Obx below re-runs build() on every
  // theme toggle, and we don't want to re-enter the binding each time.
  InitialBinding().dependencies();
  runApp(const SquadUpApp());
}

class SquadUpApp extends StatelessWidget {
  const SquadUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.to.mode.value,
          initialRoute: AppRoutes.splash,
          getPages: AppPages.routes,
          // Premium iOS-style page motion: parallax slide + swipe-back, tuned
          // snappy (260ms) so navigation feels fast yet smooth. (Per-route
          // transitions in AppPages override this; it's only a fallback.)
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaqueRoute: true,
          builder: (context, child) {
            // Scale typography to the device width (≈420dp reference) so every
            // screen stays pixel-stable and compact: it shrinks on small phones
            // to avoid overflow and is hard-capped on large screens. One global
            // lever → consistent sizing across all devices.
            final media = MediaQuery.of(context);
            final factor = (media.size.width / 420).clamp(0.85, 1.0);
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(factor)),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ));
  }
}
