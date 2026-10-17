import 'models.dart';

List<Patient> matchPatients(List<Patient> patients, String query) {
  final text = query.trim().toLowerCase();
  final list = patients.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  if (text.isEmpty) return list;
  final digits = digitsOnly(query);
  return list.where((patient) {
    final nameHit = patient.name.toLowerCase().contains(text);
    final cpfHit = formatCpf(patient.cpf).toLowerCase().contains(text) ||
        (digits.isNotEmpty && digitsOnly(patient.cpf).contains(digits));
    return nameHit || cpfHit;
  }).toList();
}

List<Procedure> proceduresOf(List<Procedure> procedures, String patientId) {
  return procedures.where((item) => item.patientId == patientId).toList()
    ..sort((a, b) => b.surgeryDate.compareTo(a.surgeryDate));
}

List<ToothSite> implantsOf(List<Procedure> procedures, String patientId) {
  return [
    for (final procedure in proceduresOf(procedures, patientId))
      if (procedure.modality != Modality.enxerto)
        for (final site in procedure.pillars) site,
  ];
}

List<FollowUp> upcomingOf(List<Procedure> procedures, String patientId) {
  return [
    for (final procedure in proceduresOf(procedures, patientId))
      for (final followUp in procedure.followUps)
        if (followUp.status == ReturnStatus.agendado) followUp,
  ]..sort((a, b) => a.date.compareTo(b.date));
}

Procedure? procedureOfFollowUp(List<Procedure> procedures, String followUpId) {
  for (final procedure in procedures) {
    if (procedure.followUps.any((item) => item.id == followUpId)) return procedure;
  }
  return null;
}

List<FollowUp> scheduledFollowUps(List<Procedure> procedures) {
  return [
    for (final procedure in procedures)
      for (final followUp in procedure.followUps)
        if (followUp.status == ReturnStatus.agendado) followUp,
  ]..sort((a, b) => a.date.compareTo(b.date));
}

List<CalendarMark> marksInMonth(List<Procedure> procedures, List<Patient> patients, DateTime month) {
  Patient patientById(String id) => patients.firstWhere((patient) => patient.id == id);
  final marks = <CalendarMark>[];
  for (final procedure in procedures) {
    final patient = patientById(procedure.patientId);
    if (procedure.surgeryDate.year == month.year && procedure.surgeryDate.month == month.month) {
      marks.add(
        CalendarMark(
          date: procedure.surgeryDate,
          patientId: patient.id,
          patientName: patient.name,
          kind: CalendarKind.cirurgia,
          label: modalityLabel(procedure.modality),
          procedureId: procedure.id,
        ),
      );
    }
    for (final visit in procedure.visits) {
      if (visit.date.year == month.year && visit.date.month == month.month) {
        marks.add(
          CalendarMark(
            date: visit.date,
            patientId: patient.id,
            patientName: patient.name,
            kind: CalendarKind.consulta,
            label: visit.note,
            procedureId: procedure.id,
          ),
        );
      }
    }
    for (final followUp in procedure.followUps) {
      if (followUp.date.year == month.year && followUp.date.month == month.month) {
        marks.add(
          CalendarMark(
            date: followUp.date,
            patientId: patient.id,
            patientName: patient.name,
            kind: CalendarKind.retorno,
            label: returnReasonLabel(followUp.reason),
            procedureId: procedure.id,
            returnStatus: followUp.status,
            overdue: followUp.status == ReturnStatus.agendado &&
                dateOnly(followUp.date).isBefore(dateOnly(DateTime.now())),
          ),
        );
      }
    }
  }
  marks.sort((a, b) {
    final byDay = a.date.compareTo(b.date);
    if (byDay != 0) return byDay;
    return a.patientName.compareTo(b.patientName);
  });
  return marks;
}
