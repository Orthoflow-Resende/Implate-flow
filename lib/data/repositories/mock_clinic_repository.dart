import 'dart:async';

import '../../domain/clinic_snapshot.dart';
import '../../domain/models.dart';
import '../services/mock_clinic_service.dart';
import 'clinic_repository.dart';

class MockClinicRepository implements ClinicRepository {
  MockClinicRepository(
    MockClinicService service, {
    Future<void> Function(ClinicSnapshot snapshot)? persist,
  }) : this.fromSnapshot(service.load(), persist: persist);

  MockClinicRepository.fromSnapshot(
    this._snapshot, {
    this._persist,
  });

  ClinicSnapshot _snapshot;
  final Future<void> Function(ClinicSnapshot snapshot)? _persist;
  final _updates = StreamController<ClinicSnapshot>.broadcast();
  final List<String> _delayNoticeFollowUpIds = [];

  @override
  ClinicSnapshot get current => _snapshot;

  @override
  List<String> get delayNoticeFollowUpIds =>
      List.unmodifiable(_delayNoticeFollowUpIds);

  @override
  Stream<ClinicSnapshot> watch() async* {
    yield _snapshot;
    yield* _updates.stream;
  }

  void _emit(ClinicSnapshot next) {
    _snapshot = next;
    _updates.add(next);
    _persist?.call(next);
  }

  @override
  void applyOverdueNotices() {
    _delayNoticeFollowUpIds.clear();
    final today = dateOnly(DateTime.now());
    var changed = false;
    final procedures = <Procedure>[];
    for (final procedure in _snapshot.procedures) {
      final followUps = <FollowUp>[];
      for (final followUp in procedure.followUps) {
        final shouldNotify = followUp.status == ReturnStatus.agendado &&
            dateOnly(followUp.date).isBefore(today) &&
            !followUp.overdueNotified;
        if (shouldNotify) {
          changed = true;
          _delayNoticeFollowUpIds.add(followUp.id);
          followUps.add(followUp.copyWith(overdueNotified: true));
        } else {
          followUps.add(followUp);
        }
      }
      procedures.add(procedure.copyWith(followUps: followUps));
    }
    if (changed) {
      _emit(_snapshot.copyWith(procedures: procedures));
    }
  }

  @override
  void signIn({required String name, required String email}) {
    _emit(
      _snapshot.copyWith(
        signedIn: true,
        profile: _snapshot.profile.copyWith(name: name, email: email),
      ),
    );
  }

  @override
  void signOut() {
    _emit(_snapshot.copyWith(signedIn: false));
  }

  @override
  String allocateId(String prefix) {
    final next = _snapshot.sequence + 1;
    _snapshot = _snapshot.copyWith(sequence: next);
    return '$prefix-$next';
  }

  @override
  Patient createPatient({
    required String name,
    required String phone,
    String cpf = '',
    required DateTime birthDate,
    String notes = '',
    String guardian = '',
  }) {
    final patient = Patient(
      id: allocateId('pac'),
      name: name.trim(),
      phone: phone.trim(),
      cpf: formatCpf(cpf),
      birthDate: birthDate,
      notes: notes.trim(),
      guardian: guardian.trim(),
    );
    _emit(_snapshot.copyWith(patients: [..._snapshot.patients, patient]));
    return patient;
  }

  @override
  void updatePatient(Patient patient) {
    _emit(
      _snapshot.copyWith(
        patients: [
          for (final item in _snapshot.patients)
            if (item.id == patient.id) patient else item,
        ],
      ),
    );
  }

  @override
  void saveProcedures(List<Procedure> created) {
    _emit(_snapshot.copyWith(procedures: [..._snapshot.procedures, ...created]));
  }

  @override
  void updateProcedure(Procedure procedure) {
    _replace(procedure.id, (_) => procedure);
  }

  @override
  void addPhoto(String procedureId, ClinicPhoto photo) {
    _replace(procedureId, (procedure) {
      return procedure.copyWith(photos: [...procedure.photos, photo]);
    });
  }

  @override
  void addVisit({
    required String procedureId,
    required String note,
    required String statusLabel,
  }) {
    _replace(procedureId, (procedure) {
      return procedure.copyWith(
        statusLabel: statusLabel,
        visits: [
          ...procedure.visits,
          Visit(
            id: allocateId('con'),
            date: DateTime.now(),
            note: note.trim().isEmpty ? 'Consulta' : note.trim(),
            statusLabel: statusLabel,
          ),
        ],
      );
    });
  }

  @override
  void completeFollowUp({
    required String followUpId,
    required String note,
    required String statusLabel,
    required ReturnStatus returnStatus,
  }) {
    final procedure = _procedureOfFollowUp(followUpId);
    if (procedure == null) return;
    final followUp = procedure.followUps.where((item) => item.id == followUpId).first;
    final visits = [...procedure.visits];
    if (returnStatus == ReturnStatus.realizado) {
      visits.add(
        Visit(
          id: allocateId('con'),
          date: DateTime.now(),
          note: note.trim().isEmpty ? returnReasonLabel(followUp.reason) : note.trim(),
          statusLabel: statusLabel,
        ),
      );
    }
    _replace(procedure.id, (current) {
      return current.copyWith(
        statusLabel: returnStatus == ReturnStatus.realizado ? statusLabel : current.statusLabel,
        followUps: [
          for (final item in current.followUps)
            if (item.id == followUpId) item.copyWith(status: returnStatus) else item,
        ],
        visits: visits,
      );
    });
  }

  @override
  void issueCertificate(String procedureId, {String? pdfPath}) {
    _replace(procedureId, (procedure) {
      return procedure.copyWith(
        certificateIssuedAt: DateTime.now(),
        certificatePdfPath: pdfPath,
      );
    });
  }

  @override
  void updateProfile(DentistProfile profile) {
    _emit(_snapshot.copyWith(profile: profile));
  }

  void _replace(String procedureId, Procedure Function(Procedure procedure) update) {
    _emit(
      _snapshot.copyWith(
        procedures: [
          for (final procedure in _snapshot.procedures)
            if (procedure.id == procedureId) update(procedure) else procedure,
        ],
      ),
    );
  }

  Procedure? _procedureOfFollowUp(String followUpId) {
    for (final procedure in _snapshot.procedures) {
      if (procedure.followUps.any((item) => item.id == followUpId)) return procedure;
    }
    return null;
  }
}
