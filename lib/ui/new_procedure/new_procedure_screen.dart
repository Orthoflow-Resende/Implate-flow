import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../core/layout.dart';
import '../core/mouth_chart.dart';
import '../core/preset_dropdown.dart';
import 'new_procedure_viewmodel.dart';

class NewProcedureScreen extends StatelessWidget {
  const NewProcedureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NewProcedureViewModel>();
    final titles = ['Modalidade', 'Boca', 'Resumo'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[viewModel.step])),
      body: switch (viewModel.step) {
        0 => _ModalityStep(viewModel: viewModel),
        1 => _MouthStep(viewModel: viewModel),
        _ => _SummaryStep(viewModel: viewModel),
      },
    );
  }
}

class _ModalityStep extends StatelessWidget {
  const _ModalityStep({required this.viewModel});

  final NewProcedureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const AppSectionHeader(
          title: 'Modalidade',
          subtitle: 'A regra de toque na boca muda conforme a escolha.',
        ),
        const SizedBox(height: 12),
        for (final modality in Modality.values) ...[
          AppSurfaceCard(
            child: ListTile(
              title: Text(modalityLabel(modality)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => viewModel.chooseModality(modality),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MouthStep extends StatelessWidget {
  const _MouthStep({required this.viewModel});

  final NewProcedureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final modality = viewModel.modality!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              AppSectionHeader(
                title: modalityLabel(modality),
                subtitle: 'Toque o dente para selecionar.',
              ),
              if (modality == Modality.protocolo) ...[
                const SizedBox(height: 12),
                SegmentedButton<Arch>(
                  segments: const [
                    ButtonSegment(value: Arch.superior, label: Text('Superior')),
                    ButtonSegment(value: Arch.inferior, label: Text('Inferior')),
                  ],
                  selected: {viewModel.arch},
                  onSelectionChanged: (value) => viewModel.chooseArch(value.first),
                ),
              ],
              const SizedBox(height: 12),
              AppSurfaceCard(
                padding: const EdgeInsets.all(8),
                child: MouthChart(
                  selected: viewModel.selected,
                  disabledArch: viewModel.disabledArch,
                  onToothTap: (tooth) {
                    final message = viewModel.toggleTooth(tooth);
                    if (message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tooth in viewModel.ordered)
                    InputChip(
                      label: Text(
                        modality == Modality.ponte
                            ? '$tooth · ${roleLabel(viewModel.roles[tooth] ?? ToothRole.pilar)}'
                            : '$tooth',
                      ),
                      onPressed: modality == Modality.ponte ? () => viewModel.flipRole(tooth) : null,
                      onDeleted: () => viewModel.toggleTooth(tooth),
                    ),
                ],
              ),
              if (viewModel.selected.isEmpty) const AppEmptyHint('Nenhum dente selecionado.'),
            ],
          ),
        ),
        AppFooterBar(
          secondaryLabel: 'Voltar',
          primaryLabel: 'Continuar',
          onSecondary: viewModel.backToModality,
          onPrimary: viewModel.openSummary,
          primaryEnabled: viewModel.canContinue,
        ),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({required this.viewModel});

  final NewProcedureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final modality = viewModel.modality!;
    final pontics = viewModel.ordered
        .where((tooth) => viewModel.roles[tooth] == ToothRole.pontico)
        .toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _OverviewCard(viewModel: viewModel),
              if (modality == Modality.ponte && pontics.isNotEmpty) ...[
                const SizedBox(height: 12),
                _PonticCard(teeth: pontics),
              ],
              const SizedBox(height: 20),
              AppSectionHeader(
                title: 'Rastreio',
                subtitle: 'Pode ficar em branco e ser completado depois.',
                action: viewModel.pillars.length > 1 && modality != Modality.enxerto
                    ? TextButton(
                        onPressed: viewModel.copyFromFirst,
                        child: const Text('Repetir o primeiro'),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              for (final tooth in viewModel.pillars) ...[
                _ToothCard(
                  viewModel: viewModel,
                  tooth: tooth,
                  expanded: tooth == viewModel.pillars.first,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              AppSectionHeader(
                title: 'Retornos',
                subtitle: 'Sutura em 7 dias · longo em ${viewModel.longMonths} meses.',
              ),
              const SizedBox(height: 8),
              _ReturnEditor(
                title: 'Sutura',
                date: viewModel.suture,
                enabled: viewModel.sutureReminder,
                hour: viewModel.sutureHour,
                onDate: viewModel.setSuture,
                onEnabled: viewModel.setSutureReminder,
                onHour: viewModel.setSutureHour,
              ),
              const SizedBox(height: 12),
              _ReturnEditor(
                title: 'Retorno longo',
                date: viewModel.longReturn,
                enabled: viewModel.longReminder,
                hour: viewModel.longHour,
                onDate: viewModel.setLongReturn,
                onEnabled: viewModel.setLongReminder,
                onHour: viewModel.setLongHour,
              ),
            ],
          ),
        ),
        AppFooterBar(
          secondaryLabel: 'Voltar',
          primaryLabel: 'Salvar',
          onSecondary: viewModel.backToMouth,
          onPrimary: () {
            final created = viewModel.save();
            context.pop();
            if (created.length == 1) context.push('/procedures/${created.first.id}');
          },
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.viewModel});

  final NewProcedureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              modalityLabel(viewModel.modality!),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _DateTile(
              icon: Icons.event_outlined,
              label: 'Cirurgia',
              value: formatDay(viewModel.surgery),
              onTap: () => _pickDate(context, viewModel.surgery, viewModel.setSurgery),
            ),
          ],
        ),
      ),
    );
  }
}

