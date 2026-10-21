import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/data/services/clinical_catalog_codec.dart';
import 'package:implate_flow/domain/models.dart';

void main() {
  test('parseia respostas da API de implantes e enxertos', () {
    final catalog = clinicalCatalogFromApi(
      implants: {
        'manufacturers': [
          {
            'id': 'm1',
            'name': 'Neodent',
            'models': [
              {'id': 'md1', 'name': 'Helix GM'},
            ],
            'references': [
              {
                'id': 'r1',
                'reference': '114.224',
                'model': 'Helix GM',
                'size': '4.0 × 10 mm',
                'anvisa': '80156920014',
              },
            ],
          },
        ],
        'sizes': [
          {'id': 's1', 'label': '4.0 × 10 mm'},
        ],
      },
      grafts: {
        'manufacturers': [
          {
            'id': 'g1',
            'name': 'Geistlich',
            'models': [
              {
                'id': 'gm1',
                'name': 'Bio-Oss',
                'product_type': 'Osso bovino desproteinizado',
                'presentations': ['po'],
                'granulometries': ['0,25–1 mm'],
              },
            ],
          },
        ],
      },
    );

    expect(catalog.implantManufacturers, ['Neodent']);
    expect(catalog.modelOrReferenceOptions('Neodent'), ['Helix GM']);
    expect(
      catalog.lookupImplantReference('Neodent', '114224')?.size,
      '4.0 × 10 mm',
    );
    expect(catalog.graftProductOf('Geistlich', 'Bio-Oss')?.presentations, [GraftPresentation.po]);
  });

  test('round-trip do cache preserva lookup', () {
    final encoded = encodeClinicalCatalog(bundledClinicalCatalog);
    final decoded = decodeClinicalCatalog(encoded);

    expect(
      decoded.lookupImplantReference('Neodent', '114.224')?.model,
      'Helix GM',
    );
    expect(decoded.graftManufacturers(), contains('Geistlich'));
    expect(decoded.implantSizes, contains('4.0 × 10 mm'));
  });
}
