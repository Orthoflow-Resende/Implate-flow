import 'package:flutter/foundation.dart';

import '../../data/repositories/clinic_repository.dart';
import '../../domain/models.dart';

class GraftDraft {
  GraftOrigin origin = GraftOrigin.biomaterial;
  String manufacturer = '';
  String model = '';
  String size = '';
  String lot = '';
  String anvisa = '';
  DateTime? manufacturedOn;
  DateTime? expiresOn;
  String donorSite = '';

  GraftDraft copy() {
    return GraftDraft()
      ..origin = origin
      ..manufacturer = manufacturer
      ..model = model
      ..size = size
      ..lot = lot
      ..anvisa = anvisa
      ..manufacturedOn = manufacturedOn
      ..expiresOn = expiresOn
      ..donorSite = donorSite;
  }

  GraftMaterial toMaterial() {
    return GraftMaterial(
      origin: origin,
      manufacturer: manufacturer,
      model: model,
      size: size,
      lot: lot,
      anvisa: anvisa,
      manufacturedOn: manufacturedOn,
      expiresOn: expiresOn,
      donorSite: donorSite,
    );
  }

  static GraftDraft fromMaterial(GraftMaterial graft) {
    return GraftDraft()
      ..origin = graft.origin
      ..manufacturer = graft.manufacturer
      ..model = graft.model
      ..size = graft.size
      ..lot = graft.lot
      ..anvisa = graft.anvisa
      ..manufacturedOn = graft.manufacturedOn
      ..expiresOn = graft.expiresOn
      ..donorSite = graft.donorSite;
  }
}

class PieceDraft {
  String manufacturer = '';
  String model = '';
  String size = '';
  String lot = '';
  String anvisa = '';
  DateTime? manufacturedOn;
  DateTime? expiresOn;
  bool withGraft = false;
  List<GraftDraft> grafts = [GraftDraft()];

  static PieceDraft fromSite(ToothSite site) {
    final piece = site.piece;
    return PieceDraft()
      ..manufacturer = piece?.manufacturer ?? ''
      ..model = piece?.model ?? ''
      ..size = piece?.size ?? ''
      ..lot = piece?.lot ?? ''
      ..anvisa = piece?.anvisa ?? ''
      ..manufacturedOn = piece?.manufacturedOn
      ..expiresOn = piece?.expiresOn
      ..withGraft = site.grafts.isNotEmpty
      ..grafts = site.grafts.isEmpty
          ? [GraftDraft()]
          : [for (final graft in site.grafts) GraftDraft.fromMaterial(graft)];
  }
}

class ExtraReturnDraft {
  ExtraReturnDraft({
    required this.id,
    required this.reason,
    required this.date,
    required this.reminderEnabled,
    required this.reminderDaysBefore,
  });

  final int id;
  final ReturnReason reason;
  DateTime date;
  bool reminderEnabled;
  int reminderDaysBefore;
}

class NewProcedureViewModel extends ChangeNotifier {
  NewProcedureViewModel(this.repository, {required this.patientId}) {
    final profile = repository.current.profile;
    longReminder = profile.reminderEnabled;
    longLead = profile.reminderDaysBefore;
  }

  final ClinicRepository repository;
  final String patientId;

  int step = 0;
  Modality? modality;
  Arch arch = Arch.superior;
  final Set<int> selected = {};
  final Map<int, ToothRole> roles = {};
  final Map<int, PieceDraft> drafts = {};
  DateTime surgery = dateOnly(DateTime.now());
  late DateTime suture = surgery.add(const Duration(days: 7));
  late DateTime longReturn = surgery.add(const Duration(days: 90));
  late bool longReminder;
  late int longLead;
  final List<ExtraReturnDraft> extraReturns = [];
  int _extraSeq = 0;

  List<int> get ordered => selected.toList()..sort(compareTeeth);

  List<int> get pillars => ordered.where((tooth) {
        if (modality != Modality.ponte) return true;
        return (roles[tooth] ?? ToothRole.pilar) == ToothRole.pilar;
      }).toList();

  bool get canContinue => switch (modality) {
        Modality.ponte => selected.isNotEmpty && isContiguousSpan(selected) && pillars.isNotEmpty,
        Modality.protocolo => selected.length >= 2,
        null => false,
        _ => selected.isNotEmpty,
      };

  Arch? get disabledArch => modality == Modality.protocolo
      ? (arch == Arch.superior ? Arch.inferior : Arch.superior)
      : null;

