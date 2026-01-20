import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/permission_handler.dart' as app_permissions;
import 'package:device_info_plus/device_info_plus.dart';

import '../config.dart';
import 'user_session_service.dart';
import 'auth_helper.dart';

class PdfService {
  /// Get Android SDK version
  static Future<int> _getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  static Future<void> downloadBookingReceipt(String bookingId, BuildContext context) async {
    try {
      final token = await UserSessionService.getUserToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$kBaseUrl/pdf/booking-receipt/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Get filename from Content-Disposition header or create a default one
        String filename = 'booking_receipt.pdf';
        final contentDisposition = response.headers['content-disposition'];
        if (contentDisposition != null && contentDisposition.contains('filename=')) {
          final filenameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
          if (filenameMatch != null) {
            filename = filenameMatch.group(1) ?? 'booking_receipt.pdf';
          }
        }

        if (kIsWeb) {
          // For web, create a data URL and open it
          await _downloadForWeb(response.bodyBytes, filename);
        } else {
        // For mobile, use path_provider to save file
        if (!context.mounted) return;
        await _downloadForMobile(response.bodyBytes, filename, context);
      }

    } else if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('Booking not found or you don\'t have permission to access it');
      } else {
        throw Exception('Failed to download receipt: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading receipt: $e');
    }
  }

  static Future<void> _downloadForWeb(List<int> bytes, String filename) async {
    // For web, create a data URL and open it in new tab
    final uri = Uri.dataFromBytes(bytes, mimeType: 'application/pdf');
    
    // Launch the URL which will prompt download
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } else {
      throw Exception('Could not launch download');
    }
  }

  static Future<void> _openPdfWithIntent(BuildContext context, File file) async {
    try {
      debugPrint('Using platform channel to open PDF: ${file.path}');
      
      // Use platform channel to open PDF with proper Android intent
      const platform = MethodChannel('palevel/pdf_downloader');
      
      try {
        final result = await platform.invokeMethod('openPdf', {
          'filePath': file.path,
        });
        
        debugPrint('Open PDF result: $result');
        
        if (result != true) {
          throw Exception('Failed to open PDF via platform channel');
        }
      } on PlatformException catch (e) {
        debugPrint('PlatformException opening PDF: ${e.message}');
        throw Exception('Could not open PDF: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error in _openPdfWithIntent: $e');
      rethrow;
    }
  }

  static Future<File?> _getPublicDownloadsFile(String filename) async {
    try {
      // Try different public Downloads paths to find the copied file
      final publicDownloadsPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];
      
      for (final downloadsPath in publicDownloadsPaths) {
        final downloadsDir = Directory(downloadsPath);
        debugPrint('PDF Download: Checking for file in: $downloadsPath');
        
        if (await downloadsDir.exists()) {
          final targetFile = File('${downloadsDir.path}/$filename');
          if (await targetFile.exists()) {
            debugPrint('PDF Download: Found public file: ${targetFile.path}');
            return targetFile;
          }
        }
      }
      
      debugPrint('PDF Download: Could not find public Downloads file');
      return null;
    } catch (e) {
      debugPrint('PDF Download: Error finding public Downloads file: $e');
      return null;
    }
  }

  static Future<void> _showErrorDialog(BuildContext context, String errorMessage) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.error, color: Colors.red, size: 48),
          title: const Text(
            'Download Failed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Download Error',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please try again or check your device storage permissions.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally retry the download or open settings
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // static Future<void> _showPermissionDialog(BuildContext context) async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return const AlertDialog(
  //         content: Row(
  //           children: [
  //             CircularProgressIndicator(),
  //             SizedBox(width: 20),
  //             Expanded(
  //               child: Text(
  //                 'Requesting storage permission...',
  //                 style: TextStyle(fontSize: 16),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  static Future<void> _showDownloadResultDialog({
    required BuildContext context,
    required String filename,
    required bool savedToPublicDownloads,
    required String savePath,
    required File file,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: savedToPublicDownloads 
            ? const Icon(Icons.check_circle, color: Colors.green, size: 48)
            : const Icon(Icons.info, color: Colors.orange, size: 48),
          title: Text(
            savedToPublicDownloads ? 'Download Successful!' : 'PDF Saved',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: $filename',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: savedToPublicDownloads ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: savedToPublicDownloads ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          savedToPublicDownloads ? Icons.folder : Icons.folder_special,
                          color: savedToPublicDownloads ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            savedToPublicDownloads 
                              ? 'Saved to Downloads folder'
                              : 'Saved to app storage',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: savedToPublicDownloads ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      savedToPublicDownloads
                        ? 'You can find this PDF in your device\'s Downloads folder and access it from any file manager.'
                        : 'The PDF is saved in the app\'s storage. You can access it from the app or through your device\'s file manager.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (!savedToPublicDownloads) ...[
                const SizedBox(height: 8),
                const Text(
                  'Note: On some Android versions, apps need special permissions to save directly to the Downloads folder.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  debugPrint('Attempting to open PDF: ${file.path}');
                  
                  // Always use our platform channel method for Android
                  if (Platform.isAndroid) {
                    await _openPdfWithIntent(context, file);
                  } else {
                    // For iOS and other platforms, use the standard method
                    final uri = Uri.file(file.path);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      throw Exception('Could not open the file');
                    }
                  }
                } catch (e) {
                  debugPrint('Error opening PDF: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open PDF: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('OPEN PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> _saveToDownloadsViaMediaStore(File sourceFile, String filename) async {
    try {
      if (!Platform.isAndroid) return false;
      
      debugPrint('PDF Download: Using MediaStore API for Android 10+');
      
      // Use platform channel to interact with MediaStore API
      const platform = MethodChannel('palevel/pdf_downloader');
      
      try {
        final result = await platform.invokeMethod('saveToDownloads', {
          'filePath': sourceFile.path,
          'filename': filename,
          'mimeType': 'application/pdf',
        });
        
        debugPrint('PDF Download: MediaStore result: $result');
        return result == true || result == 'success';
      } on PlatformException catch (e) {
        debugPrint('PDF Download: MediaStore PlatformException: ${e.message}');
        
        // Handle permission required error for Android 14+
        if (e.code == 'PERMISSION_REQUIRED') {
          debugPrint('PDF Download: Permission required - waiting for user response');
          // This is not actually an error - the permission dialog is showing
          // Return false to indicate we couldn't save to Downloads yet
          return false;
        }
        
        if (e.code == 'PERMISSION_DENIED') {
          debugPrint('PDF Download: Permission denied by user');
          throw Exception('Storage permission was denied. Please enable it in settings to download files.');
        }
        
        return false;
      } catch (e) {
        debugPrint('PDF Download: MediaStore error: $e');
        return false;
      }
    } catch (e) {
      debugPrint('PDF Download: Error in _saveToDownloadsViaMediaStore: $e');
      return false;
    }
  }

  static Future<bool> _copyToPublicDownloads(File sourceFile, String filename) async {
    try {
      // For Android 10+, use MediaStore API to save to Downloads
      final sdkVersion = await _getAndroidSdkVersion();
      
      if (Platform.isAndroid && sdkVersion >= 29) {
        // Use MediaStore for Android 10+ to properly save to Downloads
        return await _saveToDownloadsViaMediaStore(sourceFile, filename);
      }
      
      // For older Android versions, try direct file access
      final publicDownloadsPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];
      
      for (final downloadsPath in publicDownloadsPaths) {
        try {
          final downloadsDir = Directory(downloadsPath);
          debugPrint('PDF Download: Testing public Downloads path: $downloadsPath');
          
          if (await downloadsDir.exists()) {
            File targetFile = File('${downloadsDir.path}/$filename');
            
            // Check if file already exists and create unique name if needed
            if (await targetFile.exists()) {
              final nameWithoutExt = path.basenameWithoutExtension(filename);
              final ext = path.extension(filename);
              int counter = 1;
              while (await File('${downloadsDir.path}/$nameWithoutExt($counter)$ext').exists()) {
                counter++;
              }
              final uniqueFilename = '$nameWithoutExt($counter)$ext';
              targetFile = File('${downloadsDir.path}/$uniqueFilename');
            }
            
            // Copy the file
            await sourceFile.copy(targetFile.path);
            
            // Verify the copy
            if (await targetFile.exists() && await targetFile.length() > 0) {
              debugPrint('PDF Download: Successfully copied to public Downloads: ${targetFile.path}');
              return true;
            }
          }
        } catch (e) {
          debugPrint('PDF Download: Could not copy to $downloadsPath: $e');
          continue;
        }
      }
      
      debugPrint('PDF Download: Failed to copy to any public Downloads location');
      return false;
    } catch (e) {
      debugPrint('PDF Download: Error in _copyToPublicDownloads: $e');
      return false;
    }
  }

  static Future<Directory?> _getNativeDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Try the standard Downloads directory paths
        final downloadsPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
          '/storage/self/primary/Download',
          '/storage/self/primary/Downloads',
        ];
        
        for (final downloadsPath in downloadsPaths) {
          final downloadsDir = Directory(downloadsPath);
          debugPrint('PDF Download: Testing Downloads path: $downloadsPath');
          
          if (await downloadsDir.exists()) {
            // Test if we can actually write to this directory
            final testFile = File('${downloadsDir.path}/.test_write');
            try {
              await testFile.writeAsString('test');
              await testFile.delete();
              debugPrint('PDF Download: Downloads folder is writable: $downloadsPath');
              return downloadsDir;
            } catch (e) {
              debugPrint('PDF Download: Downloads folder exists but not writable: $downloadsPath - $e');
            }
          }
        }
        
        debugPrint('PDF Download: No writable Downloads folder found');
      }
      return null;
    } catch (e) {
      debugPrint('PDF Download: Error getting native Downloads directory: $e');
      return null;
    }
  }

  static Future<void> _downloadForMobile(List<int> bytes, String filename, BuildContext context) async {
    try {
      debugPrint('PDF Download: Starting download for filename: $filename');
      
      // Test if we can actually write to storage
      final canWrite = await app_permissions.AppPermissions.canWriteToStorage();
      if (!canWrite) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage access is restricted. Please check app permissions and try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        throw Exception('Storage write access denied - cannot save receipt');
      }
      
      // Check if we can access the Downloads folder
      final canAccessDownloads = await app_permissions.AppPermissions.canAccessDownloadsFolder();
      debugPrint('PDF Download: Can access Downloads folder: $canAccessDownloads');
      
      // Get the downloads directory with proper fallbacks
      Directory? targetDir;
      String? error;
      bool savedToPublicDownloads = false;
      
      if (canAccessDownloads) {
        // Try to use the native Downloads folder first
        debugPrint('PDF Download: Attempting to use native Downloads folder...');
        final downloadsDir = await _getNativeDownloadsDirectory();
        if (downloadsDir != null) {
          targetDir = downloadsDir;
          savedToPublicDownloads = true;
          debugPrint('PDF Download: Using native Downloads folder: ${targetDir.path}');
        } else {
          debugPrint('PDF Download: Native Downloads folder not accessible, falling back...');
        }
      }
      
      // If Downloads folder is not accessible, try fallback directories
      if (targetDir == null) {
        debugPrint('PDF Download: Using fallback directory selection...');
        
        // Try different approaches to get a writable directory
        final List<Future<Directory?>> possibleDirs = [
          // Try application documents directory
          getApplicationDocumentsDirectory().then((dir) => Directory('${dir.path}/Downloads')),
          // Try external storage directory
          getExternalStorageDirectory().then((dir) => dir != null ? Directory('${dir.path}/Download') : null),
          // Try temporary directory as last resort
          getTemporaryDirectory().then((dir) => Directory('${dir.path}/Downloads')),
        ];
        
        // Find the first accessible directory
        for (final dirFuture in possibleDirs) {
          try {
            final dir = await dirFuture;
            if (dir != null) {
              debugPrint('PDF Download: Trying directory: ${dir.path}');
              
              // Check if we can create/access the directory
              if (!await dir.exists()) {
                try {
                  await dir.create(recursive: true);
                } catch (e) {
                  debugPrint('PDF Download: Could not create directory ${dir.path}: $e');
                  continue;
                }
              }
              
              // Test if we can write to this directory
              final testFile = File('${dir.path}/.test_write');
              try {
                await testFile.writeAsString('test');
                await testFile.delete();
                targetDir = dir;
                debugPrint('PDF Download: Successfully found writable directory: ${targetDir.path}');
                break;
              } catch (e) {
                debugPrint('PDF Download: Cannot write to directory ${dir.path}: $e');
              }
            }
          } catch (e) {
            error = e.toString();
            debugPrint('PDF Download: Error accessing directory: $e');
          }
        }
      }
      
      if (targetDir == null) {
        // As a last resort, use the app's temporary directory
        try {
          targetDir = await getTemporaryDirectory();
          debugPrint('PDF Download: Using temporary directory as fallback: ${targetDir.path}');
        } catch (e) {
          throw Exception('Could not access any download directory. Last error: $error');
        }
      }
      
      final savePath = '${targetDir.path}/$filename';
      
      // Create the file
      final file = File(savePath);
      debugPrint('PDF Download: Saving file to: ${file.path}');
      
      // Write the file with better error handling
      try {
        await file.writeAsBytes(bytes, mode: FileMode.writeOnly, flush: true);
      } catch (e) {
        throw Exception('Failed to write file to ${file.path}: ${e.toString()}');
      }
      
      // Verify the file was written
      if (!await file.exists()) {
        throw Exception('Failed to save file: File does not exist after write at ${file.path}');
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Failed to save file: File is empty after write at ${file.path}');
      }
      
      debugPrint('PDF Download: File saved successfully. Size: $fileSize bytes');
      
      // For Android 10+, try to copy to public Downloads folder if not already there
      File fileToOpen = file; // Track which file to open (may change if copied to Downloads)
      
      if (!savedToPublicDownloads && Platform.isAndroid) {
        final sdkVersion = await _getAndroidSdkVersion();
        if (sdkVersion >= 29) { // Android 10+
          debugPrint('PDF Download: Android $sdkVersion detected, attempting to copy to public Downloads...');
          
          try {
            final copySuccess = await _copyToPublicDownloads(file, filename);
            if (copySuccess) {
              savedToPublicDownloads = true;
              
              // Get the path to the copied file in Downloads folder
              final publicFile = await _getPublicDownloadsFile(filename);
              if (publicFile != null) {
                debugPrint('PDF Download: Successfully copied to public Downloads folder: ${publicFile.path}');
                // Update the file reference to the public Downloads file
                fileToOpen = publicFile;
              }
            } else {
              debugPrint('PDF Download: Could not copy to public Downloads, keeping in app storage');
            }
          } catch (e) {
            debugPrint('PDF Download: Error during copy to public Downloads: $e');
            
            // Check if this is a permission error and provide a helpful message
            if (e.toString().contains('Storage permission was denied')) {
              // Re-throw to show user the permission denied message
              rethrow;
            } else if (e.toString().contains('Storage permission required')) {
              debugPrint('PDF Download: Permission dialog is showing, waiting for user response');
              // Don't show error - permission dialog is showing
              // The native code will handle the retry automatically
            }
          }
        }
      }
      
      // Show success dialog with location info and actions
      if (context.mounted) {
        await _showDownloadResultDialog(
          context: context,
          filename: filename,
          savedToPublicDownloads: savedToPublicDownloads,
          savePath: fileToOpen.path, // Use the file that should be opened
          file: fileToOpen, // Use the file that should be opened
        );
      }
    } catch (e) {
      debugPrint('PDF Download Error: $e');
      debugPrint('Stack Trace: ${StackTrace.current}');
      String errorMessage = 'Failed to save receipt';
      
      // Provide more specific error messages based on the exception type
      if (e is FileSystemException) {
        debugPrint('FileSystemException detected: ${e.message}');
        if (e.message.contains('Permission denied')) {
          errorMessage = 'Permission denied: Cannot access storage. Please check app permissions.';
          debugPrint('Permission denied error - user needs to grant storage permissions');
        } else if (e.message.contains('No such file or directory')) {
          errorMessage = 'Directory not found: Cannot create download directory.';
          debugPrint('Directory not found error - path does not exist');
        } else if (e.message.contains('Read-only file system')) {
          errorMessage = 'Cannot write to storage: File system is read-only.';
          debugPrint('Read-only file system error - storage is not writable');
        } else {
          errorMessage = 'File system error: ${e.message}';
          debugPrint('Generic file system error: ${e.message}');
        }
      } else if (e.toString().contains('Could not access any download directory')) {
        errorMessage = 'Cannot access download directory. Please check storage permissions and try again.';
        debugPrint('Download directory access error - all fallback directories failed');
      } else {
        errorMessage = 'Failed to save receipt: ${e.toString()}';
        debugPrint('Generic download error: ${e.toString()}');
      }
      
      debugPrint('Showing error message to user: $errorMessage');
      
      if (context.mounted) {
        await _showErrorDialog(context, errorMessage);
      }
      rethrow;
    }
  }
}
