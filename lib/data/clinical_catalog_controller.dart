import 'package:flutter/foundation.dart';

import '../domain/models.dart';

/// Expõe o catálogo ativo e notifica as telas quando a sync remota atualiza.
class ClinicalCatalogController extends ChangeNotifier {
  ClinicalCatalogController([ClinicalCatalog? initial])
      : _catalog = initial ?? bundledClinicalCatalog {
    activeClinicalCatalog = _catalog;
  }

  ClinicalCatalog _catalog;

  ClinicalCatalog get catalog => _catalog;

  void replace(ClinicalCatalog next) {
    _catalog = next;
    activeClinicalCatalog = next;
    notifyListeners();
  }

  void resetToBundled() => replace(bundledClinicalCatalog);
}
