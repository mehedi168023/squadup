import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Resolves the app's root [OverlayState] safely so global, context-free UI
/// (heads-up banners, the loading overlay) can be inserted from anywhere —
/// including controllers and services that hold no [BuildContext].
///
/// Why not the usual `Overlay.of(Get.overlayContext!)`? That throws
/// *"No Overlay widget found"* whenever the resolved context has no Overlay
/// ancestor — which is exactly what happens mid route-transition right after
/// `Get.offAllNamed` (when the post-login welcome banner fires). Here we read
/// the root navigator's [OverlayState] directly and fall back to a null-safe
/// `Overlay.maybeOf`, returning `null` instead of crashing the app.
OverlayState? rootOverlayState() {
  // The GetMaterialApp navigator owns the root overlay — read it straight from
  // the navigator state so we never call `Overlay.of` on a context whose
  // nearest Overlay ancestor may not exist yet.
  final navOverlay = Get.key.currentState?.overlay;
  if (navOverlay != null) return navOverlay;

  // Fallback: resolve via the overlay context, but null-safely.
  final ctx = Get.overlayContext;
  if (ctx != null) return Overlay.maybeOf(ctx, rootOverlay: true);

  return null;
}
