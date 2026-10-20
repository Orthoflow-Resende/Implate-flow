import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/data/services/api_feedback.dart';
import 'package:implate_flow/domain/models.dart';

void main() {
  test('sanitizePersonName rejeita literais nulas', () {
    expect(sanitizePersonName(null), '');
    expect(sanitizePersonName(''), '');
    expect(sanitizePersonName('null'), '');
    expect(sanitizePersonName('NULL'), '');
    expect(sanitizePersonName('undefined'), '');
    expect(sanitizePersonName('  Dra. Ana  '), 'Dra. Ana');
  });

  test('displayDentistName usa placeholder quando vazio', () {
    expect(displayDentistName('null'), 'Nome não informado');
    expect(displayDentistName('Dr. João'), 'Dr. João');
  });

  test('friendlyApiMessage mapeia status e corpo seguro', () {
    expect(friendlyApiMessage(401), contains('Sessão'));
    expect(friendlyApiMessage(404), contains('não encontrado'));
    expect(
      friendlyApiMessage(400, body: {
        'error': {'message': 'Informe o nome.'},
      }),
      'Informe o nome.',
    );
    expect(
      friendlyApiMessage(500, body: {
        'error': {'message': 'SQLException stack at line 12'},
      }),
      contains('indisponível'),
    );
    expect(friendlyApiMessage(202), contains('Processamento'));
    expect(friendlyApiMessage(204, action: 'Paciente salvo com sucesso.'), 'Paciente salvo com sucesso.');
  });
}
