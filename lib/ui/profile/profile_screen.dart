import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
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
                Text(profile.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(profile.email),
                const SizedBox(height: 16),
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
