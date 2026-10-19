import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../core/filter_menu.dart';
import '../core/layout.dart';
import '../view_models.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();
    final marks = viewModel.marks;
    final selected = viewModel.selected;
    final selectedMarks = selected == null
        ? <CalendarMark>[]
        : marks.where((mark) => sameDay(mark.date, selected)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          FilterMenuButton(
            activeCount: viewModel.returnFilter == null ? 0 : 1,
            onClear: () => viewModel.setReturnFilter(null),
            groups: [
              FilterMenuGroup(
                title: 'Retorno',
                options: [
                  FilterMenuOption(
                    label: 'Todos',
                    selected: viewModel.returnFilter == null,
                    onSelected: () => viewModel.setReturnFilter(null),
                  ),
                  FilterMenuOption(
                    label: 'Agendados',
                    selected: viewModel.returnFilter == ReturnStatus.agendado,
                    onSelected: () => viewModel.setReturnFilter(ReturnStatus.agendado),
                  ),
                  FilterMenuOption(
                    label: 'Realizados',
                    selected: viewModel.returnFilter == ReturnStatus.realizado,
                    onSelected: () => viewModel.setReturnFilter(ReturnStatus.realizado),
                  ),
                  FilterMenuOption(
                    label: 'Faltou',
                    selected: viewModel.returnFilter == ReturnStatus.faltou,
                    onSelected: () => viewModel.setReturnFilter(ReturnStatus.faltou),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(onPressed: viewModel.previousMonth, icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Text(
                        _monthTitle(viewModel.month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(onPressed: viewModel.nextMonth, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                _MonthGrid(
                  month: viewModel.month,
                  marks: marks,
                  selected: selected,
                  onSelect: viewModel.selectDay,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionHeader(
            title: selected == null ? 'Dia' : formatDay(selected),
            subtitle: selectedMarks.isEmpty ? 'Toque um dia no mês.' : null,
          ),
          const SizedBox(height: 8),
          if (selectedMarks.isEmpty)
            const AppEmptyHint('Nenhuma data de paciente neste dia.')
          else
            for (final mark in selectedMarks) ...[
              AppSurfaceCard(
                color: mark.overdue ? Theme.of(context).colorScheme.errorContainer : null,
                child: ListTile(
                  title: Text(mark.patientName),
                  subtitle: Text(
                    '${_kindLabel(mark.kind)} · ${mark.label}'
                    '${mark.overdue ? ' · atrasado' : ''}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Paciente',
                    onPressed: () => context.push('/patients/${mark.patientId}'),
                    icon: const Icon(Icons.person_outline),
                  ),
                  onTap: () => context.push('/procedures/${mark.procedureId}'),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.marks,
    required this.selected,
    required this.onSelect,
  });

  final DateTime month;
  final List<CalendarMark> marks;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = leading + days;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: cells,
      itemBuilder: (context, index) {
        if (index < leading) return const SizedBox.shrink();
        final day = DateTime(month.year, month.month, index - leading + 1);
        final dayMarks = marks.where((mark) => sameDay(mark.date, day)).toList();
        final count = dayMarks.length;
        final overdue = dayMarks.any((mark) => mark.overdue);
        final isSelected = selected != null && sameDay(selected!, day);
        final scheme = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () => onSelect(day),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? (overdue ? scheme.errorContainer : scheme.primaryContainer)
                  : overdue
                      ? scheme.errorContainer.withValues(alpha: 0.45)
                      : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: overdue ? scheme.error : null,
                    fontWeight: overdue ? FontWeight.w700 : null,
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      color: overdue ? scheme.error : scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _monthTitle(DateTime month) {
  const names = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  return '${names[month.month - 1]} ${month.year}';
}

String _kindLabel(CalendarKind kind) => switch (kind) {
      CalendarKind.cirurgia => 'Cirurgia',
      CalendarKind.consulta => 'Consulta',
      CalendarKind.retorno => 'Retorno',
    };
