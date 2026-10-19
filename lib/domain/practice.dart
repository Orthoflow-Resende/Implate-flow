import 'models.dart';

List<CareLocation> activeCareLocations(List<CareLocation> locations) =>
    [for (final location in locations) if (location.active) location];

CareLocation? defaultCareLocation(List<CareLocation> locations) {
  for (final location in locations) {
    if (location.active && location.isDefault) return location;
  }
  return null;
}

String? careLocationIssue(List<CareLocation> locations) {
  final active = activeCareLocations(locations);
  final defaults = active.where((location) => location.isDefault).length;
  if (active.isNotEmpty && defaults != 1) return 'É preciso exatamente um local padrão.';
  if (locations.any((location) => !location.active && location.isDefault)) {
    return 'Local inativo não pode ser o padrão.';
  }
  return null;
}

List<CareLocation> addCareLocation(List<CareLocation> locations, CareLocation created) {
  final becomesDefault = activeCareLocations(locations).isEmpty;
  return [
    for (final location in locations)
      becomesDefault ? location.copyWith(isDefault: false) : location,
    created.copyWith(active: true, isDefault: becomesDefault),
  ];
}

List<CareLocation> updateCareLocation(List<CareLocation> locations, CareLocation edited) {
  return [
    for (final location in locations)
      if (location.id == edited.id)
        location.copyWith(name: edited.name, address: edited.address)
      else
        location,
  ];
}

List<CareLocation> setDefaultCareLocation(List<CareLocation> locations, String id) {
  return [
    for (final location in locations)
      location.copyWith(isDefault: location.active && location.id == id),
  ];
}

bool needsDefaultReplacement(List<CareLocation> locations, String id) {
  final target = locations.where((location) => location.id == id);
  if (target.isEmpty) return false;
  final location = target.first;
  if (!location.active || !location.isDefault) return false;
  return activeCareLocations(locations).length > 1;
}

List<CareLocation> inactivateCareLocation(
  List<CareLocation> locations,
  String id, {
  String? replacementId,
}) {
  return [
    for (final location in locations)
      if (location.id == id)
        location.copyWith(active: false, isDefault: false)
      else if (replacementId != null && location.id == replacementId)
        location.copyWith(isDefault: true)
      else
        location,
  ];
}

List<CareLocation> reactivateCareLocation(List<CareLocation> locations, String id) {
  final hasDefault = defaultCareLocation(locations) != null;
  return [
    for (final location in locations)
      if (location.id == id)
        location.copyWith(active: true, isDefault: !hasDefault)
      else
        location,
  ];
}

class LocationFilter {
  const LocationFilter.all() : locationId = null, withoutLocation = false;

  const LocationFilter.none() : locationId = null, withoutLocation = true;

  const LocationFilter.place(this.locationId) : withoutLocation = false;

  final String? locationId;
  final bool withoutLocation;

  bool get isAll => locationId == null && !withoutLocation;
}

List<Patient> filterPatientsByLocation(List<Patient> patients, LocationFilter filter) {
  if (filter.isAll) return patients;
  if (filter.withoutLocation) {
    return [for (final patient in patients) if (patient.locationIds.isEmpty) patient];
  }
  final id = filter.locationId;
  return [
    for (final patient in patients)
      if (id != null && patient.locationIds.contains(id)) patient,
  ];
}

Patient normalizePatientContacts(Patient patient) {
  final email = patient.email.trim();
  final phoneDigits = brazilianPhoneDigits(patient.phone);
  final cpfDigits = digitsOnly(patient.cpf);
  final phone = isValidBrazilianPhone(phoneDigits) ? phoneDigits : '';
  final cpf = cpfDigits.isEmpty || isValidCpf(cpfDigits) ? cpfDigits : '';
  return patient.copyWith(
    email: email,
    phone: phone,
    cpf: cpf,
    notifyByEmail: patient.notifyByEmail && isValidEmail(email),
    notifyByPhone: patient.notifyByPhone && isValidBrazilianPhone(phone),
  );
}

class StageNoticePlan {
  const StageNoticePlan({required this.stageLabel, required this.channels});

  final String stageLabel;
  final List<String> channels;
}

const noticeEmailChannel = 'e-mail';
const noticePhoneChannel = 'telefone';

StageNoticePlan? stageNoticePlan({
  required String previousStatus,
  required String nextStatus,
  required bool clinicalChange,
  required Patient patient,
}) {
  if (!clinicalChange || previousStatus == nextStatus) return null;
  final channels = enabledNoticeChannels(patient);
  if (channels.isEmpty) return null;
  return StageNoticePlan(stageLabel: nextStatus, channels: channels);
}

List<String> enabledNoticeChannels(Patient patient) {
  return [
    if (patient.notifyByEmail && isValidEmail(patient.email)) noticeEmailChannel,
    if (patient.notifyByPhone && isValidBrazilianPhone(patient.phone)) noticePhoneChannel,
  ];
}

String stageNoticePreview(StageNoticePlan plan) {
  return 'Notificação prevista por ${plan.channels.join(' e ')}. '
      'O envio só aparece como concluído depois da confirmação do serviço.';
}

String stageNoticeStatusLabel(StageNotice notice) => switch (notice.delivery) {
      NoticeDelivery.aguardando =>
        'Aguardando confirmação do envio · ${notice.channels.join(' e ')}',
      NoticeDelivery.falha => 'Falha no envio · ${notice.channels.join(' e ')}',
      NoticeDelivery.revogada => 'Envio cancelado · canal desativado',
      NoticeDelivery.enviado => 'Enviado · ${notice.channels.join(' e ')}',
    };

List<StageNotice> revokePendingNotices(List<StageNotice> notices, Patient patient) {
  final allowed = enabledNoticeChannels(patient).toSet();
  return [
    for (final notice in notices)
      if (notice.delivery != NoticeDelivery.aguardando)
        notice
      else
        _revoke(notice, allowed),
  ];
}

StageNotice _revoke(StageNotice notice, Set<String> allowed) {
  final channels = [for (final channel in notice.channels) if (allowed.contains(channel)) channel];
  if (channels.isEmpty) {
    return notice.copyWith(channels: const [], delivery: NoticeDelivery.revogada);
  }
  return notice.copyWith(channels: channels);
}

List<StageNotice> reprocessNotice(List<StageNotice> notices, String id) {
  return [
    for (final notice in notices)
      if (notice.id == id && notice.delivery == NoticeDelivery.falha)
        notice.copyWith(delivery: NoticeDelivery.aguardando)
      else
        notice,
  ];
}
