import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../core/layout.dart';
import '../view_models.dart';

class NextWeekScreen extends StatelessWidget {
  const NextWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NextWeekViewModel>();
    final followUps = viewModel.followUps;
    return Scaffold(
      appBar: AppBar(title: const Text('Próximos 7 dias')),
      body: followUps.isEmpty
          ? const Center(child: AppEmptyHint('Nada nos próximos 7 dias.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: followUps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final followUp = followUps[index];
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
              },
            ),
    );
  }
}
