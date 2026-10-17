import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/clinic_snapshot.dart';
import 'clinic_snapshot_codec.dart';

class LocalClinicStore {
  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/clinic_snapshot.json');
  }

  Future<ClinicSnapshot?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      return decodeClinicSnapshot(await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ClinicSnapshot snapshot) async {
    final file = await _file();
    await file.writeAsString(encodeClinicSnapshot(snapshot));
  }
}
