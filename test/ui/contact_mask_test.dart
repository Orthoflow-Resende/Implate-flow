import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/ui/patients/patient_editor.dart';

void main() {
  testWidgets('cpf e telefone mascaram a colagem e bloqueiam valor inválido', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PatientDraft? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<PatientDraft>(
                MaterialPageRoute(
                  builder: (context) => const PatientEditorPage(title: 'Novo paciente'),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Ana Costa');
    await tester.enterText(find.widgetWithText(TextField, 'CPF'), '39053344705');
    await tester.enterText(find.widgetWithText(TextField, 'Telefone'), '11988881001');
    await tester.pump();

    expect(find.text('390.533.447-05'), findsOneWidget);
    expect(find.text('(11) 98888-1001'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'CPF'), '11111111111');
    await tester.pump();
    expect(find.text('Informe um CPF válido.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar')).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'CPF'), '');
    await tester.enterText(find.widgetWithText(TextField, 'Telefone'), '(11) 98888-1001');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(saved?.phone, '11988881001');
    expect(saved?.cpf, isEmpty);
  });
}
