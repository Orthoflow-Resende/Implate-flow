import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../domain/practice.dart';
import '../core/filter_menu.dart';
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
      appBar: AppBar(
        title: const Text('Pacientes'),
        actions: [
          FilterMenuButton(
            groups: _locationGroups(viewModel),
            activeCount: viewModel.locationFilter.isAll ? 0 : 1,
            onClear: () => viewModel.setLocationFilter(const LocationFilter.all()),
          ),
        ],
      ),
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
                      viewModel.query.trim().isEmpty && viewModel.locationFilter.isAll
                          ? 'Nenhum paciente cadastrado.'
                          : 'Nenhum paciente com esses filtros.',
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
    final draft = await editPatientDraft(
      context,
      title: 'Novo paciente',
      locations: viewModel.snapshot.profile.locations,
    );
    if (draft == null || !context.mounted) return;
    final patient = viewModel.createPatient(
      name: draft.name,
      phone: draft.phone,
      email: draft.email,
      cpf: draft.cpf,
      birthDate: draft.birthDate,
      notes: draft.notes,
      guardian: draft.guardian,
      locationIds: draft.locationIds,
      notifyByEmail: draft.notifyByEmail,
      notifyByPhone: draft.notifyByPhone,
    );
    if (context.mounted) await context.push('/patients/${patient.id}');
  }
}

List<FilterMenuGroup> _locationGroups(PatientsViewModel viewModel) {
  final selected = viewModel.locationFilter;
  return [
    FilterMenuGroup(
      title: 'Local de atendimento',
      options: [
        FilterMenuOption(
          label: 'Todos os locais',
          selected: selected.isAll,
          onSelected: () => viewModel.setLocationFilter(const LocationFilter.all()),
        ),
        for (final location in activeCareLocations(viewModel.snapshot.profile.locations))
          FilterMenuOption(
            label: location.name,
            selected: selected.locationId == location.id,
            onSelected: () => viewModel.setLocationFilter(LocationFilter.place(location.id)),
          ),
        FilterMenuOption(
          label: 'Sem local',
          selected: selected.withoutLocation,
          onSelected: () => viewModel.setLocationFilter(const LocationFilter.none()),
        ),
      ],
    ),
  ];
}
