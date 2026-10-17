import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

class AppUpdater {
  static Future<void> checkForUpdate(BuildContext context) async {
    const String apkUrl = 'https://github.com/Brantyre1/Follywood-movies-kenya/releases/latest/download/FOLLYWOOD-MOVIES-KENYA.apk';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update App'),
        content: const Text('Download the latest version of FOLLYWOOD MOVIES KENYA?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startDownload(context, apkUrl);
            },
            child: const Text('UPDATE'),
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
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFFFA500)),
            SizedBox(width: 20),
            Text('Downloading update...'),
          ],
        ),
      ),
    );

    try {
      OtaUpdate().execute(url).listen(
        (OtaEvent event) {
          if (event.status == OtaStatus.INSTALLING) {
            Navigator.pop(context);
          }
        },
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }
}
