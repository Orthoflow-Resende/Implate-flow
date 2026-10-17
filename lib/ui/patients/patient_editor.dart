import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../core/layout.dart';

class PatientDraft {
  const PatientDraft({
    required this.name,
    required this.phone,
    required this.cpf,
    required this.birthDate,
    this.notes = '',
    required this.guardian,
  });

  final String name;
  final String phone;
  final String cpf;
  final DateTime birthDate;
  final String notes;
  final String guardian;
}

bool _minor(DateTime birthDate) => Patient(
      id: 'draft',
      name: 'draft',
      phone: '',
      birthDate: birthDate,
    ).isMinor;

Future<PatientDraft?> editPatientDraft(
  BuildContext context, {
  required String title,
  PatientDraft? initial,
}) {
  return Navigator.of(context, rootNavigator: true).push<PatientDraft>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => PatientEditorPage(title: title, initial: initial),
    ),
  );
}

class PatientEditorPage extends StatefulWidget {
  const PatientEditorPage({super.key, required this.title, this.initial});

  final String title;
  final PatientDraft? initial;

  @override
  State<PatientEditorPage> createState() => _PatientEditorPageState();
}

class _PatientEditorPageState extends State<PatientEditorPage> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController cpf;
  late final TextEditingController guardian;
  late DateTime birth;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    name = TextEditingController(text: initial?.name ?? '');
    phone = TextEditingController(text: initial?.phone ?? '');
    cpf = TextEditingController(text: initial?.cpf ?? '');
    guardian = TextEditingController(text: initial?.guardian ?? '');
    birth = initial?.birthDate ?? DateTime(1980, 1, 1);
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    cpf.dispose();
    guardian.dispose();
    super.dispose();
  }

  bool get _canSave {
    final minor = _minor(birth);
    return name.text.trim().isNotEmpty && (!minor || guardian.text.trim().isNotEmpty);
  }

  void _save() {
    Navigator.pop(
      context,
      PatientDraft(
        name: name.text,
        phone: phone.text,
        cpf: formatCpf(cpf.text),
        birthDate: birth,
        notes: widget.initial?.notes ?? '',
        guardian: _minor(birth) ? guardian.text : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minor = _minor(birth);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const AppSectionHeader(
                  title: 'Cadastro',
                  subtitle: 'Nome, telefone, CPF e nascimento.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: cpf,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    helperText: 'Usado na busca da lista',
                  ),
                ),
                const SizedBox(height: 20),
                AppSurfaceCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(Icons.cake_outlined, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Nascimento'),
                    subtitle: Text(formatDay(birth)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: birth,
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => birth = picked);
                    },
                  ),
                ),
                if (minor) ...[
                  const SizedBox(height: 28),
                  const AppSectionHeader(
                    title: 'Responsável',
                    subtitle: 'Obrigatório para paciente menor de 18 anos.',
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: guardian,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Responsável legal'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
          AppFooterBar(
            secondaryLabel: 'Cancelar',
            primaryLabel: 'Salvar',
            onSecondary: () => Navigator.pop(context),
            onPrimary: _save,
            primaryEnabled: _canSave,
          ),
        ],
      ),
    );
  }
}
