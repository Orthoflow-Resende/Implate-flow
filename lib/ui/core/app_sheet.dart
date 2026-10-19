import 'package:flutter/material.dart';

/// Bottom sheet para ações curtas. Formulários longos usam rota própria
/// (paciente, rastreabilidade e novo procedimento). A escolha de paciente na
/// agenda já abre em sheet. Confirmações de descarte continuam em diálogo.
/// Filtros permanecem no menu dropdown.
Future<T?> showAppSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}

class AppSheet extends StatefulWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.dirty = false,
  });

  final String title;
  final Widget child;
  final Widget? footer;
  final bool dirty;

  static void pop<T>(BuildContext context, [T? result]) {
    final state = context.findAncestorStateOfType<_AppSheetState>();
    if (state == null) {
      Navigator.pop(context, result);
      return;
    }
    state._pop(result);
  }

  @override
  State<AppSheet> createState() => _AppSheetState();
}

class _AppSheetState extends State<AppSheet> {
  var _closing = false;

  bool get _canPop => _closing || !widget.dirty;

  void _pop<T>([T? result]) {
    setState(() => _closing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações'),
        content: const Text('O que foi digitado será perdido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Descartar')),
        ],
      ),
    );
    if (discard == true && mounted) _pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _canPop) return;
        _confirmDiscard();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  children: [widget.child],
                ),
              ),
              if (widget.footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: widget.footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSheetActions extends StatelessWidget {
  const AppSheetActions({
    super.key,
    required this.onSave,
    this.saveLabel = 'Salvar',
  });

  final VoidCallback onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => AppSheet.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: onSave, child: Text(saveLabel)),
        ),
      ],
    );
  }
}
