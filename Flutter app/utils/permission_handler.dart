import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AppPermissions {
  /// Get Android SDK version
  static Future<int> getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  /// Request storage permission for Android 10+ (API 29+)
  static Future<bool> requestStoragePermission() async {
    final sdkVersion = await getAndroidSdkVersion();
    debugPrint('Requesting storage permission for Android SDK $sdkVersion');
    
    if (sdkVersion >= 33) {
      // Android 13+ (API 33+) use granular media permissions
      // For PDF downloads, we don't need media permissions, but check if any are granted
      final hasAnyMediaPermission = await Permission.photos.isGranted || 
                                   await Permission.videos.isGranted || 
                                   await Permission.audio.isGranted;
      
      if (!hasAnyMediaPermission) {
        // Try to request storage permission as fallback
        final status = await Permission.storage.request();
        debugPrint('Storage permission result (Android 13+): ${status.isGranted}');
        return status.isGranted;
      }
      return true;
    } else {
      // Android 12 and below use traditional storage permission
      if (!await Permission.storage.isGranted) {
        final status = await Permission.storage.request();
        debugPrint('Storage permission result (Android <=12): ${status.isGranted}');
        return status.isGranted;
      }
      return true;
    }
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    final sdkVersion = await getAndroidSdkVersion();
    
    if (sdkVersion >= 33) {
      // Android 13+ - check if any media permission is granted or storage permission
      return await Permission.storage.isGranted || 
             await Permission.photos.isGranted || 
             await Permission.videos.isGranted || 
             await Permission.audio.isGranted;
    } else {
      // Android 12 and below
      return await Permission.storage.isGranted;
    }
  }

  /// Request manage external storage permission (Android 11+ only)
  static Future<bool> requestManageExternalStorage({BuildContext? context}) async {
    final sdkVersion = await getAndroidSdkVersion();
    
    // MANAGE_EXTERNAL_STORAGE only exists on Android 11+ (API 30+)
    if (sdkVersion < 30) {
      debugPrint('MANAGE_EXTERNAL_STORAGE not available on Android $sdkVersion (requires Android 11+)');
      return false;
    }
    
    if (!await Permission.manageExternalStorage.isGranted) {
      debugPrint('Requesting MANAGE_EXTERNAL_STORAGE permission...');
      
      // This permission requires user to manually enable in settings
      final status = await Permission.manageExternalStorage.request();
      debugPrint('MANAGE_EXTERNAL_STORAGE permission result: ${status.isGranted}');

      if (!status.isGranted && context != null && context.mounted) {
        await _showManageStorageSettingsDialog(context);
      }


      return status.isGranted;
    }
    return true;
  }

  /// Check if manage external storage is granted
  static Future<bool> hasManageExternalStoragePermission() async {
    final sdkVersion = await getAndroidSdkVersion();
    
    // MANAGE_EXTERNAL_STORAGE only exists on Android 11+ (API 30+)
    if (sdkVersion < 30) {
      debugPrint('MANAGE_EXTERNAL_STORAGE not applicable on Android $sdkVersion');
      return false;
    }
    
    return await Permission.manageExternalStorage.isGranted;
  }

  /// Show dialog to guide user to enable MANAGE_EXTERNAL_STORAGE
  static Future<void> _showManageStorageSettingsDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Access Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To save PDFs to your Downloads folder, we need special storage access.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Please enable "All files access/storage access" for this app in your device settings:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Go to Settings\n'
                '2. Apps → PaLevel\n'
                '3. Permissions → Storage\n'
                '4. Enable "All files access"',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Without this permission, PDFs will be saved to app storage.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('USE APP STORAGE'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Open app settings
                await openAppSettings();
              },
              child: const Text('OPEN SETTINGS'),
            ),
          ],
        );
      },
    );
  }

  /// Check all necessary permissions for file operations
  /// Returns true if basic storage permission is granted (can save to app directory)
  /// Returns false if no storage permissions are available
  static Future<bool> checkAndRequestStoragePermissions({BuildContext? context}) async {
    debugPrint('Checking storage permissions...');
    
    final sdkVersion = await getAndroidSdkVersion();
    debugPrint('Android SDK version: $sdkVersion');
    
    // First check basic storage permission
    if (await hasStoragePermission()) {
      debugPrint('Basic storage permission granted');
    } else {
      debugPrint('Requesting basic storage permission...');
      final hasStorage = await requestStoragePermission();
      if (!hasStorage) {
        debugPrint('Basic storage permission denied');
        if (sdkVersion >= 33 && context != null && context.mounted) {
          await _showAndroid13PermissionDialog(context);
        }

        return false;
      }
    }

    // For Android 11+ (API 30+), check if we need the special permission
    if (Platform.isAndroid && sdkVersion >= 30) {
      debugPrint('Android 11+ detected, checking MANAGE_EXTERNAL_STORAGE...');
      
      // Check if we need the special permission (Android 11+)
      if (await Permission.manageExternalStorage.isRestricted) {
        debugPrint('MANAGE_EXTERNAL_STORAGE is restricted, requesting...');
        final hasManageStorage = await requestManageExternalStorage(
          context: context != null && context.mounted ? context : null,
        );

        if (hasManageStorage) {
          debugPrint('MANAGE_EXTERNAL_STORAGE granted - can access Downloads folder');
        } else {
          debugPrint('MANAGE_EXTERNAL_STORAGE denied - will use app directory only');
        }
        // Return true since we have basic storage permission (can save to app directory)
        return true;
      } else {
        debugPrint('MANAGE_EXTERNAL_STORAGE not restricted on this device');
      }
    } else if (Platform.isAndroid) {
      debugPrint('Android $sdkVersion detected - using legacy storage access');
      // For Android 10 and below, we can try to access Downloads with basic permissions
      return true;
    }

    return true;
  }

  /// Show dialog for Android 13+ permission issues
  static Future<void> _showAndroid13PermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Permission Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Android 13+ has changed how apps access storage.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'To save PDFs, please grant storage permission when prompted.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'If you accidentally denied permission, you can enable it in:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Settings → Apps → PaLevel → Permissions → Storage',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('OPEN SETTINGS'),
            ),
          ],
        );
      },
    );
  }

  /// Check if we can access the Downloads folder
  static Future<bool> canAccessDownloadsFolder() async {
    if (Platform.isAndroid) {
      final sdkVersion = await getAndroidSdkVersion();
      
      // Android 11+ requires MANAGE_EXTERNAL_STORAGE for direct access
      if (sdkVersion >= 30) {
        return await hasManageExternalStoragePermission();
      }
      
      // Android 10 (API 29) can use MediaStore without special permissions
      if (sdkVersion == 29) {
        debugPrint('Android 10 detected - MediaStore access available');
        return true;
      }
      
      // Android 9 and below might work with basic storage permissions
      return await hasStoragePermission();
    }
    return true; // iOS doesn't have the same restrictions
  }

  /// Test if we can actually write to storage (not just check permissions)
  static Future<bool> canWriteToStorage() async {
    try {
      // Try to write to app's documents directory as a test
      final directory = await getApplicationDocumentsDirectory();
      final testFile = File('${directory.path}/.permission_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      debugPrint('Storage write test: SUCCESS');
      return true;
    } catch (e) {
      debugPrint('Storage write test: FAILED - $e');
      return false;
    }
  }
}
