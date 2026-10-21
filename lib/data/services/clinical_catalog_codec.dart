import 'dart:convert';

import '../../domain/models.dart';

ClinicalCatalog decodeClinicalCatalog(String raw) {
  final json = jsonDecode(raw);
  if (json is! Map) {
    throw const FormatException('Catálogo inválido.');
  }
  return clinicalCatalogFromJson(Map<String, dynamic>.from(json));
}

String encodeClinicalCatalog(ClinicalCatalog catalog) =>
    jsonEncode(clinicalCatalogToJson(catalog));

Map<String, dynamic> clinicalCatalogToJson(ClinicalCatalog catalog) => {
      'implantManufacturers': [
        for (final name in catalog.implantManufacturers)
          {
            'name': name,
            'models': [
              for (final model in catalog.implantModelsByManufacturer[name] ?? const <String>[])
                {'name': model},
            ],
            'references': [
              for (final entry in catalog.implantReferencesFor(name))
                {
                  'reference': entry.reference,
                  'model': entry.model,
                  'size': entry.size,
                  'anvisa': entry.anvisa,
                },
            ],
          },
      ],
      'sizes': [
        for (final label in catalog.implantSizes) {'label': label},
      ],
      'graftManufacturers': [
        for (final name in catalog.graftManufacturers())
          {
            'name': name,
            'models': [
              for (final product in catalog.graftProductsOf(name))
                {
                  'name': product.model,
                  'product_type': product.type,
                  'presentations': [for (final item in product.presentations) item.name],
                  'granulometries': product.granulometries,
                },
            ],
          },
      ],
    };

ClinicalCatalog clinicalCatalogFromJson(Map<String, dynamic> json) {
  final implantBody = json['implants'] is Map
      ? Map<String, dynamic>.from(json['implants'] as Map)
      : json;
  final graftBody = json['grafts'] is Map
      ? Map<String, dynamic>.from(json['grafts'] as Map)
      : json;

  return ClinicalCatalog(
    implantModelsByManufacturer: _implantModels(implantBody),
    implantSizes: _implantSizes(implantBody),
    implantReferences: _implantReferences(implantBody),
    graftProducts: _graftProducts(graftBody),
  );
}

/// Monta o snapshot a partir das respostas HTTP da API.
ClinicalCatalog clinicalCatalogFromApi({
  required Map<String, dynamic> implants,
  required Map<String, dynamic> grafts,
}) {
  return ClinicalCatalog(
    implantModelsByManufacturer: _implantModels(implants),
    implantSizes: _implantSizes(implants),
    implantReferences: _implantReferences(implants),
    graftProducts: _graftProducts(grafts),
  );
}

Map<String, List<String>> _implantModels(Map<String, dynamic> body) {
  final manufacturers = body['manufacturers'] ?? body['implantManufacturers'];
  if (manufacturers is! List) return {};
  final result = <String, List<String>>{};
  for (final item in manufacturers) {
    if (item is! Map) continue;
    final name = '${item['name'] ?? ''}'.trim();
    if (name.isEmpty) continue;
    final models = item['models'];
    result[name] = [
      if (models is List)
        for (final model in models)
          if (model is Map && '${model['name'] ?? ''}'.trim().isNotEmpty)
            '${model['name']}'.trim()
          else if (model is String && model.trim().isNotEmpty)
            model.trim(),
    ];
  }
  return result;
}

List<String> _implantSizes(Map<String, dynamic> body) {
  final sizes = body['sizes'];
  if (sizes is! List) return const [];
  return [
    for (final size in sizes)
      if (size is Map && '${size['label'] ?? ''}'.trim().isNotEmpty)
        '${size['label']}'.trim()
      else if (size is String && size.trim().isNotEmpty)
        size.trim(),
  ];
}

List<ImplantCatalogEntry> _implantReferences(Map<String, dynamic> body) {
  final manufacturers = body['manufacturers'] ?? body['implantManufacturers'];
  if (manufacturers is! List) return const [];
  final result = <ImplantCatalogEntry>[];
  for (final item in manufacturers) {
    if (item is! Map) continue;
    final manufacturer = '${item['name'] ?? ''}'.trim();
    if (manufacturer.isEmpty) continue;
    final references = item['references'];
    if (references is! List) continue;
    for (final reference in references) {
      if (reference is! Map) continue;
      final code = '${reference['reference'] ?? ''}'.trim();
      final model = '${reference['model'] ?? ''}'.trim();
      if (code.isEmpty || model.isEmpty) continue;
      result.add(
        ImplantCatalogEntry(
          manufacturer: manufacturer,
          model: model,
          reference: code,
          size: '${reference['size'] ?? ''}'.trim(),
          anvisa: '${reference['anvisa'] ?? ''}'.trim(),
        ),
      );
    }
  }
  return result;
}

Map<String, List<GraftProduct>> _graftProducts(Map<String, dynamic> body) {
  final manufacturers = body['manufacturers'] ?? body['graftManufacturers'];
  if (manufacturers is! List) return {};
  final result = <String, List<GraftProduct>>{};
  for (final item in manufacturers) {
    if (item is! Map) continue;
    final name = '${item['name'] ?? ''}'.trim();
    if (name.isEmpty) continue;
    final models = item['models'];
    final products = <GraftProduct>[];
    if (models is List) {
      for (final model in models) {
        if (model is! Map) continue;
        final product = _graftProduct(Map<String, dynamic>.from(model));
        if (product != null) products.add(product);
      }
    }
    result[name] = products;
  }
  return result;
}

GraftProduct? _graftProduct(Map<String, dynamic> json) {
  final model = '${json['name'] ?? json['model'] ?? ''}'.trim();
  if (model.isEmpty) return null;
  final presentations = json['presentations'];
  return GraftProduct(
    model: model,
    type: '${json['product_type'] ?? json['type'] ?? ''}'.trim(),
    presentations: [
      if (presentations is List)
        for (final item in presentations)
          for (final value in GraftPresentation.values)
            if (value.name == '$item') value,
    ],
    granulometries: [
      if (json['granulometries'] is List)
        for (final item in json['granulometries'] as List) '$item',
    ],
  );
}
