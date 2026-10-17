import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class ClinicFiles {
  Future<Directory> _media() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/clinic_media');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> saveBytes(String filename, Uint8List bytes) async {
    final directory = await _media();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> copyFile(String sourcePath, String filename) async {
    final directory = await _media();
    final file = await File(sourcePath).copy('${directory.path}/$filename');
    return file.path;
  }
}
