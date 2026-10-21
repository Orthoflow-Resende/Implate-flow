import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/clinical_catalog_controller.dart';

/// Escuta atualizações do catálogo remoto quando o provider estiver montado.
void watchClinicalCatalog(BuildContext context) {
  try {
    context.watch<ClinicalCatalogController>();
  } on ProviderNotFoundException {
    // Telas/testes sem o provider usam [activeClinicalCatalog] embutido.
  }
}
