import 'package:flutter/material.dart';

import '../../domain/models.dart';

class PresetDropdown extends StatelessWidget {
  const PresetDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final items = withCurrentOption(options, value);
    final current = items.contains(value) ? value : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        return DropdownMenu<String>(
          key: ValueKey('$label-${items.join()}-$value-$enabled'),
          enabled: enabled,
          width: width,
          initialSelection: current,
          label: Text(label),
          hintText: enabled ? 'Buscar' : null,
          enableFilter: true,
          requestFocusOnTap: enabled,
          inputDecorationTheme: Theme.of(context).inputDecorationTheme,
          dropdownMenuEntries: [
            for (final name in items) DropdownMenuEntry(value: name, label: name),
          ],
          filterCallback: (entries, filter) {
            final query = filter.trim().toLowerCase();
            if (query.isEmpty) return entries;
            return [
              for (final entry in entries)
                if (entry.label.toLowerCase().contains(query)) entry,
            ];
          },
          onSelected: enabled
              ? (selected) {
                  if (selected != null) onChanged(selected);
                }
              : null,
        );
      },
    );
  }
}