class _PonticCard extends StatelessWidget {
  const _PonticCard({required this.teeth});

  final List<int> teeth;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Pônticos sem peça: ${teeth.join(', ')}'),
      ),
    );
  }
}

class _ToothCard extends StatelessWidget {
  const _ToothCard({
    required this.viewModel,
    required this.tooth,
    required this.expanded,
  });

  final NewProcedureViewModel viewModel;
  final int tooth;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final draft = viewModel.drafts[tooth]!;
    final modality = viewModel.modality!;
    final pieceLine = [
      draft.manufacturer,
      draft.model,
    ].where((part) => part.isNotEmpty).join(' ');
    return AppCollapseCard(
      title: 'Dente $tooth',
      subtitle: pieceLine.isEmpty ? 'Rastreio opcional' : pieceLine,
      initiallyExpanded: expanded,
      child: Column(
        children: [
          if (modality != Modality.enxerto) ...[
            _ManufacturerField(viewModel: viewModel, tooth: tooth),
            const SizedBox(height: 12),
            _ModelField(viewModel: viewModel, tooth: tooth),
            const SizedBox(height: 12),
            _FieldRow(
              first: PresetDropdown(
                label: 'Tamanho',
                value: draft.size,
                options: implantSizes,
                onChanged: (value) => viewModel.updateDraft(tooth, (item) => item.size = value),
              ),
              second: PresetDropdown(
                label: 'Série',
                value: draft.serial,
                options: implantSerials[draft.manufacturer] ?? const [],
                enabled: draft.manufacturer.isNotEmpty,
                onChanged: (value) => viewModel.updateDraft(tooth, (item) => item.serial = value),
              ),
            ),
            const SizedBox(height: 4),
            _DateTile(
              icon: Icons.precision_manufacturing_outlined,
              label: 'Fabricação',
              value: draft.manufacturedOn == null ? 'Informar' : formatDay(draft.manufacturedOn!),
              onTap: () => _pickDate(
                context,
                draft.manufacturedOn ?? DateTime.now(),
                (value) => viewModel.updateDraft(tooth, (item) => item.manufacturedOn = value),
              ),
            ),
            _DateTile(
              icon: Icons.event_available_outlined,
              label: 'Validade',
              value: draft.expiresOn == null ? 'Informar' : formatDay(draft.expiresOn!),
              onTap: () => _pickDate(
                context,
                draft.expiresOn ?? DateTime.now(),
                (value) => viewModel.updateDraft(tooth, (item) => item.expiresOn = value),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Com enxerto'),
              value: draft.withGraft,
              onChanged: (value) => viewModel.updateDraft(tooth, (item) => item.withGraft = value),
            ),
          ],
          if (modality == Modality.enxerto || draft.withGraft)
            _GraftFields(viewModel: viewModel, tooth: tooth),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }
}

class _ManufacturerField extends StatelessWidget {
  const _ManufacturerField({
    required this.viewModel,
    required this.tooth,
    this.graftIndex,
  });

  final NewProcedureViewModel viewModel;
  final int tooth;
  final int? graftIndex;

  @override
  Widget build(BuildContext context) {
    final draft = viewModel.drafts[tooth]!;
    final catalog = graftIndex == null ? implantCatalog : graftCatalog;
    final current = graftIndex == null
        ? draft.manufacturer
        : draft.grafts[graftIndex!].manufacturer;
    return PresetDropdown(
      label: graftIndex == null ? 'Fabricante' : 'Fabricante do enxerto',
      value: current,
      options: catalog.keys.toList(),
      onChanged: (value) => viewModel.updateDraft(tooth, (item) {
        if (graftIndex == null) {
          item.manufacturer = value;
          item.model = '';
          item.serial = '';
        } else {
          item.grafts[graftIndex!].manufacturer = value;
          item.grafts[graftIndex!].model = '';
        }
      }),
    );
  }
}

class _ModelField extends StatelessWidget {
  const _ModelField({
    required this.viewModel,
    required this.tooth,
    this.graftIndex,
  });

  final NewProcedureViewModel viewModel;
  final int tooth;
  final int? graftIndex;

  @override
  Widget build(BuildContext context) {
    final draft = viewModel.drafts[tooth]!;
    final catalog = graftIndex == null ? implantCatalog : graftCatalog;
    final manufacturer = graftIndex == null
        ? draft.manufacturer
        : draft.grafts[graftIndex!].manufacturer;
    final current = graftIndex == null ? draft.model : draft.grafts[graftIndex!].model;
    final models = catalog[manufacturer] ?? const <String>[];
    return PresetDropdown(
      label: graftIndex == null ? 'Modelo' : 'Modelo do enxerto',
      value: current,
      options: models,
      enabled: manufacturer.isNotEmpty,
      onChanged: (value) => viewModel.updateDraft(tooth, (item) {
        if (graftIndex == null) {
          item.model = value;
        } else {
          item.grafts[graftIndex!].model = value;
        }
      }),
    );
  }
}

class _GraftFields extends StatelessWidget {
  const _GraftFields({required this.viewModel, required this.tooth});

  final NewProcedureViewModel viewModel;
  final int tooth;

  @override
  Widget build(BuildContext context) {
    final draft = viewModel.drafts[tooth]!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < draft.grafts.length; index++) ...[
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Enxerto ${index + 1}', style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      if (draft.grafts.length > 1)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => viewModel.removeGraft(tooth, index),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<GraftOrigin>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: GraftOrigin.biomaterial, label: Text('Biomaterial')),
                      ButtonSegment(value: GraftOrigin.autogeno, label: Text('Autógeno')),
                    ],
                    selected: {draft.grafts[index].origin},
                    onSelectionChanged: (value) => viewModel.updateDraft(
                      tooth,
                      (item) => item.grafts[index].origin = value.first,
                    ),
                  ),
                  if (draft.grafts[index].origin == GraftOrigin.biomaterial) ...[
                    const SizedBox(height: 12),
                    _ManufacturerField(viewModel: viewModel, tooth: tooth, graftIndex: index),
                    const SizedBox(height: 12),
                    _ModelField(viewModel: viewModel, tooth: tooth, graftIndex: index),
                    const SizedBox(height: 12),
                    _FieldRow(
                      first: TextFormField(
                        initialValue: draft.grafts[index].size,
                        decoration: const InputDecoration(labelText: 'Volume'),
                        onChanged: (value) => viewModel.updateDraft(
                          tooth,
                          (item) => item.grafts[index].size = value,
                        ),
                      ),
                      second: TextFormField(
                        initialValue: draft.grafts[index].serial,
                        decoration: const InputDecoration(labelText: 'Série'),
                        onChanged: (value) => viewModel.updateDraft(
                          tooth,
                          (item) => item.grafts[index].serial = value,
                        ),
                      ),
                    ),
                    _DateTile(
                      icon: Icons.precision_manufacturing_outlined,
                      label: 'Fabricação',
                      value: draft.grafts[index].manufacturedOn == null
                          ? 'Informar'
                          : formatDay(draft.grafts[index].manufacturedOn!),
                      onTap: () => _pickDate(
                        context,
                        draft.grafts[index].manufacturedOn ?? DateTime.now(),
                        (value) => viewModel.updateDraft(
                          tooth,
                          (item) => item.grafts[index].manufacturedOn = value,
                        ),
                      ),
                    ),
                    _DateTile(
                      icon: Icons.event_available_outlined,
                      label: 'Validade',
                      value: draft.grafts[index].expiresOn == null
                          ? 'Informar'
                          : formatDay(draft.grafts[index].expiresOn!),
                      onTap: () => _pickDate(
                        context,
                        draft.grafts[index].expiresOn ?? DateTime.now(),
                        (value) => viewModel.updateDraft(
                          tooth,
                          (item) => item.grafts[index].expiresOn = value,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: draft.grafts[index].donorSite,
                      decoration: const InputDecoration(labelText: 'Região doadora'),
                      onChanged: (value) => viewModel.updateDraft(
                        tooth,
                        (item) => item.grafts[index].donorSite = value,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => viewModel.addGraft(tooth),
            icon: const Icon(Icons.add),
            label: const Text('Outro enxerto'),
          ),
        ),
      ],
    );
  }
}

class _ReturnEditor extends StatelessWidget {
  const _ReturnEditor({
    required this.title,
    required this.date,
    required this.enabled,
    required this.hour,
    required this.onDate,
    required this.onEnabled,
    required this.onHour,
  });

  final String title;
  final DateTime date;
  final bool enabled;
  final int hour;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<int> onHour;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateTile(
              icon: Icons.event_outlined,
              label: title,
              value: formatDay(date),
              onTap: () => _pickDate(context, date, onDate),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('Lembrete'),
              value: enabled,
              onChanged: onEnabled,
            ),
            if (enabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final option in [7, 8, 9, 12, 18])
                      ChoiceChip(
                        label: Text('${option}h'),
                        selected: hour == option,
                        onSelected: (_) => onHour(option),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

Future<void> _pickDate(BuildContext context, DateTime current, ValueChanged<DateTime> onPicked) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(2020),
    lastDate: DateTime(2040),
  );
  if (picked != null) onPicked(dateOnly(picked));
}
