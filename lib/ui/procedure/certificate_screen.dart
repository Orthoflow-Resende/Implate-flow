import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/certificate.dart';
import '../../domain/models.dart';
import '../core/layout.dart';
import '../view_models.dart';

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CertificateViewModel>();
    final procedure = viewModel.procedure;
    final patient = viewModel.patient;
    if (procedure == null || patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Certificado')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Procedimento não encontrado.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Voltar')),
            ],
          ),
        ),
      );
    }
    final missing = missingCertificateFields(
      profile: viewModel.profile,
      patient: patient,
      procedure: procedure,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Certificado')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (missing.isNotEmpty) ...[
            const AppSectionHeader(
              title: 'Rastreio incompleto',
              subtitle: 'Complete os campos para gerar o PDF.',
            ),
            const SizedBox(height: 8),
            AppSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in missing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $item'),
                    ),
                ],
              ),
            ),
          ] else ...[
            const AppSectionHeader(title: 'Prévia'),
            const SizedBox(height: 8),
            AppSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificado de procedência',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text('${viewModel.profile.name}\n${viewModel.profile.cro}'),
                  const SizedBox(height: 12),
                  Text('${patient.name}\nNascimento ${formatDay(patient.birthDate)}'),
                  if (patient.isMinor && patient.guardian.isNotEmpty)
                    Text('Responsável legal: ${patient.guardian}'),
                  const SizedBox(height: 12),
                  Text(
                    '${procedure.classificationLabel}\n'
                    '${formatDay(procedure.surgeryDate)}\n'
                    '${procedure.teethLabel}'
                    '${procedure.sinusLiftLabel == null ? '' : '\n${procedure.sinusLiftLabel}'}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final site in procedure.pillars) ...[
              AppSurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dente ${site.fdi}', style: Theme.of(context).textTheme.titleSmall),
                    if (site.piece != null)
                      Text(
                        '${site.piece!.manufacturer} ${site.piece!.model}\n'
                        '${site.piece!.size}\n'
                        'Fabricação ${site.piece!.manufacturedOn == null ? '—' : formatDay(site.piece!.manufacturedOn!)}\n'
                        'Validade ${site.piece!.expiresOn == null ? '—' : formatDay(site.piece!.expiresOn!)}',
                      ),
                    for (final graft in site.grafts)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${graftTraceLabel(graft)}'
                          '${graft.expiresOn == null ? '' : '\nValidade ${formatDay(graft.expiresOn!)}'}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              procedure.certificateIssuedAt == null
                  ? 'O PDF é gerado neste aparelho.'
                  : 'Emitido em ${formatDay(procedure.certificateIssuedAt!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await viewModel.issue();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      procedure.certificateIssuedAt == null
                          ? 'PDF do certificado gerado.'
                          : 'Certificado reemitido com o rastreio atual.',
                    ),
                  ),
                );
              },
              child: Text(procedure.certificateIssuedAt == null ? 'Gerar PDF' : 'Reemitir PDF'),
            ),
          ],
        ],
      ),
    );
  }
}
