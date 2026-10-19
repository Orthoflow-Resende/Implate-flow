import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/models.dart';
import '../../domain/queries.dart';

Future<Uint8List> buildCertificatePdf({
  required DentistProfile profile,
  required Patient patient,
  required Procedure procedure,
}) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text('Certificado de procedência', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text(profile.name),
        pw.Text(profile.cro),
        pw.SizedBox(height: 12),
        pw.Text(patient.name),
        pw.Text('Nascimento ${formatDay(patient.birthDate)}'),
        if (patient.isMinor && patient.guardian.isNotEmpty)
          pw.Text('Responsável legal: ${patient.guardian}'),
        pw.SizedBox(height: 12),
        pw.Text(modalityLabel(procedure.modality)),
        pw.Text(formatDay(procedure.surgeryDate)),
        pw.Text(procedure.teethLabel),
        for (final site in procedure.pillars) ...[
          pw.SizedBox(height: 10),
          pw.Text('Dente ${site.fdi}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (site.piece != null) ...[
            pw.Text('${site.piece!.manufacturer} ${site.piece!.model}'),
            pw.Text(site.piece!.size),
            pw.Text(
              'Fabricação ${site.piece!.manufacturedOn == null ? '—' : formatDay(site.piece!.manufacturedOn!)}',
            ),
            pw.Text(
              'Validade ${site.piece!.expiresOn == null ? '—' : formatDay(site.piece!.expiresOn!)}',
            ),
          ],
          for (final graft in site.grafts)
            pw.Text(
              graft.origin == GraftOrigin.autogeno
                  ? 'Enxerto autógeno · região doadora ${graft.donorSite}'
                  : 'Enxerto ${graft.manufacturer} ${graft.model}'
                      '${graft.size.isEmpty ? '' : ' · ${graft.size}'}'
                      '${graft.manufacturedOn == null ? '' : ' · fabricação ${formatDay(graft.manufacturedOn!)}'}'
                      '${graft.expiresOn == null ? '' : ' · validade ${formatDay(graft.expiresOn!)}'}',
            ),
        ],
      ],
    ),
  );
  return document.save();
}

Future<Uint8List> buildPatientChartPdf({
  required DentistProfile profile,
  required Patient patient,
  required List<Procedure> history,
}) async {
  final implants = implantsOf(history, patient.id);
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text('Prontuário', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text(profile.name),
        pw.Text(profile.cro),
        pw.SizedBox(height: 12),
        pw.Text(patient.name),
        pw.Text(cpfLabel(patient.cpf)),
        pw.Text(patient.phone.isEmpty ? 'Sem telefone' : patient.phone),
        pw.Text('Nascimento ${formatDay(patient.birthDate)}'),
        if (patient.isMinor && patient.guardian.isNotEmpty)
          pw.Text('Responsável legal: ${patient.guardian}'),
        if (patient.notes.isNotEmpty) pw.Text('Observação: ${patient.notes}'),
        pw.SizedBox(height: 16),
        pw.Text('Implantes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        if (implants.isEmpty) pw.Text('Nenhum pilar registrado.'),
        for (final site in implants)
          pw.Text(
            'Dente ${site.fdi} · ${site.piece?.manufacturer ?? 'Sem fabricante'} ${site.piece?.model ?? ''}',
          ),
        pw.SizedBox(height: 16),
        pw.Text('Histórico', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        for (final procedure in history) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            '${formatDay(procedure.surgeryDate)} · ${modalityLabel(procedure.modality)} · ${procedure.teethLabel}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(procedure.statusLabel),
          if (procedure.notes.isNotEmpty) pw.Text(procedure.notes),
          for (final visit in procedure.visits)
            pw.Text('${formatDay(visit.date)} · Consulta · ${visit.note}'),
          if (procedure.certificateIssuedAt != null)
            pw.Text('Certificado emitido em ${formatDay(procedure.certificateIssuedAt!)}'),
        ],
      ],
    ),
  );
  return document.save();
}
