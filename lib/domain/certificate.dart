import 'models.dart';

List<String> missingCertificateFields({
  required DentistProfile profile,
  required Patient patient,
  required Procedure procedure,
}) {
  final missing = <String>[];
  if (profile.cro.trim().isEmpty) missing.add('CRO');
  if (patient.name.trim().isEmpty) missing.add('Paciente');
  if (patient.isMinor && patient.guardian.trim().isEmpty) {
    missing.add('Responsável legal');
  }
  for (final site in procedure.pillars) {
    if (procedure.modality != Modality.enxerto) {
      final piece = site.piece;
      if (piece == null || !piece.certificateReady) {
        missing.add('Peça do dente ${site.fdi}');
      }
    }
    for (final graft in site.grafts) {
      if (!graft.certificateReady) missing.add('Enxerto do dente ${site.fdi}');
    }
    if (procedure.modality == Modality.enxerto && site.grafts.isEmpty) {
      missing.add('Enxerto do dente ${site.fdi}');
    }
  }
  return missing;
}