  void chooseModality(Modality value) {
    modality = value;
    selected.clear();
    roles.clear();
    step = 1;
    notifyListeners();
  }

  void chooseArch(Arch value) {
    arch = value;
    selected.clear();
    roles.clear();
    notifyListeners();
  }

  void backToModality() {
    step = 0;
    notifyListeners();
  }

  void backToMouth() {
    step = 1;
    notifyListeners();
  }

  String? toggleTooth(int tooth) {
    final current = modality;
    if (current == null) return null;
    if (selected.contains(tooth)) {
      selected.remove(tooth);
      roles.remove(tooth);
      drafts.remove(tooth);
      _syncRoles();
      notifyListeners();
      return null;
    }
    if (current == Modality.ponte) {
      final next = {...selected, tooth};
      if (!isContiguousSpan(next)) {
        return 'A ponte precisa de um trecho contínuo da mesma arcada.';
      }
    }
    if (current == Modality.protocolo && sideOf(tooth) != arch) return null;
    selected.add(tooth);
    _syncRoles();
    notifyListeners();
    return null;
  }

  void flipRole(int tooth) {
    final current = roles[tooth] ?? ToothRole.pilar;
    roles[tooth] = current == ToothRole.pilar ? ToothRole.pontico : ToothRole.pilar;
    notifyListeners();
  }

  void openSummary() {
    for (final tooth in pillars) {
      drafts.putIfAbsent(tooth, PieceDraft.new);
    }
    drafts.removeWhere((tooth, _) => !pillars.contains(tooth));
    longReturn = addCalendarMonths(surgery, longMonths);
    step = 2;
    notifyListeners();
  }

  int get longMonths {
    if (modality == Modality.enxerto) return 6;
    final grafted = pillars.any((tooth) => drafts[tooth]?.withGraft ?? false);
    return grafted ? 6 : 3;
  }

  ReturnReason get longReason => switch (modality!) {
        Modality.enxerto => ReturnReason.instalarImplante,
        Modality.ponte => ReturnReason.instalarPonte,
        Modality.protocolo => ReturnReason.instalarProtocolo,
        Modality.unitario => ReturnReason.osseointegracao,
      };

  void setSurgery(DateTime value) {
    surgery = value;
    suture = value.add(const Duration(days: 7));
    longReturn = addCalendarMonths(value, longMonths);
    notifyListeners();
  }

  void setSuture(DateTime value) {
    suture = value;
    notifyListeners();
  }

  void setLongReturn(DateTime value) {
    longReturn = value;
    notifyListeners();
  }

  void setLongReminder(bool value) {
    longReminder = value;
    notifyListeners();
  }

  void setLongLead(int value) {
    longLead = normalizeReminderDaysBefore(value);
    notifyListeners();
  }

  void addExtraReturn(ReturnReason reason) {
    extraReturns.add(
      ExtraReturnDraft(
        id: _extraSeq++,
        reason: reason,
        date: _freeReturnDate(_seedFor(reason)),
        reminderEnabled: longReminder,
        reminderDaysBefore: longLead,
      ),
    );
    _sortExtraReturns();
    notifyListeners();
  }

  void setExtraDate(int id, DateTime value) {
    final draft = _extraById(id);
    if (draft == null) return;
    draft.date = dateOnly(value);
    _sortExtraReturns();
    notifyListeners();
  }

  void setExtraReminder(int id, bool value) {
    final draft = _extraById(id);
    if (draft == null) return;
    draft.reminderEnabled = value;
    notifyListeners();
  }

  void setExtraLead(int id, int value) {
    final draft = _extraById(id);
    if (draft == null) return;
    draft.reminderDaysBefore = normalizeReminderDaysBefore(value);
    notifyListeners();
  }

