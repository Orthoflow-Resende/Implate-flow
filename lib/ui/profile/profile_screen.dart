import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../domain/practice.dart';
import '../core/brazilian_phone_field.dart';
import '../core/layout.dart';
import '../view_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final session = context.watch<SessionViewModel>();
    final profile = viewModel.profile;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                BrazilianPhoneField(initial: profile.phone, onChanged: viewModel.setPhone),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: profile.cro,
                  decoration: const InputDecoration(labelText: 'CRO/UF'),
                  onChanged: viewModel.setCro,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(
            title: 'Locais de atendimento',
            subtitle: 'O local padrão só é uma sugestão no cadastro de pacientes.',
          ),
          const SizedBox(height: 8),
          if (profile.locations.isEmpty)
            const AppEmptyHint('Nenhum local cadastrado.')
          else
            for (final location in profile.locations) ...[
              AppSurfaceCard(
                child: ListTile(
                  title: Text(location.name),
                  subtitle: Text(
                    [
                      if (location.address.isNotEmpty) location.address,
                      if (!location.active) 'Inativo',
                      if (location.isDefault) 'Padrão',
                    ].join(' · '),
                  ),
                  isThreeLine: location.address.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => _locationAction(context, viewModel, location, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                      if (location.active && !location.isDefault)
                        const PopupMenuItem(value: 'padrao', child: Text('Definir como padrão')),
                      if (location.active)
                        const PopupMenuItem(value: 'inativar', child: Text('Inativar')),
                      if (!location.active)
                        const PopupMenuItem(value: 'reativar', child: Text('Reativar')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _editLocation(context, viewModel),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar local'),
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(
            title: 'Lembrete do retorno',
            subtitle: 'O aviso sai antes da data de retorno. O padrão é 15 dias.',
          ),
          const SizedBox(height: 8),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Lembrar antes do retorno'),
                  value: profile.reminderEnabled,
                  onChanged: viewModel.setReminderEnabled,
                ),
                if (profile.reminderEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        for (final days in reminderLeadDayOptions) ...[
                          if (days != reminderLeadDayOptions.first) const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  reminderLeadChipLabel(days),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              selected: profile.reminderDaysBefore == days,
                              onSelected: (_) => viewModel.setReminderDaysBefore(days),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                SwitchListTile(
                  title: const Text('E-mail'),
                  value: profile.emailChannel,
                  onChanged: viewModel.setEmailChannel,
                ),
                SwitchListTile(
                  title: const Text('Push'),
                  value: profile.pushChannel,
                  onChanged: viewModel.setPushChannel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: session.busy ? null : session.signOut,
            icon: session.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Sair'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _locationAction(
  BuildContext context,
  ProfileViewModel viewModel,
  CareLocation location,
  String action,
) async {
  switch (action) {
    case 'editar':
      await _editLocation(context, viewModel, location: location);
    case 'padrao':
      viewModel.makeDefaultLocation(location.id);
    case 'reativar':
      viewModel.reactivateLocation(location.id);
    case 'inativar':
      String? replacement;
      if (needsDefaultReplacement(viewModel.profile.locations, location.id)) {
        replacement = await _pickReplacement(context, viewModel.profile.locations, location.id);
        if (replacement == null) return;
      }
      viewModel.inactivateLocation(location.id, replacementId: replacement);
  }
}

Future<void> _editLocation(
  BuildContext context,
  ProfileViewModel viewModel, {
  CareLocation? location,
}) async {
  final draft = await showDialog<({String name, String address})>(
    context: context,
    builder: (context) => _LocationDialog(location: location),
  );
  if (draft == null || draft.name.isEmpty) return;
  if (location == null) {
    viewModel.addLocation(name: draft.name, address: draft.address);
  } else {
    viewModel.editLocation(id: location.id, name: draft.name, address: draft.address);
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({this.location});

  final CareLocation? location;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final name = TextEditingController(text: widget.location?.name ?? '');
  late final address = TextEditingController(text: widget.location?.address ?? '');

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? 'Novo local' : 'Editar local'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nome'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: address,
            decoration: const InputDecoration(labelText: 'Endereço'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (name: name.text.trim(), address: address.text.trim())),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

Future<String?> _pickReplacement(
  BuildContext context,
  List<CareLocation> locations,
  String currentId,
) {
  final options = [
    for (final location in locations)
      if (location.active && location.id != currentId) location,
  ];
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Escolha o novo padrão'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final location in options)
            ListTile(
              title: Text(location.name),
              onTap: () => Navigator.pop(context, location.id),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ],
    ),
  );
}
