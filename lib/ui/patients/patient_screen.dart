import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../core/layout.dart';
import '../view_models.dart';
import 'patient_editor.dart';

class PatientScreen extends StatelessWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientViewModel>();
    final patient = viewModel.patient;
    final upcoming = viewModel.upcoming;
    final history = viewModel.history;
    final timeline = viewModel.timeline;
    final implants = [
      for (final procedure in history)
        if (procedure.modality != Modality.enxerto)
          for (final site in procedure.pillars) (procedure: procedure, site: site),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: () => _edit(context, viewModel),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Exportar prontuário',
            onPressed: () async {
              await viewModel.exportChart();
            },
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'patient-new-procedure',
        onPressed: () => context.push('/patients/${patient.id}/new'),
        icon: const Icon(Icons.add),
        label: const Text('Procedimento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(patient.phone.isEmpty ? 'Sem telefone' : patient.phone),
                Text(cpfLabel(patient.cpf)),
                Text('Nascimento ${formatDay(patient.birthDate)}'),
                if (patient.isMinor && patient.guardian.isNotEmpty)
                  Text('Responsável: ${patient.guardian}'),
                if (patient.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(patient.notes),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Resumo dos implantes'),
          const SizedBox(height: 8),
          if (implants.isEmpty)
            const AppEmptyHint('Nenhum pilar registrado.')
          else
            for (final item in implants) ...[
              AppSurfaceCard(
                child: ListTile(
                  title: Text('Dente ${item.site.fdi}'),
                  subtitle: Text(
                    '${modalityLabel(item.procedure.modality)} · ${item.site.piece?.manufacturer ?? 'Sem fabricante'} ${item.site.piece?.model ?? ''}\n${item.procedure.statusLabel}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/procedures/${item.procedure.id}'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Próximos encontros'),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            const AppEmptyHint('Nenhum retorno agendado.')
          else
            for (final followUp in upcoming) ...[
              AppSurfaceCard(
                child: ListTile(
                  title: Text(formatDay(followUp.date)),
                  subtitle: Text(
                    '${returnReasonLabel(followUp.reason)} · lembrete ${followUp.reminderEnabled ? '${followUp.reminderHour}h' : 'desligado'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final procedure = viewModel.procedureOf(followUp.id);
                    if (procedure == null) return;
                    context.push('/procedures/${procedure.id}');
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Histórico'),
          const SizedBox(height: 8),
          if (timeline.isEmpty)
            const AppEmptyHint('Nenhuma cirurgia ou consulta.')
          else
            for (final event in timeline) ...[
              AppSurfaceCard(
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text('${formatDay(event.date)} · ${event.detail}'),
                  trailing: event.procedureId == null ? null : const Icon(Icons.chevron_right),
                  onTap: event.procedureId == null
                      ? null
                      : () => context.push('/procedures/${event.procedureId}'),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, PatientViewModel viewModel) async {
    final patient = viewModel.patient;
    final draft = await editPatientDraft(
      context,
      title: 'Editar paciente',
      initial: PatientDraft(
        name: patient.name,
        phone: patient.phone,
        cpf: patient.cpf,
        birthDate: patient.birthDate,
        notes: patient.notes,
        guardian: patient.guardian,
      ),
    );
    if (draft == null) return;
    viewModel.updatePatient(
      patient.copyWith(
        name: draft.name.trim(),
        phone: draft.phone.trim(),
        cpf: draft.cpf,
        birthDate: draft.birthDate,
        notes: draft.notes.trim(),
        guardian: draft.guardian.trim(),
      ),
    );
  }
}
