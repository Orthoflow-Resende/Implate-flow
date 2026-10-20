import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/models.dart';
import 'package:implate_flow/ui/new_procedure/new_procedure_viewmodel.dart';

void main() {
  test('referência exata preenche modelo, tamanho e ANVISA sem lote ou datas', () {
    final draft = PieceDraft()
      ..manufacturer = 'Neodent'
      ..lot = 'LOTE-1'
      ..manufacturedOn = DateTime(2024, 1, 2)
      ..expiresOn = DateTime(2028, 1, 2);

    final result = draft.selectModelOrReference('114.224');

    expect(result, ImplantCatalogLookup.filled);
    expect(draft.model, 'Helix GM');
    expect(draft.reference, '114.224');
    expect(draft.size, '4.0 × 10 mm');
    expect(draft.anvisa, '80156920014');
    expect(draft.lot, 'LOTE-1');
    expect(draft.manufacturedOn, DateTime(2024, 1, 2));
    expect(draft.expiresOn, DateTime(2028, 1, 2));
  });

  test('modelo do catálogo não inventa tamanho nem ANVISA', () {
    final draft = PieceDraft()
      ..manufacturer = 'Neodent'
      ..size = '5.0 × 13 mm'
      ..anvisa = 'velho';

    final result = draft.selectModelOrReference('Helix GM');

    expect(result, ImplantCatalogLookup.modelOnly);
    expect(draft.model, 'Helix GM');
    expect(draft.reference, isEmpty);
    expect(draft.size, isEmpty);
    expect(draft.anvisa, isEmpty);
  });

  test('referência inexistente ou de outro fabricante não altera o rascunho', () {
    final draft = PieceDraft()
      ..manufacturer = 'Straumann'
      ..model = 'BLX'
      ..size = '4.0 × 10 mm';

    expect(draft.selectModelOrReference('114.224'), ImplantCatalogLookup.notFound);
    expect(draft.model, 'BLX');
    expect(draft.size, '4.0 × 10 mm');
    expect(lookupImplantReference('Neodent', 'nao-existe'), isNull);
  });

  test('troca de fabricante limpa campos catalogáveis e mantém lote', () {
    final draft = PieceDraft()
      ..manufacturer = 'Neodent'
      ..selectModelOrReference('114.224')
      ..lot = 'ABC';

    draft.manufacturer = 'Straumann';
    draft.clearCatalogFields();

    expect(draft.model, isEmpty);
    expect(draft.reference, isEmpty);
    expect(draft.size, isEmpty);
    expect(draft.anvisa, isEmpty);
    expect(draft.lot, 'ABC');
  });

  test('opções de busca só listam modelos e referências do fabricante', () {
    final options = modelOrReferenceOptions('Neodent');
    expect(options, containsAll(['Helix GM', '114.224', 'Drive GM']));
    expect(options, isNot(contains('021.4301')));
    expect(modelOrReferenceOptions(''), isEmpty);
  });
}
