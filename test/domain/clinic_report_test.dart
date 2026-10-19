import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/models.dart';
import 'package:implate_flow/domain/queries.dart';

void main() {
  final today = DateTime(2026, 10, 19);
  final ana = Patient(id: 'ana', name: 'Ana Costa', phone: '', birthDate: DateTime(1984, 1, 28));
  final bruno = Patient(id: 'bruno', name: 'Bruno Dias', phone: '', birthDate: DateTime(1970, 2, 2));

  Procedure procedure({
    required String id,
    required String patientId,
    required List<FollowUp> followUps,
    Modality modality = Modality.implante,
  }) {
    return Procedure(
      id: id,
      patientId: patientId,
      modality: modality,
      surgeryDate: DateTime(2026, 9, 1),
      statusLabel: 'Instalado',
      sites: const [ToothSite(fdi: 11, role: ToothRole.pilar)],
      followUps: followUps,
    );
  }

  FollowUp followUp({
    required String id,
    required DateTime date,
    required ReturnStatus status,
    ReturnReason reason = ReturnReason.controle,
  }) {
    return FollowUp(
      id: id,
      date: date,
      reason: reason,
      status: status,
      reminderEnabled: false,
    );
  }

  test('atraso continua agendado e falta só entra quando marcada', () {
    final procedures = [
      procedure(
        id: 'pro-ana',
        patientId: ana.id,
        followUps: [
          followUp(id: 'vencido', date: DateTime(2026, 10, 18), status: ReturnStatus.agendado),
          followUp(id: 'falta', date: DateTime(2026, 10, 1), status: ReturnStatus.faltou),
        ],
      ),
    ];

    expect(patientsForReport(procedures, [ana], ReportFilter.atrasados, today).single.id, ana.id);
    expect(patientsForReport(procedures, [ana], ReportFilter.faltas, today).single.id, ana.id);
    expect(
      reportFollowUps(procedures, ana.id, ReportFilter.atrasados, today).single.followUp.status,
      ReturnStatus.agendado,
    );
    expect(patientsForReport(procedures, [ana], ReportFilter.emDia, today), isEmpty);
  });

  test('em dia ignora falta registrada e paciente sem pendência vencida', () {
    final procedures = [
      procedure(
        id: 'pro-bruno',
        patientId: bruno.id,
        followUps: [
          followUp(id: 'falta', date: DateTime(2026, 9, 1), status: ReturnStatus.faltou),
          followUp(id: 'futuro', date: DateTime(2026, 10, 25), status: ReturnStatus.agendado),
        ],
      ),
    ];

    expect(patientsForReport(procedures, [ana, bruno], ReportFilter.emDia, today).map((item) => item.id), [
      ana.id,
      bruno.id,
    ]);
  });

  test('comparecimento usa só desfecho e não conta o mesmo compromisso duas vezes', () {
    final shared = followUp(id: 'mesmo', date: DateTime(2026, 10, 2), status: ReturnStatus.realizado);
    final procedures = [
      procedure(id: 'pro-1', patientId: ana.id, followUps: [shared]),
      procedure(id: 'pro-2', patientId: ana.id, followUps: [shared]),
      procedure(
        id: 'pro-3',
        patientId: bruno.id,
        followUps: [
          followUp(id: 'falta', date: DateTime(2026, 10, 3), status: ReturnStatus.faltou),
          followUp(id: 'aberto', date: DateTime(2026, 10, 30), status: ReturnStatus.agendado),
        ],
      ),
    ];

    final report = clinicReport(procedures: procedures, patients: [ana, bruno], today: today);

    expect(report.attended, 1);
    expect(report.missed, 1);
    expect(report.pending, 1);
    expect(report.withOutcome, 2);
    expect(report.attendancePercent, 50);
    expect(report.absences, 1);
  });

  test('período, modalidade, nome e fuso de Brasília recortam a lista', () {
    final procedures = [
      procedure(
        id: 'pro-ana',
        patientId: ana.id,
        followUps: [
          followUp(id: 'hoje', date: DateTime(2026, 10, 19), status: ReturnStatus.agendado),
          followUp(id: 'oito', date: DateTime(2026, 10, 27), status: ReturnStatus.agendado),
        ],
      ),
      procedure(
        id: 'pro-bruno',
        patientId: bruno.id,
        modality: Modality.protese,
        followUps: [
          followUp(id: 'ponte', date: DateTime(2026, 10, 20), status: ReturnStatus.agendado),
        ],
      ),
    ];
    final week = ReportWindow.span(today, ReportSpan.seteDias);

    expect(
      reportFollowUps(procedures, ana.id, ReportFilter.proximos, today, window: week).map((row) => row.followUp.id),
      ['hoje'],
    );
    expect(
      patientsForReport(
        procedures,
        [ana, bruno],
        ReportFilter.proximos,
        today,
        modality: Modality.protese,
      ).single.id,
      bruno.id,
    );
    expect(
      patientsForReport(procedures, [ana, bruno], ReportFilter.proximos, today, query: 'ana').single.id,
      ana.id,
    );

    final beforeMidnight = brasiliaToday(DateTime.utc(2026, 10, 19, 2, 30));
    final afterMidnight = brasiliaToday(DateTime.utc(2026, 10, 19, 3));
    final dueYesterday = [
      procedure(
        id: 'pro-ana',
        patientId: ana.id,
        followUps: [
          followUp(id: 'limite', date: DateTime(2026, 10, 18), status: ReturnStatus.agendado),
        ],
      ),
    ];
    expect(patientsForReport(dueYesterday, [ana], ReportFilter.atrasados, beforeMidnight), isEmpty);
    expect(patientsForReport(dueYesterday, [ana], ReportFilter.atrasados, afterMidnight), hasLength(1));
  });

  test('o relatório de um consultório não inclui pacientes de outro', () {
    final clinicA = clinicReport(
      procedures: [
        procedure(
          id: 'pro-ana',
          patientId: ana.id,
          followUps: [
            followUp(id: 'a', date: DateTime(2026, 10, 1), status: ReturnStatus.faltou),
          ],
        ),
      ],
      patients: [ana],
      today: today,
    );
    final clinicB = patientsForReport(
      [
        procedure(
          id: 'pro-bruno',
          patientId: bruno.id,
          followUps: [
            followUp(id: 'b', date: DateTime(2026, 10, 1), status: ReturnStatus.faltou),
          ],
        ),
      ],
      [bruno],
      ReportFilter.faltas,
      today,
    );

    expect(clinicA.absences, 1);
    expect(clinicB.single.id, bruno.id);
    expect(clinicB.any((patient) => patient.id == ana.id), isFalse);
  });
}
