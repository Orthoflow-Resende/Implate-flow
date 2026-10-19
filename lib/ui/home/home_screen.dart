import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../core/layout.dart';
import '../patients/patient_editor.dart';
import '../view_models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home-new-procedure',
        onPressed: () => _startProcedure(context, viewModel),
        icon: const Icon(Icons.add),
        label: const Text('Procedimento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CountCard(
                    label: 'Atraso',
                    count: viewModel.overduePatientCount,
                    onTap: () => context.push('/reports?filtro=atrasados'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountCard(
                    label: 'Lembretes',
                    count: viewModel.todayReminderCount,
                    onTap: () => context.push('/reminders'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountCard(
                    label: 'Próximos 7 dias',
                    count: viewModel.nextWeekCount,
                    onTap: () => context.push('/week'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _AgendaSection(
            title: 'Hoje',
            empty: 'Nenhum retorno hoje.',
            items: viewModel.today,
            viewModel: viewModel,
          ),
        ],
      ),
    );
  }

  Future<void> _startProcedure(BuildContext context, HomeViewModel viewModel) async {
    final selected = await showModalBottomSheet<Patient>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => _PatientPicker(viewModel: viewModel),
    );
    if (selected == null || !context.mounted) return;
    await context.push('/patients/${selected.id}/new');
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.count, required this.onTap});

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: '$label, $count',
      child: AppSurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        child: Column(
          children: [
            Text(
              '$count',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaSection extends StatelessWidget {
  const _AgendaSection({
    required this.title,
    required this.empty,
    required this.items,
    required this.viewModel,
  });

  final String title;
  final String empty;
  final List<FollowUp> items;
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: 8),
          if (items.isEmpty)
            AppEmptyHint(empty)
          else
            for (final followUp in items) ...[
              _ReturnTile(viewModel: viewModel, followUp: followUp),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _PatientPicker extends StatefulWidget {
  const _PatientPicker({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<_PatientPicker> createState() => _PatientPickerState();
}

class _PatientPickerState extends State<_PatientPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.viewModel.patientsMatching(query);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AppSectionHeader(
                title: 'Paciente do procedimento',
                subtitle: 'Escolha na lista ou cadastre um novo.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: FilledButton.icon(
                onPressed: () => _createPatient(context),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Novo paciente'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar por nome ou CPF',
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: AppEmptyHint(
                        query.trim().isEmpty
                            ? 'Nenhum paciente cadastrado.'
                            : 'Nenhum paciente com esse nome ou CPF.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: matches.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final patient = matches[index];
                        return AppSurfaceCard(
                          child: ListTile(
                            title: Text(patient.name),
                            subtitle: Text(cpfLabel(patient.cpf)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, patient),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPatient(BuildContext context) async {
    final draft = await editPatientDraft(context, title: 'Novo paciente');
    if (draft == null || !context.mounted) return;
    final patient = widget.viewModel.repository.createPatient(
      name: draft.name,
      phone: draft.phone,
      cpf: draft.cpf,
      birthDate: draft.birthDate,
      notes: draft.notes,
      guardian: draft.guardian,
    );
    if (context.mounted) Navigator.pop(context, patient);
  }
}

class _ReturnTile extends StatelessWidget {
  const _ReturnTile({required this.viewModel, required this.followUp});

  final HomeViewModel viewModel;
  final FollowUp followUp;

  @override
  Widget build(BuildContext context) {
    final procedure = viewModel.procedureOf(followUp.id);
    if (procedure == null) return const SizedBox.shrink();
    final patient = viewModel.patientOf(procedure.patientId);
    return AppSurfaceCard(
      child: ListTile(
        title: Text(patient.name),
        subtitle: Text(
          '${formatDay(followUp.date)} · ${returnReasonLabel(followUp.reason)} · ${procedure.teethLabel}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/procedures/${procedure.id}'),
      ),
    );
  }
}
