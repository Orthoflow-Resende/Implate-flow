enum Modality { unitario, ponte, protocolo, enxerto }

enum ToothRole { pilar, pontico }

enum Arch { superior, inferior }

enum ImplantStatus {
  planejado,
  instalado,
  osseointegracao,
  reabertura,
  protese,
  concluido,
  manutencao,
  intercorrencia,
}

enum GraftStatus {
  planejado,
  realizado,
  maturacao,
  prontoParaImplante,
  intercorrencia,
}

enum GraftOrigin { biomaterial, autogeno }

enum ReturnReason {
  sutura,
  osseointegracao,
  instalarImplante,
  instalarPonte,
  instalarProtocolo,
  controle,
  reabertura,
}

enum ReturnStatus { agendado, realizado, faltou }

enum CalendarKind { cirurgia, consulta, retorno }

const upperArch = <int>[
  18, 17, 16, 15, 14, 13, 12, 11,
  21, 22, 23, 24, 25, 26, 27, 28,
];

const lowerArch = <int>[
  48, 47, 46, 45, 44, 43, 42, 41,
  31, 32, 33, 34, 35, 36, 37, 38,
];

const chipOrder = <int>[
  18, 17, 16, 15, 14, 13, 12, 11,
  21, 22, 23, 24, 25, 26, 27, 28,
  48, 47, 46, 45, 44, 43, 42, 41,
  31, 32, 33, 34, 35, 36, 37, 38,
];

const implantCatalog = <String, List<String>>{
  'Neodent': ['Drive GM', 'Helix GM', 'Grand Morse'],
  'Straumann': ['BLX', 'BLT', 'TLX'],
  'Nobel Biocare': ['NobelActive', 'NobelParallel'],
};

const implantSizes = <String>[
  '3.3 × 8 mm',
  '3.3 × 10 mm',
  '3.3 × 11.5 mm',
  '3.3 × 13 mm',
  '3.5 × 8 mm',
  '3.5 × 10 mm',
  '3.5 × 11.5 mm',
  '3.5 × 13 mm',
  '3.75 × 8 mm',
  '3.75 × 10 mm',
  '3.75 × 11.5 mm',
  '3.75 × 13 mm',
  '4.0 × 8 mm',
  '4.0 × 10 mm',
  '4.0 × 11.5 mm',
  '4.0 × 13 mm',
  '4.3 × 10 mm',
  '4.3 × 11.5 mm',
  '4.3 × 13 mm',
  '4.3 × 16 mm',
  '4.5 × 8 mm',
  '4.5 × 10 mm',
  '4.5 × 13 mm',
  '5.0 × 8 mm',
  '5.0 × 10 mm',
  '5.0 × 11.5 mm',
  '5.0 × 13 mm',
];

List<String> withCurrentOption(List<String> options, String current) {
  if (current.isNotEmpty && !options.contains(current)) {
    return [current, ...options];
  }
  return options;
}

const graftCatalog = <String, List<String>>{
  'Geistlich': ['Bio-Oss', 'Bio-Oss Collagen'],
  'Straumann': ['cerabone', 'maxgraft'],
  'Baumer': ['Ox Bone'],
};

List<int> archOf(int tooth) =>
    upperArch.contains(tooth) ? upperArch : lowerArch;

Arch sideOf(int tooth) =>
    upperArch.contains(tooth) ? Arch.superior : Arch.inferior;

int compareTeeth(int a, int b) => chipOrder.indexOf(a).compareTo(chipOrder.indexOf(b));

bool isContiguousSpan(Iterable<int> teeth) {
  final list = teeth.toList();
  if (list.length < 2) return true;
  final arch = archOf(list.first);
  if (list.any((tooth) => !arch.contains(tooth))) return false;
  final indexes = list.map(arch.indexOf).toList()..sort();
  for (var i = 1; i < indexes.length; i++) {
    if (indexes[i] != indexes[i - 1] + 1) return false;
  }
  return true;
}

String modalityLabel(Modality modality) => switch (modality) {
      Modality.unitario => 'Implante unitário',
      Modality.ponte => 'Ponte fixa',
      Modality.protocolo => 'Protocolo',
      Modality.enxerto => 'Enxerto sozinho',
    };

String archLabel(Arch arch) =>
    arch == Arch.superior ? 'Arcada superior' : 'Arcada inferior';

String roleLabel(ToothRole role) => role == ToothRole.pilar ? 'Pilar' : 'Pôntico';

String implantStatusLabel(ImplantStatus status) => switch (status) {
      ImplantStatus.planejado => 'Planejado',
      ImplantStatus.instalado => 'Instalado',
      ImplantStatus.osseointegracao => 'Em osseointegração',
      ImplantStatus.reabertura => 'Reabertura',
      ImplantStatus.protese => 'Prótese',
      ImplantStatus.concluido => 'Concluído',
      ImplantStatus.manutencao => 'Manutenção',
      ImplantStatus.intercorrencia => 'Intercorrência',
    };

