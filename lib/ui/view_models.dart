import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import '../config/app_config.dart';
import '../data/repositories/clinic_repository.dart';
import '../data/services/clinic_files.dart';
import '../data/services/clinic_pdfs.dart';
import '../data/services/workos_auth.dart';
import '../domain/clinic_snapshot.dart';
import '../domain/models.dart';
import '../domain/queries.dart';

class RepositoryViewModel extends ChangeNotifier {
  RepositoryViewModel(this.repository) {
    _subscription = repository.watch().listen((next) {
      snapshot = next;
      loadError = null;
      notifyListeners();
    }, onError: (Object _) {
      loadError = 'Não foi possível atualizar os relatórios.';
      notifyListeners();
    });
  }

  final ClinicRepository repository;
  late ClinicSnapshot snapshot = repository.current;
  String? loadError;
  late final StreamSubscription<ClinicSnapshot> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class SessionViewModel extends RepositoryViewModel {
  SessionViewModel(super.repository, this.auth);

  final WorkOsAuth auth;
  bool busy = false;
  String? error;

  bool get signedIn => snapshot.signedIn;

  Future<void> signIn() async {
    if (busy) return;
    if (AppConfig.workOsClientId.isEmpty) {
      error = 'Preencha WORKOS_CLIENT_ID em config/local.json.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final identity = await auth.signIn(
        clientId: AppConfig.workOsClientId,
        redirectUri: AppConfig.workOsRedirectUri,
      );
      repository.signIn(name: identity.name, email: identity.email);
    } on WorkOsAuthException catch (error) {
      this.error = error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await auth.signOut(redirectUri: AppConfig.workOsRedirectUri);
    } on WorkOsAuthException {
      // The local session still ends so the dentist returns to login.
    } finally {
      repository.signOut();
      busy = false;
      notifyListeners();
    }
  }
}

class HomeViewModel extends RepositoryViewModel {
  HomeViewModel(super.repository) {
    repository.applyOverdueNotices();
  }

  DentistProfile get profile => snapshot.profile;

  DateTime get agendaToday => brasiliaToday();

  List<FollowUp> _scheduledOn(bool Function(DateTime day) test) {
    return scheduledFollowUps(snapshot.procedures).where((item) => test(dateOnly(item.date))).toList();
  }

  List<FollowUp> get today => _scheduledOn((day) => sameDay(day, agendaToday));

  List<FollowUp> get nextWeek => followUpsInNextDays(snapshot.procedures, agendaToday);

  int get nextWeekCount => nextWeek.length;

  int get overduePatientCount => patientsForReport(
        snapshot.procedures,
        snapshot.patients,
        ReportFilter.atrasados,
        agendaToday,
      ).length;

  List<FollowUp> get todayReminders => schedulingReminders(
        procedures: snapshot.procedures,
        day: agendaToday,
        remindersEnabled: profile.reminderEnabled,
      );

  int get todayReminderCount => todayReminders.length;

  Procedure? procedureOf(String followUpId) =>
      procedureOfFollowUp(snapshot.procedures, followUpId);

  Patient patientOf(String patientId) =>
      snapshot.patients.firstWhere((patient) => patient.id == patientId);

  List<Patient> patientsMatching(String query) => matchPatients(snapshot.patients, query);
}

class PatientsViewModel extends RepositoryViewModel {
  PatientsViewModel(super.repository);

  String query = '';

  List<Patient> get patients => matchPatients(snapshot.patients, query);

  int implantCount(String patientId) => implantsOf(snapshot.procedures, patientId).length;

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  Patient createPatient({
    required String name,
    required String phone,
    String cpf = '',
    required DateTime birthDate,
    String notes = '',
    String guardian = '',
  }) {
    return repository.createPatient(
      name: name,
      phone: phone,
      cpf: cpf,
      birthDate: birthDate,
      notes: notes,
      guardian: guardian,
    );
  }
}

class PatientViewModel extends RepositoryViewModel {
  PatientViewModel(super.repository, {required this.patientId});

  final String patientId;

  Patient get patient => snapshot.patients.firstWhere((item) => item.id == patientId);

  List<Procedure> get history => proceduresOf(snapshot.procedures, patientId);

  List<FollowUp> get upcoming => upcomingOf(snapshot.procedures, patientId);

  Procedure? procedureOf(String followUpId) =>
      procedureOfFollowUp(snapshot.procedures, followUpId);

