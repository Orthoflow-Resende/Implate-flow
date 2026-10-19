import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/models.dart';
import 'package:implate_flow/domain/practice.dart';

void main() {
  test('cpf aceita máscara, colagem e rejeita inválido', () {
    expect(formatCpf('39053344705'), '390.533.447-05');
    expect(formatCpf('390.533.447-05'), '390.533.447-05');
    expect(formatCpf('39053344705123'), '390.533.447-05');
    expect(formatCpf('390533'), '390.533');
    expect(isValidCpf('39053344705'), isTrue);
    expect(isValidCpf('52998224725'), isTrue);
    expect(isValidCpf('11144477735'), isTrue);
    expect(isValidCpf(''), isFalse);
    expect(isValidCpf('3905334470'), isFalse);
    expect(isValidCpf('11111111111'), isFalse);
    expect(isValidCpf('39053344700'), isFalse);
    expect(cpfIssue(''), isNull);
    expect(cpfIssue('111.111.111-11'), 'Informe um CPF válido.');
  });

  test('telefone exige ddd e tamanho completos', () {
    expect(formatBrazilianPhone('11988881001'), '(11) 98888-1001');
    expect(formatBrazilianPhone('1133334040'), '(11) 3333-4040');
    expect(formatBrazilianPhone('+55 (11) 98888-1001'), '(11) 98888-1001');
    expect(isValidBrazilianPhone('11988881001'), isTrue);
    expect(isValidBrazilianPhone('(11) 3333-4040'), isTrue);
    expect(isValidBrazilianPhone(''), isFalse);
    expect(isValidBrazilianPhone('119888810'), isFalse);
    expect(isValidBrazilianPhone('00988881001'), isFalse);
    expect(brazilianPhoneIssue('119888'), 'Informe DDD e número, com 10 ou 11 dígitos.');
    expect(brazilianPhoneIssue('0012345678'), 'Informe um DDD válido.');
    expect(brazilianPhoneIssue('(11) 3333-4040'), isNull);
  });

  test('apagar um separador remove o dígito anterior', () {
    final masked = applyDigitMask(
      previous: '(11) 98888-1001',
      incoming: '(11 98888-1001',
      cursor: 3,
      format: formatBrazilianPhone,
    );
    expect(masked.text, '(19) 8888-1001');
    expect(masked.offset, 2);
  });

  test('contato inválido não é gravado', () {
    final patient = Patient(
      id: 'pac',
      name: 'Maria',
      phone: '(11) 98888-1001',
      cpf: '390.533.447-05',
      birthDate: DateTime(1980, 1, 1),
    );
    final stored = normalizePatientContacts(patient);
    expect(stored.phone, '11988881001');
    expect(stored.cpf, '39053344705');
    final cleared = normalizePatientContacts(patient.copyWith(phone: '123', cpf: '11111111111'));
    expect(cleared.phone, isEmpty);
    expect(cleared.cpf, isEmpty);
  });
}
