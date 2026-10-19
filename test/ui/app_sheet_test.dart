import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/ui/core/app_sheet.dart';

void main() {
  testWidgets('sheet curto não descarta o texto ao tocar fora e salva pelo botão', (tester) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await showAppSheet<String>(
                context: context,
                builder: (context) => const _NoteSheet(),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'oi');
    await tester.pump();

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('oi'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(saved, 'oi');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('cancelar fecha o sheet sem gravar', (tester) async {
    String? saved = 'mantido';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showAppSheet<String>(
                context: context,
                builder: (context) => const _NoteSheet(),
              );
              saved = result;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'rascunho');
    await tester.pump();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.text('rascunho'), findsNothing);
  });
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet();

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Anotação',
      dirty: note.text.isNotEmpty,
      footer: AppSheetActions(onSave: () => AppSheet.pop(context, note.text)),
      child: TextField(
        controller: note,
        decoration: const InputDecoration(labelText: 'Texto'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