String graftStatusLabel(GraftStatus status) => switch (status) {
      GraftStatus.planejado => 'Planejado',
      GraftStatus.realizado => 'Realizado',
      GraftStatus.maturacao => 'Em maturação',
      GraftStatus.prontoParaImplante => 'Pronto para implante',
      GraftStatus.intercorrencia => 'Intercorrência',
    };

String returnReasonLabel(ReturnReason reason) => switch (reason) {
      ReturnReason.sutura => 'Remoção de sutura',
      ReturnReason.osseointegracao => 'Osseointegração',
      ReturnReason.instalarImplante => 'Instalar o implante',
      ReturnReason.instalarPonte => 'Instalar a ponte',
      ReturnReason.instalarProtocolo => 'Instalar o protocolo',
      ReturnReason.controle => 'Retorno de controle',
      ReturnReason.reabertura => 'Retorno para reabertura',
    };

int returnReasonOrder(ReturnReason reason) => switch (reason) {
      ReturnReason.sutura => 0,
      ReturnReason.controle => 1,
      ReturnReason.reabertura => 2,
      ReturnReason.osseointegracao => 3,
      ReturnReason.instalarImplante => 3,
      ReturnReason.instalarPonte => 3,
      ReturnReason.instalarProtocolo => 3,
    };

List<FollowUp> chronologicalFollowUps(List<FollowUp> followUps) {
  return [...followUps]..sort((a, b) {
      final byDate = dateOnly(a.date).compareTo(dateOnly(b.date));
      if (byDate != 0) return byDate;
      return returnReasonOrder(a.reason).compareTo(returnReasonOrder(b.reason));
    });
}

String returnStatusLabel(ReturnStatus status) => switch (status) {
      ReturnStatus.agendado => 'Agendado',
      ReturnStatus.realizado => 'Realizado',
      ReturnStatus.faltou => 'Faltou',
    };

const defaultReminderDaysBefore = 15;

const reminderLeadDayOptions = <int>[7, 15, 30];

int normalizeReminderDaysBefore(int days) =>
    days < 1 ? defaultReminderDaysBefore : days;

class DentistProfile {
  const DentistProfile({
    required this.name,
    required this.email,
    this.cro = '',
    this.reminderEnabled = true,
    this.reminderDaysBefore = defaultReminderDaysBefore,
    this.emailChannel = true,
    this.pushChannel = true,
  });

  final String name;
  final String email;
  final String cro;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final bool emailChannel;
  final bool pushChannel;

  DentistProfile copyWith({
    String? name,
    String? email,
    String? cro,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    bool? emailChannel,
    bool? pushChannel,
  }) {
    return DentistProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      cro: cro ?? this.cro,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      emailChannel: emailChannel ?? this.emailChannel,
      pushChannel: pushChannel ?? this.pushChannel,
    );
  }
}

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.phone,
    required this.birthDate,
    this.cpf = '',
    this.notes = '',
    this.guardian = '',
  });

  final String id;
  final String name;
  final String phone;
  final String cpf;
  final DateTime birthDate;
  final String notes;
  final String guardian;

  bool get isMinor {
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    final birthday = DateTime(today.year, birthDate.month, birthDate.day);
    if (birthday.isAfter(DateTime(today.year, today.month, today.day))) age--;
    return age < 18;
  }

  Patient copyWith({
    String? name,
    String? phone,
    String? cpf,
    DateTime? birthDate,
    String? notes,
    String? guardian,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
      guardian: guardian ?? this.guardian,
    );
  }
}

class ImplantPiece {
  const ImplantPiece({
    this.manufacturer = '',
    this.model = '',
    this.size = '',
    this.lot = '',
    this.manufacturedOn,
    this.expiresOn,
    this.anvisa = '',
  });

  final String manufacturer;
  final String model;
  final String size;
  final String lot;
  final DateTime? manufacturedOn;
  final DateTime? expiresOn;
  final String anvisa;

  bool get certificateReady =>
      manufacturer.isNotEmpty &&
      model.isNotEmpty &&
      size.isNotEmpty &&
      manufacturedOn != null &&
      expiresOn != null;
}

class GraftMaterial {
  const GraftMaterial({
    required this.origin,
    this.manufacturer = '',
    this.model = '',
    this.size = '',
    this.lot = '',
    this.manufacturedOn,
    this.expiresOn,
    this.anvisa = '',
    this.donorSite = '',
  });

  final GraftOrigin origin;
  final String manufacturer;
  final String model;
  final String size;
  final String lot;
  final DateTime? manufacturedOn;
  final DateTime? expiresOn;
  final String anvisa;
  final String donorSite;

  bool get certificateReady => switch (origin) {
        GraftOrigin.biomaterial =>
          manufacturer.isNotEmpty && model.isNotEmpty && expiresOn != null,
        GraftOrigin.autogeno => donorSite.isNotEmpty,
      };
}

class ToothSite {
  const ToothSite({
    required this.fdi,
    required this.role,
    this.piece,
    this.grafts = const [],
  });

  final int fdi;
  final ToothRole role;
  final ImplantPiece? piece;
  final List<GraftMaterial> grafts;
}

