import 'package:flutter/material.dart';

class AppSafeArea extends StatelessWidget {
  const AppSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: child,
      ),
    );
  }
}
