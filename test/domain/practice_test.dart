import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/models.dart';
import 'package:implate_flow/domain/practice.dart';

void main() {
  test('há um único padrão e inativar o padrão pede substituto', () {
    final first = const CareLocation(id: 'a', name: 'Centro');
    final added = addCareLocation(const [], first);
    expect(added.single.isDefault, isTrue);
    final second = addCareLocation(added, const CareLocation(id: 'b', name: 'Sul'));
    expect(second.where((location) => location.isDefault), hasLength(1));
    expect(needsDefaultReplacement(second, 'a'), isTrue);
    final inactive = inactivateCareLocation(second, 'a', replacementId: 'b');
    expect(careLocationIssue(inactive), isNull);
    expect(inactive.firstWhere((location) => location.id == 'a').active, isFalse);
    expect(inactive.firstWhere((location) => location.id == 'b').isDefault, isTrue);
    expect(inactive.firstWhere((location) => location.id == 'a').name, 'Centro');
  });

  test('aviso de etapa só sai em mudança clínica com canal válido', () {
    final patient = Patient(
      id: 'pac',
      name: 'Maria',
      phone: '(11) 98888-1001',
      email: 'maria@exemplo.com',
      birthDate: DateTime(1980, 1, 1),
      notifyByEmail: true,
      notifyByPhone: true,
    );
    final plan = stageNoticePlan(
      previousStatus: 'Instalado',
      nextStatus: 'Em osseointegração',
      clinicalChange: true,
      patient: patient,
    );
    expect(plan?.channels, ['e-mail', 'telefone']);
    expect(
      stageNoticePlan(
        previousStatus: 'Instalado',
        nextStatus: 'Instalado',
        clinicalChange: true,
        patient: patient,
      ),
      isNull,
    );
    expect(
      stageNoticePlan(
        previousStatus: 'Instalado',
        nextStatus: 'Reabertura',
        clinicalChange: false,
        patient: patient,
      ),
      isNull,
    );

    final revoked = normalizePatientContacts(patient.copyWith(notifyByEmail: false, phone: '123'));
    expect(revoked.notifyByPhone, isFalse);
    final pending = [
      StageNotice(
        id: 'avi-1',
        stageLabel: 'Reabertura',
        channels: const ['e-mail', 'telefone'],
        delivery: NoticeDelivery.aguardando,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
    final after = revokePendingNotices(pending, revoked);
    expect(after.single.delivery, NoticeDelivery.revogada);

    final failed = pending.single.copyWith(delivery: NoticeDelivery.falha);
    final again = reprocessNotice([failed], 'avi-1').single;
    expect(again.delivery, NoticeDelivery.aguardando);
    expect(stageNoticeStatusLabel(again), contains('Aguardando confirmação'));
    expect(stageNoticeStatusLabel(again), isNot(contains('Enviado')));
  });

  test('filtro de local não duplica paciente e isola o consultório', () {
    final patients = [
      Patient(
        id: '1',
        name: 'Maria',
        phone: '',
        birthDate: DateTime(1980),
        locationIds: const ['centro', 'sul'],
      ),
      Patient(id: '2', name: 'Pedro', phone: '', birthDate: DateTime(2014)),
    ];
    expect(filterPatientsByLocation(patients, const LocationFilter.place('centro')), hasLength(1));
    expect(filterPatientsByLocation(patients, const LocationFilter.place('sul')), hasLength(1));
    expect(filterPatientsByLocation(patients, const LocationFilter.none()).single.name, 'Pedro');
    final dentist = [
      const CareLocation(id: 'centro', name: 'Centro', isDefault: true),
    ];
    expect(activeCareLocations(dentist).map((location) => location.id), ['centro']);
  });
}
