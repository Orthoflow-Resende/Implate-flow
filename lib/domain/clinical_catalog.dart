part of 'models.dart';

/// Snapshot de catálogo clínico (implantes + enxertos) usado pelos formulários.
class ClinicalCatalog {
  const ClinicalCatalog({
    required this.implantModelsByManufacturer,
    required this.implantSizes,
    required this.implantReferences,
    required this.graftProducts,
  });

  final Map<String, List<String>> implantModelsByManufacturer;
  final List<String> implantSizes;
  final List<ImplantCatalogEntry> implantReferences;
  final Map<String, List<GraftProduct>> graftProducts;

  List<String> get implantManufacturers => implantModelsByManufacturer.keys.toList();

  List<String> graftManufacturers() => graftProducts.keys.toList();

  List<GraftProduct> graftProductsOf(String manufacturer) =>
      graftProducts[manufacturer] ?? const [];

  GraftProduct? graftProductOf(String manufacturer, String model) {
    for (final product in graftProductsOf(manufacturer)) {
      if (product.model == model) return product;
    }
    return null;
  }

  List<ImplantCatalogEntry> implantReferencesFor(String manufacturer) {
    return [
      for (final entry in implantReferences)
        if (entry.manufacturer == manufacturer) entry,
    ];
  }

  /// Modelos do fabricante para a listagem (nome único). Referências não entram —
  /// a busca por número é tratada à parte (preenche tamanho; só o modelo não).
  List<String> modelOrReferenceOptions(String manufacturer) {
    final models = implantModelsByManufacturer[manufacturer] ?? const <String>[];
    return [...{for (final model in models) model}];
  }

  ImplantCatalogEntry? lookupImplantReference(String manufacturer, String reference) {
    final query = normalizeImplantReferenceKey(reference);
    if (manufacturer.isEmpty || query.isEmpty) return null;
    final matches = [
      for (final entry in implantReferences)
        if (entry.manufacturer == manufacturer &&
            normalizeImplantReferenceKey(entry.reference) == query)
          entry,
    ];
    if (matches.length == 1) return matches.single;
    return null;
  }

  /// Referências cujo código normalizado começa com a busca (sem exigir match exato).
  List<ImplantCatalogEntry> implantReferencesMatching(String manufacturer, String query) {
    final key = normalizeImplantReferenceKey(query);
    if (manufacturer.isEmpty || key.isEmpty) return const [];
    return [
      for (final entry in implantReferencesFor(manufacturer))
        if (normalizeImplantReferenceKey(entry.reference).startsWith(key)) entry,
    ];
  }

  String? catalogModelName(String manufacturer, String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return null;
    for (final model in implantModelsByManufacturer[manufacturer] ?? const <String>[]) {
      if (model.toLowerCase() == query) return model;
    }
    return null;
  }

  bool graftCombinationValid(GraftMaterial graft) {
    if (graft.origin == GraftOrigin.autogeno) {
      return graft.processing == null &&
          graft.manufacturer.isEmpty &&
          graft.model.isEmpty &&
          graft.productType.isEmpty &&
          graft.granulometry.isEmpty;
    }
    if (graft.presentation == GraftPresentation.bloco && graft.granulometry.isNotEmpty) {
      return false;
    }
    if (graft.processing != GraftProcessing.liofilizado) return graft.donorSite.isEmpty;
    if (graft.donorSite.isNotEmpty) return false;
    final product = graftProductOf(graft.manufacturer, graft.model);
    if (graft.manufacturer.isEmpty || graft.model.isEmpty) return product == null;
    if (product == null) return false;
    if (graft.productType.isNotEmpty && graft.productType != product.type) return false;
    if (graft.presentation != null && !product.presentations.contains(graft.presentation)) {
      return false;
    }
    if (graft.granulometry.isNotEmpty && !product.granulometries.contains(graft.granulometry)) {
      return false;
    }
    return true;
  }
}

