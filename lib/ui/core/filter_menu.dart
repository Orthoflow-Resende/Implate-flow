import 'package:flutter/material.dart';

class FilterMenuOption {
  const FilterMenuOption({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
}

class FilterMenuGroup {
  const FilterMenuGroup({required this.title, required this.options});

  final String title;
  final List<FilterMenuOption> options;
}

class FilterMenuButton extends StatelessWidget {
  const FilterMenuButton({
    super.key,
    required this.groups,
    required this.activeCount,
    required this.onClear,
  });

  final List<FilterMenuGroup> groups;
  final int activeCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
    return MenuAnchor(
      style: MenuStyle(
        maximumSize: WidgetStatePropertyAll(Size(280, maxHeight)),
      ),
      menuChildren: [
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(group.title, style: Theme.of(context).textTheme.labelLarge),
          ),
          for (final option in group.options)
            MenuItemButton(
              onPressed: option.onSelected,
              leadingIcon: Icon(
                option.selected ? Icons.check : Icons.check,
                color: option.selected ? null : Colors.transparent,
              ),
              child: Text(option.label),
            ),
        ],
        const Divider(),
        MenuItemButton(
          onPressed: activeCount == 0 ? null : onClear,
          child: const Text('Limpar filtros'),
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Filtros',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Badge(
            isLabelVisible: activeCount > 0,
            label: Text('$activeCount'),
            child: const Icon(Icons.filter_alt_outlined),
          ),
        );
      },
    );
  }
}
