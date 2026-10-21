import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/models.dart';
import 'clinical_catalog_codec.dart';

abstract class CatalogStore {
  Future<ClinicalCatalog?> load();

  Future<void> save(ClinicalCatalog catalog);
}

class LocalCatalogStore implements CatalogStore {
  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/clinical_catalog.json');
  }

  @override
  Future<ClinicalCatalog?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      return decodeClinicalCatalog(await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ClinicalCatalog catalog) async {
    final file = await _file();
    await file.writeAsString(encodeClinicalCatalog(catalog));
  }
}

class MemoryCatalogStore implements CatalogStore {
  ClinicalCatalog? value;

  @override
  Future<ClinicalCatalog?> load() async => value;

  @override
  Future<void> save(ClinicalCatalog catalog) async {
    value = catalog;
  }
}
