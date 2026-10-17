import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../core/layout.dart';
import '../view_models.dart';
import 'patient_editor.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientsViewModel>();
    final patients = viewModel.patients;
    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'patients-new',
        onPressed: () => _create(context, viewModel),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar por nome ou CPF',
              ),
              onChanged: viewModel.setQuery,
            ),
          ),
          Expanded(
            child: patients.isEmpty
                ? Center(
                    child: AppEmptyHint(
                      viewModel.query.trim().isEmpty
                          ? 'Nenhum paciente cadastrado.'
                          : 'Nenhum paciente com esse nome ou CPF.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: patients.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      final count = viewModel.implantCount(patient.id);
                      return AppSurfaceCard(
                        child: ListTile(
                          title: Text(patient.name),
                          subtitle: Text(
                            '${cpfLabel(patient.cpf)}\n${count == 0 ? 'Sem implante registrado' : '$count implante(s)'}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/patients/${patient.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, PatientsViewModel viewModel) async {
    final draft = await editPatientDraft(context, title: 'Novo paciente');
    if (draft == null || !context.mounted) return;
    final patient = viewModel.createPatient(
      name: draft.name,
      phone: draft.phone,
      cpf: draft.cpf,
      birthDate: draft.birthDate,
      notes: draft.notes,
      guardian: draft.guardian,
    );
    if (context.mounted) await context.push('/patients/${patient.id}');
  }
}