  List<({DateTime date, String title, String detail, String? procedureId})> get timeline {
    return [
      for (final procedure in history) ...[
        (
          date: procedure.surgeryDate,
          title: 'Cirurgia',
          detail: '${procedure.classificationLabel} · ${procedure.teethLabel}',
          procedureId: procedure.id,
        ),
        for (final visit in procedure.visits)
          (
            date: visit.date,
            title: 'Consulta',
            detail: visit.note,
            procedureId: procedure.id,
          ),
      ],
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  void updatePatient(Patient patient) => repository.updatePatient(patient);

  Future<void> exportChart() async {
    final bytes = await buildPatientChartPdf(
      profile: snapshot.profile,
      patient: patient,
      history: history,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'prontuario-${patient.id}.pdf');
  }
}

class ReportsViewModel extends RepositoryViewModel {
  ReportsViewModel(super.repository, {this.filter = ReportFilter.atrasados});

  static const pageSize = 20;

  ReportFilter filter;
  ReportSpan span = ReportSpan.todos;
  DateTime? customStart;
  DateTime? customEnd;
  Modality? modality;
  String query = '';
  bool byAppointment = false;
  int visibleLimit = pageSize;

  DateTime get today => brasiliaToday();

  ReportWindow get window => ReportWindow.span(
        today,
        span,
        customStart: customStart,
        customEnd: customEnd,
      );

  ClinicReport get totals => clinicReport(
        procedures: snapshot.procedures,
        patients: snapshot.patients,
        today: today,
        window: window,
        modality: modality,
        query: query,
      );

  String get attendanceLabel {
    final percent = totals.attendancePercent;
    final rate = percent == null ? 'Comparecimento indisponível' : 'Comparecimento $percent%';
    return '$rate · ${totals.withOutcome} com desfecho · ${totals.pending} sem desfecho';
  }

  List<Patient> get patients => patientsForReport(
        snapshot.procedures,
        snapshot.patients,
        filter,
        today,
        window: window,
        modality: modality,
        query: query,
      );

  List<({Procedure procedure, FollowUp followUp})> rowsFor(String patientId) => reportFollowUps(
        snapshot.procedures,
        patientId,
        filter,
        today,
        window: window,
        modality: modality,
      );

  List<({Patient patient, Procedure procedure, FollowUp followUp})> get appointments {
    final rows = [
      for (final patient in patients)
        for (final row in rowsFor(patient.id))
          (patient: patient, procedure: row.procedure, followUp: row.followUp),
    ]..sort((a, b) {
        final byDate = a.followUp.date.compareTo(b.followUp.date);
        if (byDate != 0) return byDate;
        return a.patient.name.toLowerCase().compareTo(b.patient.name.toLowerCase());
      });
    return rows;
  }

  List<Patient> get visiblePatients => patients.take(visibleLimit).toList();

  List<({Patient patient, Procedure procedure, FollowUp followUp})> get visibleAppointments =>
      appointments.take(visibleLimit).toList();

  bool get hasMore =>
      (byAppointment ? appointments.length : patients.length) > visibleLimit;

  int get activeFilterCount {
    var count = span == ReportSpan.todos ? 0 : 1;
    if (modality != null) count++;
    return count;
  }

  void showMore() {
    visibleLimit += pageSize;
    notifyListeners();
  }

  void clearFilters() {
    span = ReportSpan.todos;
    customStart = null;
    customEnd = null;
    modality = null;
    _publish();
  }

  void _publish() {
    visibleLimit = pageSize;
    notifyListeners();
  }

  void setFilter(ReportFilter value) {
    filter = value;
    _publish();
  }

  void setSpan(ReportSpan value) {
    span = value;
    if (value == ReportSpan.personalizado) {
      customStart ??= today;
      customEnd ??= today;
      if (dateOnly(customEnd!).isBefore(dateOnly(customStart!))) {
        final start = customStart;
        customStart = customEnd;
        customEnd = start;
      }
    }
    _publish();
  }

  void setCustomStart(DateTime value) {
    customStart = dateOnly(value);
    span = ReportSpan.personalizado;
    setSpan(ReportSpan.personalizado);
  }

  void setCustomEnd(DateTime value) {
    customEnd = dateOnly(value);
    setSpan(ReportSpan.personalizado);
  }

  void setModality(Modality? value) {
    modality = value;
    _publish();
  }

  void setQuery(String value) {
    query = value;
    _publish();
  }

  void setByAppointment(bool value) {
    byAppointment = value;
    _publish();
  }
}

class NextWeekViewModel extends RepositoryViewModel {
  NextWeekViewModel(super.repository);

  List<FollowUp> get followUps => followUpsInNextDays(snapshot.procedures, brasiliaToday());

  Procedure? procedureOf(String followUpId) =>
      procedureOfFollowUp(snapshot.procedures, followUpId);

  Patient patientOf(String patientId) =>
      snapshot.patients.firstWhere((patient) => patient.id == patientId);
}

class TodayRemindersViewModel extends RepositoryViewModel {
  TodayRemindersViewModel(super.repository);

  List<FollowUp> get reminders => schedulingReminders(
        procedures: snapshot.procedures,
        day: brasiliaToday(),
        remindersEnabled: snapshot.profile.reminderEnabled,
      );

  Procedure? procedureOf(String followUpId) =>
      procedureOfFollowUp(snapshot.procedures, followUpId);

  Patient patientOf(String patientId) =>
      snapshot.patients.firstWhere((patient) => patient.id == patientId);
}

class CalendarViewModel extends RepositoryViewModel {
  CalendarViewModel(super.repository) {
    final today = brasiliaToday();
    month = DateTime(today.year, today.month);
    selected = today;
  }

  late DateTime month;
  DateTime? selected;
  ReturnStatus? returnFilter;

  List<CalendarMark> get marks {
    final all = marksInMonth(snapshot.procedures, snapshot.patients, month);
    if (returnFilter == null) return all;
    return all.where((mark) {
      if (mark.kind != CalendarKind.retorno) return true;
      return mark.returnStatus == returnFilter;
    }).toList();
  }

  void previousMonth() {
    month = DateTime(month.year, month.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    month = DateTime(month.year, month.month + 1);
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selected = day;
    notifyListeners();
  }

  void setReturnFilter(ReturnStatus? status) {
    returnFilter = status;
    notifyListeners();
  }
}

class ProcedureViewModel extends RepositoryViewModel {
  ProcedureViewModel(super.repository, {required this.procedureId});

  final String procedureId;

  Procedure get procedure => snapshot.procedures.firstWhere((item) => item.id == procedureId);

  Patient get patient => snapshot.patients.firstWhere((item) => item.id == procedure.patientId);

  void addPhoto(ClinicPhoto photo) => repository.addPhoto(procedureId, photo);

  void addVisit({required String note, required String statusLabel}) {
    repository.addVisit(procedureId: procedureId, note: note, statusLabel: statusLabel);
  }

  void completeFollowUp({
    required String followUpId,
    required String note,
    required String statusLabel,
    required ReturnStatus returnStatus,
  }) {
    repository.completeFollowUp(
      followUpId: followUpId,
      note: note,
      statusLabel: statusLabel,
      returnStatus: returnStatus,
    );
  }

  void saveNotes(String notes) {
    repository.updateProcedure(procedure.copyWith(notes: notes));
  }

  void saveSites(List<ToothSite> sites) {
    repository.updateProcedure(procedure.copyWith(sites: sites));
  }
}

class CertificateViewModel extends RepositoryViewModel {
  CertificateViewModel(super.repository, {required this.procedureId});

  final String procedureId;

  Procedure get procedure => snapshot.procedures.firstWhere((item) => item.id == procedureId);

  Patient get patient => snapshot.patients.firstWhere((item) => item.id == procedure.patientId);

  DentistProfile get profile => snapshot.profile;

  Future<void> issue() async {
    final bytes = await buildCertificatePdf(
      profile: profile,
      patient: patient,
      procedure: procedure,
    );
    final path = await ClinicFiles().saveBytes(
      'certificado-${procedure.id}.pdf',
      bytes,
    );
    repository.issueCertificate(procedureId, pdfPath: path);
    await Printing.sharePdf(bytes: bytes, filename: 'certificado-${procedure.id}.pdf');
  }
}

class ProfileViewModel extends RepositoryViewModel {
  ProfileViewModel(super.repository);

  DentistProfile get profile => snapshot.profile;

  void setCro(String value) => repository.updateProfile(profile.copyWith(cro: value));

  void setReminderEnabled(bool value) =>
      repository.updateProfile(profile.copyWith(reminderEnabled: value));

  void setReminderDaysBefore(int value) => repository.updateProfile(
        profile.copyWith(reminderDaysBefore: normalizeReminderDaysBefore(value)),
      );

  void setEmailChannel(bool value) => repository.updateProfile(profile.copyWith(emailChannel: value));

  void setPushChannel(bool value) => repository.updateProfile(profile.copyWith(pushChannel: value));
}
