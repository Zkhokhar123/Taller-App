import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> setupDatabaseFactory() async {
  // Windows / Linux / macOS desktop.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android / iOS keep the default sqflite plugin factory.
}
