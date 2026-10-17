import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/clinic_repository.dart';
import 'data/repositories/mock_clinic_repository.dart';
import 'data/services/local_clinic_store.dart';
import 'data/services/mock_clinic_service.dart';
import 'data/services/workos_auth.dart';
import 'routing/router.dart';
import 'ui/core/app_safe_area.dart';
import 'ui/core/layout.dart';
import 'ui/view_models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalClinicStore();
  final loaded = await store.load();
  final repository = MockClinicRepository.fromSnapshot(
    loaded ?? MockClinicService().load(),
    persist: store.save,
  );
  runApp(
    MultiProvider(
      providers: [
        Provider<ClinicRepository>.value(value: repository),
        ChangeNotifierProvider(create: (_) => SessionViewModel(repository, NativeWorkOsAuth())),
      ],
      child: const ImplateApp(),
    ),
  );
}

class ImplateApp extends StatefulWidget {
  const ImplateApp({super.key});

  @override
  State<ImplateApp> createState() => _ImplateAppState();
}

class _ImplateAppState extends State<ImplateApp> {
  late final _router = buildRouter(context.read<SessionViewModel>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'implante flow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        return AppSafeArea(child: child ?? const SizedBox.shrink());
      },
      routerConfig: _router,
    );
  }
}
