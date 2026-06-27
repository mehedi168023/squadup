import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/core/app_toast.dart';
import '../../app/data/services/notification_service.dart';
import '../../app/data/services/notifications/notif_platform.dart';
import '../../app/data/services/permission_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/responsive.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  bool _isNotificationGranted = false;
  bool _isPhotosGranted = false;
  bool _isStorageGranted = false;
  bool _isBatteryOptimizationIgnored = false;
  
  Map<String, dynamic> _lastTriggeredPayload = {};
  Timer? _backgroundTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _checkDiagnostics();
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkDiagnostics() async {
    final notif = await Permission.notification.isGranted;
    final photos = kIsWeb ? true : await Permission.photos.isGranted;
    final storage = kIsWeb ? true : await Permission.storage.isGranted;
    final battery = await PermissionService.to.isBatteryOptimizationIgnored();

    setState(() {
      _isNotificationGranted = notif;
      _isPhotosGranted = photos;
      _isStorageGranted = storage;
      _isBatteryOptimizationIgnored = battery;
    });
  }

  void _updatePayload(String type, Map<String, dynamic> payload) {
    setState(() {
      _lastTriggeredPayload = {
        'test_type': type,
        'timestamp': DateTime.now().toIso8601String(),
        ...payload,
      };
    });
  }

  Future<void> _triggerForegroundTest() async {
    final payload = {
      'target': 'wallet',
      'args': {'source': 'foreground_test'}
    };
    _updatePayload('Foreground standard', payload);

    await NotificationService.to.notifier.show(
      id: 101,
      title: 'SquadUp Match Alert 🏆',
      body: 'Your match "BR Solo Time" is starting in 10 minutes. Click to view!',
      payload: payload,
    );
    AppToast.success('Foreground Notification Triggered!');
  }

  void _triggerBackgroundTest() {
    setState(() {
      _secondsLeft = 4;
    });
    AppToast.info('Press the HOME button now to put app in background!');

    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _secondsLeft--;
      });

      if (_secondsLeft <= 0) {
        timer.cancel();
        final payload = {
          'target': 'my_matches',
          'args': {'source': 'background_test'}
        };
        _updatePayload('Background delayed', payload);

        await NotificationService.to.notifier.show(
          id: 102,
          title: 'Tournament Live! 🎮',
          body: 'Ludo match room is open. Join now before time runs out.',
          payload: payload,
        );
      }
    });
  }

  Future<void> _triggerImageTest() async {
    final payload = {
      'target': 'products',
      'args': {'source': 'rich_image_test'}
    };
    _updatePayload('Rich Image Notification', payload);

    // Using a sample public high-quality placeholder tournament banner image
    const imageUrl = 'https://picsum.photos/id/29/800/400';

    await NotificationService.to.notifier.show(
      id: 103,
      title: 'New Store Discount! 🛍️',
      body: 'Get 25% off on Atom63 Mechanical Keyboards! Tap to view.',
      image: imageUrl,
      payload: payload,
    );
    AppToast.success('Rich Image Notification Triggered!');
  }

  Future<void> _triggerActionsTest() async {
    final payload = {
      'target': 'deposit',
      'args': {'source': 'actions_test'}
    };
    _updatePayload('Notification Action Buttons', payload);

    final actions = [
      const NotificationAction(
        id: 'act_deposit',
        title: 'Add Money',
      ),
      const NotificationAction(
        id: 'act_dismiss',
        title: 'Dismiss',
      ),
    ];

    await NotificationService.to.notifier.show(
      id: 104,
      title: 'Low Wallet Balance ⚠️',
      body: 'Your balance is below ৳50. Add money now to join matches.',
      actions: actions,
      payload: payload,
    );
    AppToast.success('Action Buttons Notification Triggered!');
  }

  Future<void> _triggerDeepLinkTest() async {
    final payload = {
      'target': 'match',
      'args': {'matchId': 1}
    };
    _updatePayload('Deep Link / Router', payload);

    await NotificationService.to.notifier.show(
      id: 105,
      title: 'Match Details Update 📊',
      body: 'Match UID has been updated. Click to inspect your match details.',
      payload: payload,
    );
    AppToast.success('Deep Link Route Notification Triggered!');
  }

  Future<void> _handleBatteryOptimization() async {
    final result = await PermissionService.to.requestDisableBatteryOptimization();
    if (result) {
      AppToast.success('Battery optimization disabled!');
    } else {
      AppToast.info('Exemption not granted / cancelled.');
    }
    _checkDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing', style: AppTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
          children: [
            const SectionHeader('SYSTEM DIAGNOSTICS'),
            const SizedBox(height: 10),
            _buildDiagnosticsCard(),
            const SizedBox(height: 20),
            if (_secondsLeft > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.killRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.killRed.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.killRed),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Triggering Background Test in $_secondsLeft seconds...\nGO TO HOME SCREEN NOW!',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.killRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SectionHeader('TRIGGER TEST CASES'),
            const SizedBox(height: 10),
            _buildTestCasesCard(),
            const SizedBox(height: 20),
            const SectionHeader('CHANNEL SPECIFICATION'),
            const SizedBox(height: 10),
            _buildChannelSpecCard(),
            const SizedBox(height: 20),
            const SectionHeader('PAYLOAD INSPECTION'),
            const SizedBox(height: 10),
            _buildPayloadInspectorCard(),
            const SizedBox(height: 20),
            const SectionHeader('OEM COMPATIBILITY & TROUBLESHOOTING'),
            const SizedBox(height: 10),
            _buildOEMCompatibilityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsCard() {
    return AppCard(
      child: Column(
        children: [
          _buildDiagnosticRow(
            'Notification Permission',
            _isNotificationGranted,
            onFix: () async {
              await PermissionService.to.requestAll();
              _checkDiagnostics();
            },
          ),
          const Divider(height: 24),
          _buildDiagnosticRow(
            'Photos Access (Android 13+)',
            _isPhotosGranted,
            onFix: () async {
              await Permission.photos.request();
              _checkDiagnostics();
            },
          ),
          const Divider(height: 24),
          _buildDiagnosticRow(
            'Storage Access (Legacy)',
            _isStorageGranted,
            onFix: () async {
              await Permission.storage.request();
              _checkDiagnostics();
            },
          ),
          const Divider(height: 24),
          _buildDiagnosticRow(
            'Battery Optimization Disabled',
            _isBatteryOptimizationIgnored,
            subtitle: 'Prevents OS from killing background tasks',
            fixLabel: 'DISABLE OPT',
            onFix: _handleBatteryOptimization,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(
    String title,
    bool isHealthy, {
    String? subtitle,
    String fixLabel = 'ENABLE',
    required VoidCallback onFix,
  }) {
    return Row(
      children: [
        Icon(
          isHealthy ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isHealthy ? AppColors.winningTeal : AppColors.killRed,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isHealthy ? null : AppColors.textSecondary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (!isHealthy)
          SizedBox(
            height: 32,
            child: TextButton(
              onPressed: onFix,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(fixLabel),
            ),
          )
        else
          Text(
            'ACTIVE',
            style: AppTextStyles.label.copyWith(
              color: AppColors.winningTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildTestCasesCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTestButton(
            '1. Trigger Foreground Heads-Up',
            'Trigger instant system and in-app banner alert',
            Icons.phonelink_ring_rounded,
            _triggerForegroundTest,
          ),
          const SizedBox(height: 12),
          _buildTestButton(
            '2. Trigger Background Delayed (4s)',
            'Trigger peeking notification while app is closed',
            Icons.timer_outlined,
            _triggerBackgroundTest,
          ),
          const SizedBox(height: 12),
          _buildTestButton(
            '3. Trigger Rich Image Preview',
            'Download and present tournament banner preview',
            Icons.image_outlined,
            _triggerImageTest,
          ),
          const SizedBox(height: 12),
          _buildTestButton(
            '4. Trigger Action Buttons',
            'Display utility action choices inside notification drawer',
            Icons.smart_button_rounded,
            _triggerActionsTest,
          ),
          const SizedBox(height: 12),
          _buildTestButton(
            '5. Trigger Deep Link Route payload',
            'Deliver payload to jump directly to target screen',
            Icons.alt_route_rounded,
            _triggerDeepLinkTest,
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.body2.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSpecCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecRow('Channel ID', 'urgent_notifications'),
          const Divider(height: 20),
          _buildSpecRow('Channel Name', 'Important Notifications'),
          const Divider(height: 20),
          _buildSpecRow('Importance', 'Importance.max (Level 5)'),
          const Divider(height: 20),
          _buildSpecRow('Priority', 'Priority.max (Level 2)'),
          const Divider(height: 20),
          _buildSpecRow('Vibration & Lights', 'ENABLED'),
          const Divider(height: 20),
          _buildSpecRow('Lock Screen Visibility', 'NotificationVisibility.public'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
        Text(value, style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPayloadInspectorCard() {
    final payloadStr = _lastTriggeredPayload.isEmpty
        ? 'No test notifications triggered yet.'
        : const JsonEncoder.withIndent('  ').convert(_lastTriggeredPayload);

    return AppCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            payloadStr,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.winningTeal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOEMCompatibilityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️ Known Vendor Limitations',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          _buildOEMText('Xiaomi / Redmi', 'Requires enabling "Autostart" and "Display pop-up windows while running in the background" in Settings > Apps.'),
          const SizedBox(height: 6),
          _buildOEMText('Samsung', 'Deep sleep apps are prohibited from receiving push alerts. Suggest checking settings under Settings > Device Care > Battery > Sleeping apps.'),
          const SizedBox(height: 6),
          _buildOEMText('Oppo / Vivo / Realme', 'Strict battery saving kills background push handlers. Turn off Smart Power Saving and lock the app in the recent apps tray.'),
          const SizedBox(height: 6),
          _buildOEMText('Huawei', 'Power Genius frequently disrupts background FCM. Ensure battery optimizations are set to "Don\'t optimize".'),
        ],
      ),
    );
  }

  Widget _buildOEMText(String oem, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(oem, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(desc, style: AppTextStyles.body2.copyWith(fontSize: 12)),
      ],
    );
  }
}
