import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/models.dart';
import 'package:implate_flow/domain/queries.dart';

void main() {
  final today = DateTime(2026, 10, 18);
  final ana = Patient(id: 'ana', name: 'Ana Costa', phone: '', birthDate: DateTime(1984, 1, 28));
  final bruno = Patient(id: 'bruno', name: 'Bruno Dias', phone: '', birthDate: DateTime(1970, 2, 2));

  Procedure procedure({
    required String id,
    required String patientId,
    required List<FollowUp> followUps,
  }) {
    return Procedure(
      id: id,
      patientId: patientId,
      modality: Modality.implante,
      surgeryDate: DateTime(2026, 9, 1),
      statusLabel: 'Instalado',
      sites: const [ToothSite(fdi: 36, role: ToothRole.pilar)],
      followUps: followUps,
    );
  }

  FollowUp followUp({
    required String id,
    required DateTime date,
    required ReturnStatus status,
    bool reminderEnabled = false,
    int reminderDaysBefore = 15,
    ReturnReason reason = ReturnReason.osseointegracao,
  }) {
    return FollowUp(
      id: id,
      date: date,
      reason: reason,
      status: status,
      reminderEnabled: reminderEnabled,
      reminderDaysBefore: reminderDaysBefore,
    );
  }

  test('atraso conta pacientes distintos, não compromissos', () {
    final procedures = [
      procedure(
        id: 'pro-ana',
        patientId: ana.id,
        followUps: [
          followUp(id: 'ret-1', date: DateTime(2026, 10, 17), status: ReturnStatus.agendado),
          followUp(id: 'ret-2', date: DateTime(2026, 10, 10), status: ReturnStatus.agendado),
        ],
      ),
      procedure(
        id: 'pro-bruno',
        patientId: bruno.id,
        followUps: [
          followUp(id: 'ret-3', date: DateTime(2026, 10, 18), status: ReturnStatus.agendado),
        ],
      ),
    ];

    final patients = patientsForReport(procedures, [ana, bruno], ReportFilter.atrasados, today);

    expect(patients.map((patient) => patient.id), ['ana']);
    expect(reportFollowUps(procedures, 'ana', ReportFilter.atrasados, today), hasLength(2));
  });

  test('lembrete do dia não duplica o mesmo compromisso e respeita o perfil', () {
    final due = followUp(
      id: 'ret-1',
      date: DateTime(2026, 11, 2),
      status: ReturnStatus.agendado,
      reminderEnabled: true,
    );
    final procedures = [
      procedure(id: 'pro-1', patientId: ana.id, followUps: [due]),
      procedure(id: 'pro-2', patientId: ana.id, followUps: [due]),
    ];

    final reminders = schedulingReminders(
      procedures: procedures,
      day: today,
      remindersEnabled: true,
    );
    expect(reminders, hasLength(1));
    expect(
      schedulingReminders(procedures: procedures, day: today, remindersEnabled: false),
      isEmpty,
    );
  });

  test('virada do dia segue America/Sao_Paulo', () {
    expect(brasiliaToday(DateTime.utc(2026, 10, 19, 2, 30)), DateTime(2026, 10, 18));
    expect(brasiliaToday(DateTime.utc(2026, 10, 19, 3)), DateTime(2026, 10, 19));

    final procedures = [
      procedure(
        id: 'pro-ana',
        patientId: ana.id,
        followUps: [
          followUp(id: 'ret-1', date: DateTime(2026, 10, 18), status: ReturnStatus.agendado),
        ],
      ),
    ];
    expect(
      patientsForReport(procedures, [ana], ReportFilter.atrasados, brasiliaToday(DateTime.utc(2026, 10, 19, 2, 30))),
      isEmpty,
    );
    expect(
      patientsForReport(procedures, [ana], ReportFilter.atrasados, brasiliaToday(DateTime.utc(2026, 10, 19, 3))),
      hasLength(1),
    );
  });
}