class Visit {
  Visit({
    required this.id,
    required this.date,
    required this.note,
    required this.statusLabel,
  });

  final String id;
  final DateTime date;
  final String note;
  final String statusLabel;
}

class ClinicPhoto {
  const ClinicPhoto({
    required this.id,
    required this.caption,
    this.path = '',
    this.visitId,
  });

  final String id;
  final String caption;
  final String path;
  final String? visitId;
}

class FollowUp {
  const FollowUp({
    required this.id,
    required this.date,
    required this.reason,
    required this.status,
    required this.reminderEnabled,
    this.reminderDaysBefore = defaultReminderDaysBefore,
    this.overdueNotified = false,
  });

  final String id;
  final DateTime date;
  final ReturnReason reason;
  final ReturnStatus status;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final bool overdueNotified;

  DateTime get reminderOn => dateOnly(date).subtract(Duration(days: reminderDaysBefore));

  FollowUp copyWith({
    DateTime? date,
    ReturnReason? reason,
    ReturnStatus? status,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    bool? overdueNotified,
  }) {
    return FollowUp(
      id: id,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      overdueNotified: overdueNotified ?? this.overdueNotified,
    );
  }
}

class Procedure {
  Procedure({
    required this.id,
    required this.patientId,
    required this.modality,
    required this.surgeryDate,
    required this.sites,
    required this.statusLabel,
    this.arch,
    this.notes = '',
    List<Visit>? visits,
    List<FollowUp>? followUps,
    List<ClinicPhoto>? photos,
    this.certificateIssuedAt,
    this.certificatePdfPath,
  })  : visits = visits ?? [],
        followUps = followUps ?? [],
        photos = photos ?? [];

  final String id;
  final String patientId;
  final Modality modality;
  final Arch? arch;
  final DateTime surgeryDate;
  final String statusLabel;
  final String notes;
  final List<ToothSite> sites;
  final List<Visit> visits;
  final List<FollowUp> followUps;
  final List<ClinicPhoto> photos;
  final DateTime? certificateIssuedAt;
  final String? certificatePdfPath;

  Procedure copyWith({
    String? statusLabel,
    String? notes,
    List<ToothSite>? sites,
    List<Visit>? visits,
    List<FollowUp>? followUps,
    List<ClinicPhoto>? photos,
    DateTime? certificateIssuedAt,
    String? certificatePdfPath,
  }) {
    return Procedure(
      id: id,
      patientId: patientId,
      modality: modality,
      surgeryDate: surgeryDate,
      sites: sites ?? this.sites,
      statusLabel: statusLabel ?? this.statusLabel,
      arch: arch,
      notes: notes ?? this.notes,
      visits: visits ?? this.visits,
      followUps: followUps ?? this.followUps,
      photos: photos ?? this.photos,
      certificateIssuedAt: certificateIssuedAt ?? this.certificateIssuedAt,
      certificatePdfPath: certificatePdfPath ?? this.certificatePdfPath,
    );
  }

  List<ToothSite> get pillars =>
      sites.where((site) => site.role == ToothRole.pilar).toList();

  List<ToothSite> get pontics =>
      sites.where((site) => site.role == ToothRole.pontico).toList();

  String get teethLabel {
    final numbers = sites.map((site) => site.fdi).toList()..sort(compareTeeth);
    if (modality == Modality.protocolo && arch != null) {
      return '${archLabel(arch!)} · ${numbers.join(', ')}';
    }
    return numbers.join(', ');
  }
}

class CalendarMark {
  CalendarMark({
    required this.date,
    required this.patientId,
    required this.patientName,
    required this.kind,
    required this.label,
    required this.procedureId,
    this.returnStatus,
    this.overdue = false,
  });

  final DateTime date;
  final String patientId;
  final String patientName;
  final CalendarKind kind;
  final String label;
  final String procedureId;
  final ReturnStatus? returnStatus;
  final bool overdue;
}

String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

String formatCpf(String value) {
  final digits = digitsOnly(value);
  if (digits.length != 11) return value.trim();
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
}

String cpfLabel(String value) {
  final formatted = formatCpf(value);
  return formatted.isEmpty ? 'CPF não informado' : formatted;
}

String formatDay(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Civil day in America/Sao_Paulo. Brasília stays at UTC−3, without daylight saving.
DateTime brasiliaToday([DateTime? instant]) {
  final utc = (instant ?? DateTime.now()).toUtc();
  final civil = utc.subtract(const Duration(hours: 3));
  return DateTime(civil.year, civil.month, civil.day);
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime addCalendarMonths(DateTime date, int months) {
  final total = date.month + months;
  final year = date.year + ((total - 1) ~/ 12);
  final month = ((total - 1) % 12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(year, month, day);
}

String reminderLine({
  required Patient patient,
  required Procedure procedure,
  required FollowUp followUp,
}) {
  return '${patient.name}, ${procedure.teethLabel}, ${returnReasonLabel(followUp.reason)}';
}

String reminderLeadChipLabel(int days) => days == 1 ? '1 dia' : '$days dias';

String reminderLeadLabel(int days) => '${reminderLeadChipLabel(days)} antes';
