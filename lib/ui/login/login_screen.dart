import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models.dart';

/// Splash discreto enquanto o AuthKit do sistema abre (F3S-517).
/// Sem botão "Entrar"; cancelamento/erro mostram "Tentar novamente".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SessionViewModel>().presentAuthKitIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SessionViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/branding/logo.png',
                    height: 96,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'implante flow',
                    textAlign: TextAlign.center,
                    style: theme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (viewModel.error != null) ...[
                    const SizedBox(height: 28),
                    Text(
                      viewModel.error!,
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium?.copyWith(color: scheme.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: viewModel.busy ? null : viewModel.retryAuthKit,
                      child: viewModel.busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Tentar novamente'),
                    ),
                  ] else if (viewModel.busy) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
