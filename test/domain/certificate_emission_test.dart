import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/certificate.dart';
import 'package:implate_flow/domain/models.dart';

void main() {
  test('CRO exige UF e número', () {
    expect(dentistCroReady(const DentistProfile(name: 'A', email: 'a@x', cro: '')), isFalse);
    expect(dentistCroReady(const DentistProfile(name: 'A', email: 'a@x', cro: '12345')), isFalse);
    expect(dentistCroReady(const DentistProfile(name: 'A', email: 'a@x', cro: 'RJ 12345')), isTrue);
  });

  test('CRO aceita formatos comuns e normaliza para UF 00000', () {
    expect(normalizeCro('RJ 12345'), 'RJ 12345');
    expect(normalizeCro('rj12345'), 'RJ 12345');
    expect(normalizeCro('CRO-RJ 12.345'), 'RJ 12345');
    expect(normalizeCro('12345/RJ'), 'RJ 12345');
    expect(normalizeCro('12345-rj'), 'RJ 12345');
    expect(normalizeCro('12345 RJ'), 'RJ 12345');
    expect(normalizeCro('12345'), isNull);
    expect(normalizeCro('RJ'), isNull);
  });

  test('local do certificado usa apenas locais ativos vinculados ao paciente', () {
    const profile = DentistProfile(
      name: 'A',
      email: 'a@x',
      cro: 'SP 1',
      locations: [
        CareLocation(id: 'l1', name: 'Centro', address: 'Rua 1', isDefault: true),
        CareLocation(id: 'l2', name: 'Barra', address: 'Rua 2'),
        CareLocation(id: 'l3', name: 'Inativo', active: false),
      ],
    );
    final patient = Patient(
      id: 'p1',
      name: 'Ana',
      phone: '',
      birthDate: DateTime(1990, 1, 1),
      locationIds: const ['l2', 'l3', 'missing'],
    );
    final locations = certificateCareLocations(profile: profile, patient: patient);
    expect(locations.map((item) => item.id), ['l2']);
    expect(
      resolveCertificateLocation(candidates: locations, selectedLocationId: null)?.id,
      'l2',
    );
  });

  test('paciente sem local vinculado usa os locais ativos do perfil', () {
    const profile = DentistProfile(
      name: 'A',
      email: 'a@x',
      cro: 'SP 1',
      locations: [
        CareLocation(id: 'l1', name: 'Centro', address: 'Rua 1'),
        CareLocation(id: 'l2', name: 'Inativo', active: false),
      ],
    );
    final patient = Patient(id: 'p1', name: 'Ana', phone: '', birthDate: DateTime(1990, 1, 1));
    final locations = certificateCareLocations(profile: profile, patient: patient);
    expect(locations.map((item) => item.id), ['l1']);
  });

  test('múltiplos locais exigem seleção explícita', () {
    const candidates = [
      CareLocation(id: 'l1', name: 'A', address: 'Rua 1'),
      CareLocation(id: 'l2', name: 'B', address: 'Rua 2'),
    ];
    expect(resolveCertificateLocation(candidates: candidates, selectedLocationId: null), isNull);
    expect(
      resolveCertificateLocation(candidates: candidates, selectedLocationId: 'l2')?.name,
      'B',
    );
  });

  test('prótese sem peça não bloqueia certificado', () {
    final missing = missingCertificateFields(
      profile: const DentistProfile(name: 'Dra. Helena', email: 'h@x', cro: 'SP 1'),
      patient: Patient(
        id: 'pac-1',
        name: 'Ana',
        phone: '',
        birthDate: DateTime(1980, 1, 1),
      ),
      procedure: Procedure(
        id: 'pro-1',
        patientId: 'pac-1',
        modality: Modality.protese,
        subtype: ProcedureSubtype.unitario,
        surgeryDate: DateTime(2026, 1, 1),
        statusLabel: implantStatusLabel(ImplantStatus.protese),
        sites: [ToothSite(fdi: 11, role: ToothRole.pilar)],
      ),
    );
    expect(missing, isEmpty);
  });
}
