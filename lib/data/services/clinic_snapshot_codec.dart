import 'dart:convert';

import '../../domain/clinic_snapshot.dart';
import '../../domain/models.dart';

String encodeClinicSnapshot(ClinicSnapshot snapshot) {
  return const JsonEncoder.withIndent('  ').convert(snapshotToJson(snapshot));
}

ClinicSnapshot decodeClinicSnapshot(String source) {
  return snapshotFromJson(jsonDecode(source) as Map<String, dynamic>);
}

Map<String, dynamic> snapshotToJson(ClinicSnapshot snapshot) {
  return {
    'version': 1,
    'signedIn': snapshot.signedIn,
    'sequence': snapshot.sequence,
    'profile': {
      'name': snapshot.profile.name,
      'email': snapshot.profile.email,
      'cro': snapshot.profile.cro,
      'reminderEnabled': snapshot.profile.reminderEnabled,
      'reminderDaysBefore': snapshot.profile.reminderDaysBefore,
      'emailChannel': snapshot.profile.emailChannel,
      'pushChannel': snapshot.profile.pushChannel,
    },
    'patients': [
      for (final patient in snapshot.patients)
        {
          'id': patient.id,
          'name': patient.name,
          'phone': patient.phone,
          'cpf': patient.cpf,
          'birthDate': _date(patient.birthDate),
          'notes': patient.notes,
          'guardian': patient.guardian,
        },
    ],
    'procedures': [
      for (final procedure in snapshot.procedures) _procedureToJson(procedure),
    ],
  };
}

ClinicSnapshot snapshotFromJson(Map<String, dynamic> json) {
  return ClinicSnapshot(
    signedIn: json['signedIn'] as bool? ?? false,
    sequence: json['sequence'] as int? ?? 0,
    profile: DentistProfile(
      name: json['profile']?['name'] as String? ?? '',
      email: json['profile']?['email'] as String? ?? '',
      cro: json['profile']?['cro'] as String? ?? '',
      reminderEnabled: json['profile']?['reminderEnabled'] as bool? ?? true,
      reminderDaysBefore: _reminderDays(json['profile']),
      emailChannel: json['profile']?['emailChannel'] as bool? ?? true,
      pushChannel: json['profile']?['pushChannel'] as bool? ?? true,
    ),
    patients: [
      for (final item in json['patients'] as List<dynamic>? ?? const [])
        Patient(
          id: item['id'] as String,
          name: item['name'] as String,
          phone: item['phone'] as String? ?? '',
          cpf: item['cpf'] as String? ?? '',
          birthDate: _parseDate(item['birthDate'] as String),
          notes: item['notes'] as String? ?? '',
          guardian: item['guardian'] as String? ?? '',
        ),
    ],
    procedures: [
      for (final item in json['procedures'] as List<dynamic>? ?? const [])
        _procedureFromJson(item as Map<String, dynamic>),
    ],
  );
}

Map<String, dynamic> _procedureToJson(Procedure procedure) {
  return {
    'id': procedure.id,
    'patientId': procedure.patientId,
    'modality': procedure.modality.name,
    'arch': procedure.arch?.name,
    'surgeryDate': _date(procedure.surgeryDate),
    'statusLabel': procedure.statusLabel,
    'notes': procedure.notes,
    'certificateIssuedAt': _dateOrNull(procedure.certificateIssuedAt),
    'certificatePdfPath': procedure.certificatePdfPath,
    'sites': [
      for (final site in procedure.sites)
        {
          'fdi': site.fdi,
          'role': site.role.name,
          'piece': site.piece == null ? null : _pieceToJson(site.piece!),
          'grafts': [for (final graft in site.grafts) _graftToJson(graft)],
        },
    ],
    'visits': [
      for (final visit in procedure.visits)
        {
          'id': visit.id,
          'date': _date(visit.date),
          'note': visit.note,
          'statusLabel': visit.statusLabel,
        },
    ],
    'followUps': [
      for (final followUp in procedure.followUps)
        {
          'id': followUp.id,
          'date': _date(followUp.date),
          'reason': followUp.reason.name,
          'status': followUp.status.name,
          'reminderEnabled': followUp.reminderEnabled,
          'reminderDaysBefore': followUp.reminderDaysBefore,
          'overdueNotified': followUp.overdueNotified,
        },
    ],
    'photos': [
      for (final photo in procedure.photos)
        {
          'id': photo.id,
          'caption': photo.caption,
          'path': photo.path,
          'visitId': photo.visitId,
        },
    ],
  };
}

