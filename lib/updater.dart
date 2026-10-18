import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

class AppUpdater {
  static Future<void> checkForUpdate(BuildContext context) async {
    // The direct link to the latest APK on your GitHub releases
    const String apkUrl = 'https://github.com/Brantyre1/Follywood-movies-kenya/releases/latest/download/FOLLYWOOD-MOVIES-KENYA.apk';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C22),
        title: const Text('Update Available', style: TextStyle(color: Colors.white)),
        content: const Text('Download the latest version of FOLLYWOOD MOVIES KENYA?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startDownload(context, apkUrl);
            },
            child: const Text('UPDATE', style: TextStyle(color: Color(0xFFFFA500), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void _startDownload(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.black,
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFFFA500)),
            SizedBox(width: 20),
            Text('Downloading update...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // 'update.apk' is the temporary filename it saves to before installing
      OtaUpdate().execute(url, destinationFilename: 'update.apk').listen(
        (OtaEvent event) {
          if (event.status == OtaStatus.INSTALLING) {
            // App is launching the Android installer, close the dialog
            Navigator.pop(context);
          } else if (event.status == OtaStatus.FAILED) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: ${event.value}')),
            );
          }
        },
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
