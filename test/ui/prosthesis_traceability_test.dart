import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/data/repositories/mock_clinic_repository.dart';
import 'package:implate_flow/data/services/mock_clinic_service.dart';
import 'package:implate_flow/domain/models.dart';
import 'package:implate_flow/ui/new_procedure/new_procedure_screen.dart';
import 'package:implate_flow/ui/new_procedure/new_procedure_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  for (final subtype in [
    ProcedureSubtype.unitario,
    ProcedureSubtype.ponte,
    ProcedureSubtype.protocolo,
  ]) {
    testWidgets('prótese ${subtype.name} mostra estado vazio sem vínculo', (tester) async {
      final repository = MockClinicRepository(MockClinicService());
      final patient = repository.current.patients.firstWhere((item) => item.name == 'João Lima');
      final viewModel = NewProcedureViewModel(repository, patientId: patient.id);
      viewModel.chooseModality(Modality.protese, subtype: subtype);
      viewModel.toggleTooth(14);
      if (subtype == ProcedureSubtype.ponte) {
        viewModel.toggleTooth(15);
        viewModel.toggleTooth(16);
      }
      viewModel.openSummary();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: const NewProcedureScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Rastreabilidade'), findsOneWidget);
      expect(find.textContaining('Nenhum implante vinculado'), findsWidgets);
      expect(viewModel.saveError, isNull);
    });
  }

  testWidgets('prótese com vínculo lista o implante na região', (tester) async {
    final repository = MockClinicRepository(MockClinicService());
    final patient = repository.current.patients.firstWhere((item) => item.name == 'João Lima');
    final implant = repository.current.procedures.firstWhere(
      (item) => item.patientId == patient.id && item.modality == Modality.implante,
    );
    final viewModel = NewProcedureViewModel(repository, patientId: patient.id);
    viewModel.chooseModality(Modality.protese, subtype: ProcedureSubtype.unitario);
    viewModel.toggleTooth(implant.sites.first.fdi);
    viewModel.toggleLinkedProcedure(implant.id);
    viewModel.openSummary();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: viewModel,
          child: const NewProcedureScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sem implante vinculado'), findsNothing);
    expect(find.text(implant.classificationLabel), findsWidgets);
  });
}
