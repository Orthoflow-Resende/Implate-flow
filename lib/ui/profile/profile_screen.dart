import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            subtitle: 'Canais ficam gravados. E-mail e push reais entram depois.',
          ),
          const SizedBox(height: 8),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Avisar no dia'),
                  value: profile.reminderEnabled,
                  onChanged: viewModel.setReminderEnabled,
                ),
                if (profile.reminderEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final hour in [7, 8, 9, 12, 18])
                          ChoiceChip(
                            label: Text('${hour}h'),
                            selected: profile.reminderHour == hour,
                            onSelected: (_) => viewModel.setReminderHour(hour),
                          ),
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
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          ),
        ],
      ),
    );
  }
}
