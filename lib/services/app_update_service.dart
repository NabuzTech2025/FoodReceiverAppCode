import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:new_version_plus/new_version_plus.dart';

class AppUpdateService {
  static const String _androidPackageName = 'com.food.mandeep.food_app'; // Replace with your actual package name
  static const String _iosAppId = '6747834218'; // Your actual App Store ID
  static const String _iosAppStoreUrl = 'https://apps.apple.com/in/app/magskr-food-app/id6747834218'; // Your actual App Store URL

  static Future<void> checkForUpdates(BuildContext context) async {
    print("🔄 ========== APP UPDATE CHECK STARTED ==========");
    print("🔄 Platform: ${Platform.operatingSystem}");
    print("🔄 Time: ${DateTime.now()}");

    try {
      final newVersion = NewVersionPlus(
        androidId: _androidPackageName,
        iOSId: _iosAppId,
      );

      final status = await newVersion.getVersionStatus();

      if (status != null) {
        print("📱 Local Version: ${status.localVersion}");
        print("🎯 Store Version: ${status.storeVersion}");
        print("🪩 Store Link: ${status.appStoreLink}");
        print("⚖️ Can Update: ${status.canUpdate}");

        if (status.canUpdate) {
          print("🚀 Update available! Showing dialog...");
          _showUpdateDialog(context, status.localVersion, status.storeVersion,
                  () async {
                // Use your actual App Store link for iOS
                final uri = Platform.isIOS
                    ? Uri.parse(_iosAppStoreUrl)
                    : Uri.parse(status.appStoreLink);

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              });
        } else {
          print("✅ App is up to date");
        }
      } else {
        print("❌ Could not fetch version status from store");
      }
    } catch (e, stackTrace) {
      print("❌ Error checking for updates: $e");
      print("❌ Stack trace: $stackTrace");

      // Fallback for testing - using your actual links
      print("🔄 Showing fallback update dialog for testing...");
      _showUpdateDialog(context, '1.0.0', '1.0.1', () async {
        final uri = Uri.parse(
            Platform.isAndroid
                ? 'https://play.google.com/store/apps/details?id=$_androidPackageName'
                : _iosAppStoreUrl); // Using your actual iOS App Store URL
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      });
    }

    print("🔄 ========== APP UPDATE CHECK ENDED ==========");
  }

  static void _showUpdateDialog(BuildContext context, String currentVersion,
      String latestVersion, VoidCallback onUpdate)
  {
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
                    'Please update to continue using the app with the latest features and bug fixes.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _exitApp();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onUpdate();
                },
                child: const Text('Update'),
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

  // Force update dialog - also using your actual App Store link
  static void showForceUpdateDialog(
      BuildContext context, VoidCallback? customUpdate) {
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
                  'This version of the app is no longer supported. Please update to the latest version to continue.'),
              actions: [
                ElevatedButton(
                  onPressed: customUpdate ?? () async {
                    final uri = Uri.parse(
                        Platform.isAndroid
                            ? 'https://play.google.com/store/apps/details?id=$_androidPackageName'
                            : _iosAppStoreUrl); // Using your actual iOS App Store URL
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
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