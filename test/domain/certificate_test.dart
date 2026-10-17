import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/certificate.dart';
import 'package:implate_flow/domain/models.dart';

void main() {
  test('certificado de menor exige responsável', () {
    final missing = missingCertificateFields(
      profile: const DentistProfile(name: 'Dra. Helena', email: 'h@x', cro: 'CRO-SP 1'),
      patient: Patient(
        id: 'pac-1',
        name: 'Pedro',
        phone: '',
        birthDate: DateTime(2014, 7, 19),
      ),
      procedure: Procedure(
        id: 'pro-1',
        patientId: 'pac-1',
        modality: Modality.enxerto,
        surgeryDate: DateTime(2026, 1, 1),
        statusLabel: graftStatusLabel(GraftStatus.realizado),
        sites: [
          ToothSite(
            fdi: 46,
            role: ToothRole.pilar,
            grafts: [
              const GraftMaterial(origin: GraftOrigin.autogeno, donorSite: 'Ramo'),
            ],
          ),
        ],
      ),
    );
    expect(missing, contains('Responsável legal'));
  });
}
