import 'package:flutter_test/flutter_test.dart';
import 'package:implate_flow/data/repositories/clinic_repository.dart';
import 'package:implate_flow/data/repositories/mock_clinic_repository.dart';
import 'package:implate_flow/data/services/mock_clinic_service.dart';
import 'package:implate_flow/data/services/workos_auth.dart';
import 'package:implate_flow/main.dart';
import 'package:implate_flow/ui/view_models.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('A entrada mostra o implante flow', (tester) async {
    final repository = MockClinicRepository(MockClinicService());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ClinicRepository>.value(value: repository),
          ChangeNotifierProvider(create: (_) => SessionViewModel(repository, NativeWorkOsAuth())),
        ],
        child: const ImplateApp(),
      ),
    );
    expect(find.text('implante flow'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
