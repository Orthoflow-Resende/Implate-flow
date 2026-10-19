import 'package:flutter/material.dart';

const appRadius = 16.0;

const appCyan = Color(0xFF5BD3F3);
const appMint = Color(0xFF74F3D8);
const appInk = Color(0xFF383D41);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: appCyan,
    brightness: Brightness.light,
  ).copyWith(
    primary: appCyan,
    onPrimary: appInk,
    primaryContainer: appMint,
    onPrimaryContainer: appInk,
    secondary: appMint,
    onSecondary: appInk,
    secondaryContainer: appMint,
    onSecondaryContainer: appInk,
    tertiary: appMint,
    onTertiary: appInk,
    surface: const Color(0xFFF7FDFE),
    onSurface: appInk,
    onSurfaceVariant: appInk,
    surfaceTint: Colors.transparent,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(appRadius));
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF3FCFF),
    useMaterial3: true,
    textTheme: ThemeData.light().textTheme.apply(bodyColor: appInk, displayColor: appInk),
    iconTheme: const IconThemeData(color: appInk),
    listTileTheme: const ListTileThemeData(
      textColor: appInk,
      iconColor: appInk,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFFF3FCFF),
      foregroundColor: appInk,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: shape,
    ),
    dialogTheme: DialogThemeData(shape: shape),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 68,
      backgroundColor: scheme.surface,
      indicatorColor: appMint,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconTheme: const WidgetStatePropertyAll(IconThemeData(color: appInk)),
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(color: appInk)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
      highlightElevation: 2,
      backgroundColor: appCyan,
      foregroundColor: appInk,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: appInk),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: appCyan,
        foregroundColor: appInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: Colors.transparent,
        foregroundColor: appInk,
        side: const BorderSide(color: appInk),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: appInk),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(appInk),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return appCyan;
          return Colors.transparent;
        }),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surface,
      selectedColor: appMint,
      disabledColor: scheme.surface,
      labelStyle: const TextStyle(color: appInk),
      secondaryLabelStyle: const TextStyle(color: appInk),
      checkmarkColor: appInk,
      side: BorderSide(color: appInk.withValues(alpha: 0.18)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return appInk;
        return scheme.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return appCyan;
        return appInk.withValues(alpha: 0.2);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      filled: true,
      fillColor: scheme.surface,
      isDense: true,
    ),
  );
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(appRadius),
      child: card,
    );
  }
}

class AppCollapseCard extends StatefulWidget {
  const AppCollapseCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<AppCollapseCard> createState() => _AppCollapseCardState();
}

class _AppCollapseCardState extends State<AppCollapseCard> {
  late bool open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: widget.subtitle == null
                ? null
                : Text(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Icon(open ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => open = !open),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class AppEmptyHint extends StatelessWidget {
  const AppEmptyHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class AppFooterBar extends StatelessWidget {
  const AppFooterBar({
    super.key,
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondary,
    required this.onPrimary,
    this.primaryEnabled = true,
  });

  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback onSecondary;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: primaryEnabled ? onPrimary : null,
                  child: Text(primaryLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