Procedure _procedureFromJson(Map<String, dynamic> json) {
  return Procedure(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    modality: Modality.values.byName(json['modality'] as String),
    arch: json['arch'] == null ? null : Arch.values.byName(json['arch'] as String),
    surgeryDate: _parseDate(json['surgeryDate'] as String),
    statusLabel: json['statusLabel'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    certificateIssuedAt: _parseDateOrNull(json['certificateIssuedAt'] as String?),
    certificatePdfPath: json['certificatePdfPath'] as String?,
    sites: [
      for (final site in json['sites'] as List<dynamic>? ?? const [])
        ToothSite(
          fdi: site['fdi'] as int,
          role: ToothRole.values.byName(site['role'] as String),
          piece: site['piece'] == null
              ? null
              : _pieceFromJson(site['piece'] as Map<String, dynamic>),
          grafts: [
            for (final graft in site['grafts'] as List<dynamic>? ?? const [])
              _graftFromJson(graft as Map<String, dynamic>),
          ],
        ),
    ],
    visits: [
      for (final visit in json['visits'] as List<dynamic>? ?? const [])
        Visit(
          id: visit['id'] as String,
          date: _parseDate(visit['date'] as String),
          note: visit['note'] as String? ?? '',
          statusLabel: visit['statusLabel'] as String? ?? '',
        ),
    ],
    followUps: [
      for (final item in json['followUps'] as List<dynamic>? ?? const [])
        FollowUp(
          id: item['id'] as String,
          date: _parseDate(item['date'] as String),
          reason: ReturnReason.values.byName(item['reason'] as String),
          status: ReturnStatus.values.byName(item['status'] as String),
          reminderEnabled: item['reminderEnabled'] as bool? ?? true,
          reminderDaysBefore: _reminderDays(item),
          overdueNotified: item['overdueNotified'] as bool? ?? false,
        ),
    ],
    photos: [
      for (final photo in json['photos'] as List<dynamic>? ?? const [])
        ClinicPhoto(
          id: photo['id'] as String,
          caption: photo['caption'] as String? ?? '',
          path: photo['path'] as String? ?? '',
          visitId: photo['visitId'] as String?,
        ),
    ],
  );
}

Map<String, dynamic> _pieceToJson(ImplantPiece piece) {
  return {
    'manufacturer': piece.manufacturer,
    'model': piece.model,
    'size': piece.size,
    'serial': piece.serial,
    'lot': piece.lot,
    'manufacturedOn': _dateOrNull(piece.manufacturedOn),
    'expiresOn': _dateOrNull(piece.expiresOn),
    'anvisa': piece.anvisa,
  };
}

ImplantPiece _pieceFromJson(Map<String, dynamic> json) {
  return ImplantPiece(
    manufacturer: json['manufacturer'] as String? ?? '',
    model: json['model'] as String? ?? '',
    size: json['size'] as String? ?? '',
    serial: json['serial'] as String? ?? '',
    lot: json['lot'] as String? ?? '',
    manufacturedOn: _parseDateOrNull(json['manufacturedOn'] as String?),
    expiresOn: _parseDateOrNull(json['expiresOn'] as String?),
    anvisa: json['anvisa'] as String? ?? '',
  );
}

Map<String, dynamic> _graftToJson(GraftMaterial graft) {
  return {
    'origin': graft.origin.name,
    'manufacturer': graft.manufacturer,
    'model': graft.model,
    'size': graft.size,
    'serial': graft.serial,
    'lot': graft.lot,
    'manufacturedOn': _dateOrNull(graft.manufacturedOn),
    'expiresOn': _dateOrNull(graft.expiresOn),
    'anvisa': graft.anvisa,
    'donorSite': graft.donorSite,
  };
}

GraftMaterial _graftFromJson(Map<String, dynamic> json) {
  return GraftMaterial(
    origin: GraftOrigin.values.byName(json['origin'] as String),
    manufacturer: json['manufacturer'] as String? ?? '',
    model: json['model'] as String? ?? '',
    size: json['size'] as String? ?? '',
    serial: json['serial'] as String? ?? '',
    lot: json['lot'] as String? ?? '',
    manufacturedOn: _parseDateOrNull(json['manufacturedOn'] as String?),
    expiresOn: _parseDateOrNull(json['expiresOn'] as String?),
    anvisa: json['anvisa'] as String? ?? '',
    donorSite: json['donorSite'] as String? ?? '',
  );
}

String _date(DateTime date) => date.toIso8601String();

String? _dateOrNull(DateTime? date) => date?.toIso8601String();

DateTime _parseDate(String value) => DateTime.parse(value);

DateTime? _parseDateOrNull(String? value) =>
    value == null || value.isEmpty ? null : DateTime.parse(value);

int _reminderDays(Object? json) {
  if (json is! Map) return defaultReminderDaysBefore;
  final raw = json['reminderDaysBefore'];
  if (raw is! int) return defaultReminderDaysBefore;
  return normalizeReminderDaysBefore(raw);
}