/// Catálogo embutido (espelho do seed PostgreSQL). Fallback offline sem inventar dados.
const bundledClinicalCatalog = ClinicalCatalog(
  implantModelsByManufacturer: {
    'Neodent': ['Drive GM', 'Helix GM', 'Grand Morse'],
    'Straumann': ['BLX', 'BLT', 'TLX'],
    'Nobel Biocare': ['NobelActive', 'NobelParallel'],
  },
  implantSizes: [
    '3.3 × 8 mm',
    '3.3 × 10 mm',
    '3.3 × 11.5 mm',
    '3.3 × 13 mm',
    '3.5 × 8 mm',
    '3.5 × 10 mm',
    '3.5 × 11.5 mm',
    '3.5 × 13 mm',
    '3.75 × 8 mm',
    '3.75 × 10 mm',
    '3.75 × 11.5 mm',
    '3.75 × 13 mm',
    '4.0 × 8 mm',
    '4.0 × 10 mm',
    '4.0 × 11.5 mm',
    '4.0 × 13 mm',
    '4.3 × 10 mm',
    '4.3 × 11.5 mm',
    '4.3 × 13 mm',
    '4.3 × 16 mm',
    '4.5 × 8 mm',
    '4.5 × 10 mm',
    '4.5 × 13 mm',
    '5.0 × 8 mm',
    '5.0 × 10 mm',
    '5.0 × 11.5 mm',
    '5.0 × 13 mm',
  ],
  implantReferences: [
    ImplantCatalogEntry(
      manufacturer: 'Neodent',
      model: 'Helix GM',
      reference: '114.224',
      size: '4.0 × 10 mm',
      anvisa: '80156920014',
    ),
    ImplantCatalogEntry(
      manufacturer: 'Neodent',
      model: 'Helix GM',
      reference: '114.223',
      size: '3.75 × 10 mm',
      anvisa: '80156920014',
    ),
    ImplantCatalogEntry(
      manufacturer: 'Neodent',
      model: 'Drive GM',
      reference: '110.618',
      size: '4.0 × 10 mm',
      anvisa: '80156920011',
    ),
    ImplantCatalogEntry(
      manufacturer: 'Straumann',
      model: 'BLX',
      reference: '021.4301',
      size: '4.0 × 10 mm',
      anvisa: '10345590025',
    ),
    ImplantCatalogEntry(
      manufacturer: 'Straumann',
      model: 'BLT',
      reference: '021.2310',
      size: '4.0 × 10 mm',
      anvisa: '10345590018',
    ),
    ImplantCatalogEntry(
      manufacturer: 'Nobel Biocare',
      model: 'NobelActive',
      reference: '34130',
      size: '4.3 × 10 mm',
      anvisa: '80146540033',
    ),
    ImplantCatalogEntry(
      manufacturer: 'Nobel Biocare',
      model: 'NobelParallel',
      reference: '30130',
      size: '4.3 × 10 mm',
      anvisa: '80146540041',
    ),
  ],
  graftProducts: {
    'Geistlich': [
      GraftProduct(
        model: 'Bio-Oss',
        type: 'Osso bovino desproteinizado',
        presentations: [GraftPresentation.po],
        granulometries: ['0,25–1 mm', '1–2 mm'],
      ),
      GraftProduct(
        model: 'Bio-Oss Collagen',
        type: 'Osso bovino desproteinizado',
        presentations: [GraftPresentation.bloco],
      ),
    ],
    'Straumann': [
      GraftProduct(
        model: 'cerabone',
        type: 'Osso bovino',
        presentations: [GraftPresentation.po],
        granulometries: ['0,5–1 mm', '1–2 mm'],
      ),
      GraftProduct(
        model: 'maxgraft',
        type: 'Aloenxerto',
        presentations: [GraftPresentation.bloco, GraftPresentation.po],
        granulometries: ['0,5–2 mm'],
      ),
    ],
    'Baumer': [
      GraftProduct(
        model: 'Ox Bone',
        type: 'Osso bovino',
        presentations: [GraftPresentation.bloco, GraftPresentation.po],
        granulometries: ['0,25–1 mm', '1–2 mm'],
      ),
    ],
  },
);

/// Catálogo em uso pelos drafts e telas. Atualizado após sync remoto/cache.
ClinicalCatalog activeClinicalCatalog = bundledClinicalCatalog;

Map<String, List<String>> get implantCatalog =>
    activeClinicalCatalog.implantModelsByManufacturer;

List<String> get implantSizes => activeClinicalCatalog.implantSizes;

List<ImplantCatalogEntry> get implantReferenceCatalog =>
    activeClinicalCatalog.implantReferences;

Map<String, List<GraftProduct>> get graftProducts => activeClinicalCatalog.graftProducts;

/// Chave de busca de referência: só letras/dígitos, minúsculas (ex.: `109.644` → `109644`).
String normalizeImplantReferenceKey(String reference) {
  final buffer = StringBuffer();
  for (final unit in reference.trim().toLowerCase().codeUnits) {
    final isDigit = unit >= 48 && unit <= 57;
    final isLatin = unit >= 97 && unit <= 122;
    if (isDigit || isLatin) buffer.writeCharCode(unit);
  }
  return buffer.toString();
}

List<ImplantCatalogEntry> implantReferencesFor(String manufacturer) =>
    activeClinicalCatalog.implantReferencesFor(manufacturer);

List<String> modelOrReferenceOptions(String manufacturer) =>
    activeClinicalCatalog.modelOrReferenceOptions(manufacturer);

ImplantCatalogEntry? lookupImplantReference(String manufacturer, String reference) =>
    activeClinicalCatalog.lookupImplantReference(manufacturer, reference);

List<ImplantCatalogEntry> implantReferencesMatching(String manufacturer, String query) =>
    activeClinicalCatalog.implantReferencesMatching(manufacturer, query);

String? catalogModelName(String manufacturer, String value) =>
    activeClinicalCatalog.catalogModelName(manufacturer, value);

List<String> graftManufacturers() => activeClinicalCatalog.graftManufacturers();

List<GraftProduct> graftProductsOf(String manufacturer) =>
    activeClinicalCatalog.graftProductsOf(manufacturer);

GraftProduct? graftProductOf(String manufacturer, String model) =>
    activeClinicalCatalog.graftProductOf(manufacturer, model);

bool graftCombinationValid(GraftMaterial graft) =>
    activeClinicalCatalog.graftCombinationValid(graft);
