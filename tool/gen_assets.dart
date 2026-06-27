// Generates all branding assets from the SquadUp master logo.
// Run: dart run tool/gen_assets.dart
import 'dart:io';
import 'package:image/image.dart' as img;

const navyR = 0x0E, navyG = 0x0C, navyB = 0x18; // #0E0C18 brand background

void main() {
  final master = img.decodePng(
    File('assets/branding/squadup_master.png').readAsBytesSync(),
  )!;
  print('master: ${master.width}x${master.height}');

  // 1) icon_full.png — 1024² square, logo composited on the brand navy so the
  //    transparent corners are filled (needed for iOS / web full-bleed icons).
  final m1024 = img.copyResize(master,
      width: 1024, height: 1024, interpolation: img.Interpolation.cubic);
  final full = img.Image(width: 1024, height: 1024);
  img.fill(full, color: img.ColorRgb8(navyR, navyG, navyB));
  img.compositeImage(full, m1024);
  _save('assets/branding/icon_full.png', full);

  // 2) icon_foreground.png — transparent canvas, logo scaled to the adaptive
  //    safe-zone (~82%) and centered (Android adaptive foreground layer).
  const fgScale = 0.82;
  final side = (1024 * fgScale).round();
  final off = ((1024 - side) / 2).round();
  final scaled = img.copyResize(master,
      width: side, height: side, interpolation: img.Interpolation.cubic);
  final fg = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.compositeImage(fg, scaled, dstX: off, dstY: off);
  _save('assets/branding/icon_foreground.png', fg);

  // 3) icon_monochrome.png — white silhouette of the bright logo art on
  //    transparent (Android 13 themed icon + notification status-bar icon).
  final mono = img.Image(width: 1024, height: 1024, numChannels: 4);
  for (var y = 0; y < scaled.height; y++) {
    for (var x = 0; x < scaled.width; x++) {
      final p = scaled.getPixel(x, y);
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      if (p.a > 40 && lum > 70) {
        mono.setPixelRgba(x + off, y + off, 255, 255, 255, 255);
      }
    }
  }
  _save('assets/branding/icon_monochrome.png', mono);
  _save('assets/branding/notification_icon.png', mono);

  // 4) splash_logo.png — logo (transparent corners) for the native splash.
  final splash = img.copyResize(master,
      width: 820, height: 820, interpolation: img.Interpolation.cubic);
  _save('assets/branding/splash_logo.png', splash);

  // 5) Replace the in-app logo so every in-app reference shows SquadUp.
  _save('assets/images/logo.png', m1024);

  print('All branding assets generated.');
}

void _save(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
  print('  wrote $path (${image.width}x${image.height})');
}
