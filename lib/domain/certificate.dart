import 'models.dart';
import 'practice.dart';

const certificateCroRequiredMessage =
    'Para emitir certificado, é necessário completar o cadastro';

/// Converte o CRO digitado para o formato canônico `UF 00000` aceito pela API.
String? normalizeCro(String value) {
  final text = value.trim().toUpperCase().replaceFirst(RegExp(r'^CRO[\s\-/:]*'), '');
  final ufFirst = RegExp(r'^([A-Z]{2})[\s\-/:]*(\d[\d.\-]*)$').firstMatch(text);
  if (ufFirst != null) return '${ufFirst[1]} ${ufFirst[2]!.replaceAll(RegExp(r'\D'), '')}';
  final ufLast = RegExp(r'^(\d[\d.\-]*?)[\s\-/:]*([A-Z]{2})$').firstMatch(text);
  if (ufLast != null) return '${ufLast[2]} ${ufLast[1]!.replaceAll(RegExp(r'\D'), '')}';
  return null;
}

bool dentistCroReady(DentistProfile profile) => normalizeCro(profile.cro) != null;

List<CareLocation> certificateCareLocations({
  required DentistProfile profile,
  required Patient patient,
}) {
  final active = {
    for (final location in activeCareLocations(profile.locations)) location.id: location,
  };
  final selected = <CareLocation>[];
  final seen = <String>{};
  for (final id in patient.locationIds) {
    final location = active[id];
    if (location == null || !seen.add(id)) continue;
    selected.add(location);
  }
  if (selected.isEmpty) return active.values.toList();
  return selected;
}

CareLocation? resolveCertificateLocation({
  required List<CareLocation> candidates,
  String? selectedLocationId,
}) {
  if (selectedLocationId != null) {
    for (final location in candidates) {
      if (location.id == selectedLocationId) return location;
    }
    return null;
  }
  if (candidates.length == 1) return candidates.first;
  return null;
}

String locationAddressLabel(CareLocation location) {
  final address = location.address.trim();
  if (address.isEmpty) return location.name;
  return '${location.name}\n$address';
}

List<String> missingCertificateFields({
  required DentistProfile profile,
  required Patient patient,
  required Procedure procedure,
}) {
  final missing = <String>[];
  if (!dentistCroReady(profile)) missing.add('CRO');
  if (patient.name.trim().isEmpty) missing.add('Paciente');
  if (patient.isMinor && patient.guardian.trim().isEmpty) {
    missing.add('Responsável legal');
  }
  for (final site in procedure.pillars) {
    if (procedure.modality == Modality.implante) {
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
