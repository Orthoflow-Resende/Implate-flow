import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../core/layout.dart';
import '../view_models.dart';

class TodayRemindersScreen extends StatelessWidget {
  const TodayRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TodayRemindersViewModel>();
    final reminders = viewModel.reminders;
    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes de agendamento de hoje')),
      body: reminders.isEmpty
          ? const Center(child: AppEmptyHint('Nenhum lembrete de agendamento hoje.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: reminders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final followUp = reminders[index];
                final procedure = viewModel.procedureOf(followUp.id);
                if (procedure == null) return const SizedBox.shrink();
                final patient = viewModel.patientOf(procedure.patientId);
                return AppSurfaceCard(
                  child: ListTile(
                    title: Text(patient.name),
                    subtitle: Text(
                      '${formatDay(followUp.date)} · ${returnReasonLabel(followUp.reason)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/procedures/${procedure.id}'),
                  ),
                );
              },
            ),
    );
  }
}
