import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../domain/queries.dart';
import '../core/layout.dart';
import '../view_models.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReportsViewModel>();
    final patients = viewModel.patients;
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in ReportFilter.values)
                ChoiceChip(
                  label: Text(reportFilterLabel(filter)),
                  selected: viewModel.filter == filter,
                  onSelected: (_) => viewModel.setFilter(filter),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (patients.isEmpty)
            AppEmptyHint(_emptyLabel(viewModel.filter))
          else
            for (final patient in patients) ...[
              _PatientReportCard(viewModel: viewModel, patient: patient),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  String _emptyLabel(ReportFilter filter) => switch (filter) {
        ReportFilter.atrasados => 'Nenhum paciente em atraso.',
        ReportFilter.faltas => 'Nenhum paciente com falta.',
        ReportFilter.proximos => 'Nenhum retorno próximo.',
        ReportFilter.realizados => 'Nenhuma consulta realizada.',
      };
}

class _PatientReportCard extends StatelessWidget {
  const _PatientReportCard({required this.viewModel, required this.patient});

  final ReportsViewModel viewModel;
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final rows = viewModel.rowsFor(patient.id);
    return AppSurfaceCard(
      child: Column(
        children: [
          ListTile(
            title: Text(patient.name),
            subtitle: Text('${rows.length} ${rows.length == 1 ? 'compromisso' : 'compromissos'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/patients/${patient.id}'),
          ),
          for (final row in rows)
            ListTile(
              dense: true,
              title: Text('${formatDay(row.followUp.date)} · ${returnReasonLabel(row.followUp.reason)}'),
              subtitle: Text(row.procedure.teethLabel),
              onTap: () => context.push('/procedures/${row.procedure.id}'),
            ),
        ],
      ),
    );
  }
}
