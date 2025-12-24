import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:upgrader/upgrader.dart';

class AppUpdateService {
  static const String _androidPackageName = 'com.food.mandeep.food_app';
  static const String _iosAppId = '6747834218';
  static const String _iosAppStoreUrl = 'https://apps.apple.com/in/app/magskr-food-app/id6747834218';

  static bool _isChecking = false;
  static DateTime? _lastCheckTime;
  static const bool _hasShownInitialCheck = false;
  static Future<void> checkForUpdates(BuildContext context) async {
    // ✅ ADD: Prevent duplicate checks
    if (_isChecking) {
      print("⏭️ Update check already in progress, skipping");
      return;
    }

    // ✅ ADD: Don't check more than once per minute
    if (_lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < const Duration(minutes: 1)) {
      print("⏭️ Update check done recently, skipping");
      return;
    }

    if (!context.mounted) {
      print("⚠️ Context not mounted, skipping update check");
      return;
    }

    _isChecking = true;
    _lastCheckTime = DateTime.now();

    print("🔄 ========== APP UPDATE CHECK STARTED ==========");
    print("🔄 Platform: ${Platform.operatingSystem}");
    print("🔄 Time: ${DateTime.now()}");

    try {
      final upgrader = Upgrader(
        countryCode: 'IN',
        debugDisplayAlways: false,
        debugLogging: true,
        durationUntilAlertAgain: const Duration(days: 1),
      );

      await upgrader.initialize();

      final blocked = upgrader.blocked();
      print("🚫 Blocked (Force Update): $blocked");

      final shouldDisplayUpgrade = upgrader.shouldDisplayUpgrade();
      print("📱 Should Display Upgrade: $shouldDisplayUpgrade");

      if (blocked) {
        print("⚠️ Force update required!");
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          _showForceUpdateDialog(context);
        }
      } else if (shouldDisplayUpgrade) {
        print("🚀 Update available! Showing dialog...");
        final appStoreVersion = upgrader.currentAppStoreVersion ?? 'Unknown';
        final installedVersion = upgrader.currentInstalledVersion ?? 'Unknown';

        print("📱 Local Version: $installedVersion");
        print("🎯 Store Version: $appStoreVersion");

        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          _showUpdateDialog(
              context,
              installedVersion,
              appStoreVersion,
                  () => _launchStore()
          );
        }
      } else {
        print("✅ App is up to date");
      }
    } catch (e, stackTrace) {
      print("❌ Error checking for updates: $e");
      print("❌ Stack trace: $stackTrace");
    } finally {
      _isChecking = false; // ✅ ADD: Reset flag
    }

    print("🔄 ========== APP UPDATE CHECK ENDED ==========");
  }


  static Future<void> _launchStore() async {
    try {
      final uri = Uri.parse(
          Platform.isAndroid
              ? 'https://play.google.com/store/apps/details?id=$_androidPackageName'
              : _iosAppStoreUrl
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print("✅ Store opened successfully");
      } else {
        print("❌ Could not launch store");
      }
    } catch (e) {
      print("❌ Error launching store: $e");
    }
  }

  static void _showUpdateDialog(
      BuildContext context,
      String currentVersion,
      String latestVersion,
      VoidCallback onUpdate
      ) {
    print("📱 ========== SHOWING UPDATE DIALOG ==========");
    print("📱 Current: $currentVersion");
    print("📱 Latest: $latestVersion");
    print("📱 Context available: ${context.mounted}");

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('App Update Available'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A new version of the app is available.'),
                const SizedBox(height: 16),
                Text('Current Version: $currentVersion'),
                Text('Latest Version: $latestVersion'),
                const SizedBox(height: 16),
                const Text(
                  'Please update to continue using the app with the latest features and bug fixes.',
                ),
              ],
            ),
            actions: [
              // TextButton(
              //   onPressed: () {
              //     Navigator.of(context).pop();
              //   },
              //   child: const Text('Later'),
              // ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onUpdate();
                },
                child: const Text('Update Now'),
              ),
            ],
          );
        },
      );
      print("✅ Update dialog shown successfully");
    } catch (e, stackTrace) {
      print("❌ Error showing update dialog: $e");
      print("❌ Stack trace: $stackTrace");
    }
  }

  static void _showForceUpdateDialog(BuildContext context) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: const Text('Update Required'),
              content: const Text(
                'This version of the app is no longer supported. Please update to the latest version to continue.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _launchStore();
                  },
                  child: const Text('Update Now'),
                ),
              ],
            ),
          );
        },
      );
      print("✅ Force update dialog shown successfully");
    } catch (e) {
      print("❌ Error showing force update dialog: $e");
    }
  }

  static void _exitApp() {
    try {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        exit(0);
      }
    } catch (e) {
      print("❌ Error exiting app: $e");
    }
  }

  // Direct force update dialog - public method
  static void showForceUpdateDialog(
      BuildContext context,
      VoidCallback? customUpdate
      ) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: const Text('Update Required'),
              content: const Text(
                'This version of the app is no longer supported. Please update to the latest version to continue.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: customUpdate ?? () => _launchStore(),
                  child: const Text('Update Now'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("❌ Error showing force update dialog: $e");
    }
  }
}