  void removeExtraReturn(int id) {
    extraReturns.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  ExtraReturnDraft? _extraById(int id) {
    for (final draft in extraReturns) {
      if (draft.id == id) return draft;
    }
    return null;
  }

  DateTime _seedFor(ReturnReason reason) {
    if (reason == ReturnReason.reabertura) return addCalendarMonths(longReturn, 1);
    return surgery.add(const Duration(days: 30));
  }

  DateTime _freeReturnDate(DateTime seed) {
    var date = dateOnly(seed);
    final taken = {
      dateOnly(suture),
      dateOnly(longReturn),
      for (final extra in extraReturns) dateOnly(extra.date),
    };
    while (taken.contains(date)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  void _sortExtraReturns() {
    extraReturns.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return returnReasonOrder(a.reason).compareTo(returnReasonOrder(b.reason));
    });
  }

  void copyFromFirst() {
    final first = drafts[pillars.first];
    if (first == null) return;
    for (final tooth in pillars.skip(1)) {
      final draft = drafts[tooth];
      if (draft == null) continue;
      draft.manufacturer = first.manufacturer;
      draft.model = first.model;
      draft.size = first.size;
      draft.withGraft = first.withGraft;
      draft.grafts = [for (final graft in first.grafts) graft.copy()];
    }
    notifyListeners();
  }

  void updateDraft(int tooth, void Function(PieceDraft draft) change) {
    final draft = drafts[tooth];
    if (draft == null) return;
    change(draft);
    if (draft.withGraft) {
      longReturn = addCalendarMonths(surgery, longMonths);
    }
    notifyListeners();
  }

  void addGraft(int tooth) {
    updateDraft(tooth, (draft) => draft.grafts.add(GraftDraft()));
  }

  void removeGraft(int tooth, int index) {
    updateDraft(tooth, (draft) {
      if (draft.grafts.length <= 1) return;
      draft.grafts.removeAt(index);
    });
  }

  List<Procedure> save() {
    final current = modality!;
    final grouped = current == Modality.ponte || current == Modality.protocolo;
    final groups = grouped ? [ordered] : pillars.map((tooth) => [tooth]).toList();
    final created = <Procedure>[];
    for (final teeth in groups) {
      created.add(
        Procedure(
          id: repository.allocateId('pro'),
          patientId: patientId,
          modality: current,
          arch: current == Modality.protocolo ? arch : null,
          surgeryDate: surgery,
          statusLabel: current == Modality.enxerto
              ? graftStatusLabel(GraftStatus.realizado)
              : implantStatusLabel(ImplantStatus.instalado),
          sites: [
            for (final tooth in teeth)
              ToothSite(
                fdi: tooth,
                role: roles[tooth] ?? ToothRole.pilar,
                piece: current == Modality.enxerto || roles[tooth] == ToothRole.pontico
                    ? null
                    : ImplantPiece(
                        manufacturer: drafts[tooth]?.manufacturer ?? '',
                        model: drafts[tooth]?.model ?? '',
                        size: drafts[tooth]?.size ?? '',
                        lot: drafts[tooth]?.lot ?? '',
                        anvisa: drafts[tooth]?.anvisa ?? '',
                        manufacturedOn: drafts[tooth]?.manufacturedOn,
                        expiresOn: drafts[tooth]?.expiresOn,
                      ),
                grafts: _graftsFor(tooth),
              ),
          ],
          followUps: chronologicalFollowUps([
            FollowUp(
              id: repository.allocateId('ret'),
              date: suture,
              reason: ReturnReason.sutura,
              status: ReturnStatus.agendado,
              reminderEnabled: false,
            ),
            for (final extra in extraReturns)
              FollowUp(
                id: repository.allocateId('ret'),
                date: extra.date,
                reason: extra.reason,
                status: ReturnStatus.agendado,
                reminderEnabled: extra.reminderEnabled,
                reminderDaysBefore: extra.reminderDaysBefore,
              ),
            FollowUp(
              id: repository.allocateId('ret'),
              date: longReturn,
              reason: longReason,
              status: ReturnStatus.agendado,
              reminderEnabled: longReminder,
              reminderDaysBefore: longLead,
            ),
          ]),
        ),
      );
    }
    repository.saveProcedures(created);
    return created;
  }

  List<GraftMaterial> _graftsFor(int tooth) {
    final draft = drafts[tooth];
    if (draft == null) return const [];
    final include = modality == Modality.enxerto || draft.withGraft;
    if (!include || roles[tooth] == ToothRole.pontico) return const [];
    return [for (final graft in draft.grafts) graft.toMaterial()];
  }

  void _syncRoles() {
    if (modality != Modality.ponte) {
      for (final tooth in selected) {
        roles[tooth] = ToothRole.pilar;
      }
      return;
    }
    final teeth = ordered;
    roles.removeWhere((tooth, _) => !selected.contains(tooth));
    for (var index = 0; index < teeth.length; index++) {
      final tooth = teeth[index];
      final isEnd = index == 0 || index == teeth.length - 1;
      roles.putIfAbsent(tooth, () => teeth.length <= 2 || isEnd ? ToothRole.pilar : ToothRole.pontico);
    }
  }
}
