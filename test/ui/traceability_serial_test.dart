import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/domain/models.dart';
import 'package:implate_flow/ui/procedure/traceability_editor.dart';

void main() {
  testWidgets('a edição do rastreio não pede número de série', (tester) async {
    final procedure = Procedure(
      id: 'pro-1',
      patientId: 'pac-1',
      modality: Modality.unitario,
      surgeryDate: DateTime(2026, 1, 1),
      statusLabel: implantStatusLabel(ImplantStatus.instalado),
      sites: [
        const ToothSite(
          fdi: 11,
          role: ToothRole.pilar,
          piece: ImplantPiece(
            manufacturer: 'Neodent',
            model: 'Drive',
            size: '3.5 × 10 mm',
          ),
        ),
      ],
    );
    List<ToothSite>? saved;
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await editTraceability(context, procedure: procedure);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Série'), findsNothing);
    expect(find.text('Neodent'), findsWidgets);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(saved!.single.piece!.manufacturer, 'Neodent');
  });
}
