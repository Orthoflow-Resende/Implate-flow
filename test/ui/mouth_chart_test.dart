import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/ui/core/mouth_chart.dart';

void main() {
  testWidgets('o centro de cada dente permanente seleciona esse dente', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MouthChart(selected: const {}, onToothTap: taps.add),
          ),
        ),
      ),
    );

    for (final fdi in [11, 16, 18, 26, 36, 38, 46, 48]) {
      taps.clear();
      await tester.tap(find.bySemanticsLabel('Dente $fdi'));
      expect(taps, [fdi]);
    }
  });
}
