import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/api_feedback.dart';
import '../view_models.dart';

/// Exibe SnackBars de sucesso/erro em qualquer rota (shell ou fora).
class ApiFeedbackHost extends StatefulWidget {
  const ApiFeedbackHost({super.key, required this.child});

  final Widget child;

  @override
  State<ApiFeedbackHost> createState() => _ApiFeedbackHostState();
}

class _ApiFeedbackHostState extends State<ApiFeedbackHost> {
  ApiFeedback? _shown;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>();
    final notice = session.feedback;
    if (notice != null && !identical(notice, _shown)) {
      _shown = notice;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(notice.message),
            backgroundColor: switch (notice.kind) {
              ApiFeedbackKind.error => Theme.of(context).colorScheme.error,
              ApiFeedbackKind.pending => Theme.of(context).colorScheme.tertiary,
              ApiFeedbackKind.success => null,
            },
          ),
        );
        session.clearFeedback();
      });
    }
    return widget.child;
  }
}
