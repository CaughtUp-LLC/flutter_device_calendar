import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

// make sure 'adb devices' works on your local machine, then from the root of the plugin, run the following:
/* 
1.
cd example
2.
flutter drive --driver=integration_test/integration_test.dart --target=integration_test/app_test.dart 
  */

Future<void> main() async {
  // Try to grant permissions, but don't fail if adb is not available
  try {
    await Process.run('adb', [
      'shell',
      'pm',
      'grant',
      'com.builttoroam.devicecalendarexample',
      'android.permission.READ_CALENDAR'
    ]);
    await Process.run('adb', [
      'shell',
      'pm',
      'grant',
      'com.builttoroam.devicecalendarexample',
      'android.permission.WRITE_CALENDAR'
    ]);
    print('✅ Android permissions granted successfully');
  } catch (e) {
    print('⚠️  Could not grant Android permissions automatically: $e');
    print('Please ensure calendar permissions are granted manually if needed');
  }
  
  await integrationDriver();
}
