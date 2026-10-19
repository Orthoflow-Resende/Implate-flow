import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/certificate.dart';
import 'package:implate_flow/domain/models.dart';

void main() {
  test('o certificado não exige número de série', () {
    final missing = missingCertificateFields(
      profile: const DentistProfile(name: 'Dra. Helena', email: 'h@x', cro: 'CRO-SP 1'),
      patient: Patient(
        id: 'pac-1',
        name: 'Ana',
        phone: '',
        birthDate: DateTime(1980, 1, 1),
      ),
      procedure: Procedure(
        id: 'pro-1',
        patientId: 'pac-1',
        modality: Modality.unitario,
        surgeryDate: DateTime(2026, 1, 1),
        statusLabel: implantStatusLabel(ImplantStatus.instalado),
        sites: [
          ToothSite(
            fdi: 11,
            role: ToothRole.pilar,
            piece: ImplantPiece(
              manufacturer: 'Neodent',
              model: 'Drive',
              size: '3.5 × 10 mm',
              manufacturedOn: DateTime(2025, 1, 1),
              expiresOn: DateTime(2030, 1, 1),
            ),
          ),
        ],
      ),
    );

    expect(missing, isEmpty);
  });
}
