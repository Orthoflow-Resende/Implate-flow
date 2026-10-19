import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../core/layout.dart';
import '../core/preset_dropdown.dart';
import '../new_procedure/new_procedure_viewmodel.dart';

Future<List<ToothSite>?> editTraceability(
  BuildContext context, {
  required Procedure procedure,
}) {
  return Navigator.of(context, rootNavigator: true).push<List<ToothSite>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => TraceabilityEditorPage(procedure: procedure),
    ),
  );
}

class TraceabilityEditorPage extends StatefulWidget {
  const TraceabilityEditorPage({super.key, required this.procedure});

  final Procedure procedure;

  @override
  State<TraceabilityEditorPage> createState() => _TraceabilityEditorPageState();
}

class _TraceabilityEditorPageState extends State<TraceabilityEditorPage> {
  late final Map<int, PieceDraft> drafts = {
    for (final site in widget.procedure.sites)
      if (site.role == ToothRole.pilar) site.fdi: PieceDraft.fromSite(site),
  };

  bool get _showImplant => widget.procedure.modality == Modality.implante;

  void _save() {
    Navigator.pop(context, [
      for (final site in widget.procedure.sites)
        ToothSite(
          fdi: site.fdi,
          role: site.role,
          piece: site.role == ToothRole.pontico || !_showImplant
              ? null
              : ImplantPiece(
                  manufacturer: drafts[site.fdi]?.manufacturer ?? '',
                  model: drafts[site.fdi]?.model ?? '',
                  size: drafts[site.fdi]?.size ?? '',
                  lot: drafts[site.fdi]?.lot ?? '',
                  anvisa: drafts[site.fdi]?.anvisa ?? '',
                  manufacturedOn: drafts[site.fdi]?.manufacturedOn,
                  expiresOn: drafts[site.fdi]?.expiresOn,
                ),
          grafts: site.role == ToothRole.pontico
              ? const []
              : [
                  if (!_showImplant || (drafts[site.fdi]?.withGraft ?? false))
                    for (final graft in drafts[site.fdi]?.grafts ?? const <GraftDraft>[])
                      graft.toMaterial(),
                ],
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pillars = [
      for (final site in widget.procedure.sites)
        if (drafts.containsKey(site.fdi)) site,
    ];
    final pontics = [
      for (final site in widget.procedure.sites)
        if (site.role == ToothRole.pontico) site.fdi,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Editar rastreio')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                AppSectionHeader(
                  title: widget.procedure.classificationLabel,
                  subtitle: 'Pode completar a peça agora ou deixar em branco.',
                ),
                if (pontics.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppSurfaceCard(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(16),
                    child: Text('Pônticos sem peça: ${pontics.join(', ')}'),
                  ),
                ],
                const SizedBox(height: 20),
                for (var index = 0; index < pillars.length; index++) ...[
                  _SiteCard(
                    site: pillars[index],
                    draft: drafts[pillars[index].fdi]!,
                    showImplant: _showImplant,
                    expanded: index == 0,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          AppFooterBar(
            secondaryLabel: 'Cancelar',
            primaryLabel: 'Salvar',
            onSecondary: () => Navigator.pop(context),
            onPrimary: _save,
          ),
        ],
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({
    required this.site,
    required this.draft,
    required this.showImplant,
    required this.expanded,
    required this.onChanged,
  });

  final ToothSite site;
  final PieceDraft draft;
  final bool showImplant;
  final bool expanded;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final pieceLine = [draft.manufacturer, draft.model].where((part) => part.isNotEmpty).join(' ');
    return AppCollapseCard(
      title: 'Dente ${site.fdi}',
      subtitle: pieceLine.isEmpty ? 'Rastreio opcional' : pieceLine,
      initiallyExpanded: expanded,
      child: Column(
        children: [
          if (showImplant) ...[
              PresetDropdown(
                label: 'Fabricante',
                value: draft.manufacturer,
                options: implantCatalog.keys.toList(),
                onChanged: (value) {
                  draft.manufacturer = value;
                  draft.model = '';
                  onChanged();
                },
              ),
              const SizedBox(height: 16),
              PresetDropdown(
                label: 'Modelo',
                value: draft.model,
                options: implantCatalog[draft.manufacturer] ?? const [],
                enabled: draft.manufacturer.isNotEmpty,
                onChanged: (value) {
                  draft.model = value;
                  onChanged();
                },
              ),
              const SizedBox(height: 16),
              PresetDropdown(
                label: 'Tamanho',
                value: draft.size,
                options: implantSizes,
                onChanged: (value) {
                  draft.size = value;
                  onChanged();
                },
              ),
              const SizedBox(height: 8),
              _DateTile(
                icon: Icons.precision_manufacturing_outlined,
                label: 'Fabricação',
                value: draft.manufacturedOn == null ? 'Informar' : formatDay(draft.manufacturedOn!),
                onTap: () => _pickDate(context, draft.manufacturedOn, (value) {
                  draft.manufacturedOn = value;
                  onChanged();
                }),
              ),
              _DateTile(
                icon: Icons.event_available_outlined,
                label: 'Validade',
                value: draft.expiresOn == null ? 'Informar' : formatDay(draft.expiresOn!),
                onTap: () => _pickDate(context, draft.expiresOn, (value) {
                  draft.expiresOn = value;
                  onChanged();
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Com enxerto'),
                value: draft.withGraft,
                onChanged: (value) {
                  draft.withGraft = value;
                  onChanged();
                },
              ),
            ],
            if (!showImplant || draft.withGraft) _GraftBlock(draft: draft, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _GraftBlock extends StatelessWidget {
  const _GraftBlock({required this.draft, required this.onChanged});

  final PieceDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
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
                          onPressed: () {
                            draft.grafts.removeAt(index);
                            onChanged();
                          },
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
                    onSelectionChanged: (value) {
                      draft.grafts[index].origin = value.first;
                      onChanged();
                    },
                  ),
                  if (draft.grafts[index].origin == GraftOrigin.biomaterial) ...[
                    const SizedBox(height: 16),
                    PresetDropdown(
                      label: 'Fabricante',
                      value: draft.grafts[index].manufacturer,
                      options: graftCatalog.keys.toList(),
                      onChanged: (value) {
                        draft.grafts[index].manufacturer = value;
                        draft.grafts[index].model = '';
                        onChanged();
                      },
                    ),
                    const SizedBox(height: 16),
                    PresetDropdown(
                      label: 'Modelo',
                      value: draft.grafts[index].model,
                      options: graftCatalog[draft.grafts[index].manufacturer] ?? const [],
                      enabled: draft.grafts[index].manufacturer.isNotEmpty,
                      onChanged: (value) {
                        draft.grafts[index].model = value;
                        onChanged();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: draft.grafts[index].size,
                      decoration: const InputDecoration(labelText: 'Volume'),
                      onChanged: (value) => draft.grafts[index].size = value,
                    ),
                    _DateTile(
                      icon: Icons.precision_manufacturing_outlined,
                      label: 'Fabricação',
                      value: draft.grafts[index].manufacturedOn == null
                          ? 'Informar'
                          : formatDay(draft.grafts[index].manufacturedOn!),
                      onTap: () => _pickDate(context, draft.grafts[index].manufacturedOn, (value) {
                        draft.grafts[index].manufacturedOn = value;
                        onChanged();
                      }),
                    ),
                    _DateTile(
                      icon: Icons.event_available_outlined,
                      label: 'Validade',
                      value: draft.grafts[index].expiresOn == null
                          ? 'Informar'
                          : formatDay(draft.grafts[index].expiresOn!),
                      onTap: () => _pickDate(context, draft.grafts[index].expiresOn, (value) {
                        draft.grafts[index].expiresOn = value;
                        onChanged();
                      }),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: draft.grafts[index].donorSite,
                      decoration: const InputDecoration(labelText: 'Região doadora'),
                      onChanged: (value) => draft.grafts[index].donorSite = value,
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
            onPressed: () {
              draft.grafts.add(GraftDraft());
              onChanged();
            },
            icon: const Icon(Icons.add),
            label: const Text('Outro enxerto'),
          ),
        ),
      ],
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

Future<void> _pickDate(
  BuildContext context,
  DateTime? current,
  ValueChanged<DateTime> onPicked,
) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2040),
  );
  if (picked != null) onPicked(dateOnly(picked));
}
