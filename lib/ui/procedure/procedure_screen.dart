import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/services/clinic_files.dart';
import '../../domain/models.dart';
import '../core/layout.dart';
import '../view_models.dart';
import 'traceability_editor.dart';

class ProcedureScreen extends StatelessWidget {
  const ProcedureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProcedureViewModel>();
    final procedure = viewModel.procedure;
    final patient = viewModel.patient;
    final events = <({DateTime date, String title, String detail})>[
      (date: procedure.surgeryDate, title: 'Cirurgia', detail: modalityLabel(procedure.modality)),
      for (final visit in procedure.visits) (date: visit.date, title: 'Consulta', detail: visit.note),
      for (final followUp in procedure.followUps)
        (
          date: followUp.date,
          title: returnStatusLabel(followUp.status),
          detail: returnReasonLabel(followUp.reason),
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: Text(modalityLabel(procedure.modality))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('${formatDay(procedure.surgeryDate)} · ${procedure.teethLabel}'),
                Text(procedure.statusLabel),
                if (procedure.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(procedure.notes),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _editNotes(context, viewModel),
                    child: const Text('Editar notas'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSectionHeader(
            title: 'Rastreio',
            action: TextButton(
              onPressed: () async {
                final sites = await editTraceability(context, procedure: procedure);
                if (sites != null) viewModel.saveSites(sites);
              },
              child: const Text('Editar'),
            ),
          ),
          const SizedBox(height: 8),
          for (final site in procedure.sites) ...[
            AppSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dente ${site.fdi} · ${roleLabel(site.role)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (site.piece != null)
                    Text(
                      '${site.piece!.manufacturer} ${site.piece!.model} ${site.piece!.size}',
                    ),
                  for (final graft in site.grafts)
                    Text(
                      graft.origin == GraftOrigin.autogeno
                          ? 'Enxerto autógeno · ${graft.donorSite}'
                          : 'Enxerto ${graft.manufacturer} ${graft.model}'
                              '${graft.size.isEmpty ? '' : ' · ${graft.size}'}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Linha do tempo'),
          const SizedBox(height: 8),
          for (final event in events) ...[
            AppSurfaceCard(
              child: ListTile(
                title: Text(event.title),
                subtitle: Text('${formatDay(event.date)} · ${event.detail}'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          const AppSectionHeader(title: 'Fotos'),
          const SizedBox(height: 8),
          if (procedure.photos.isEmpty) const AppEmptyHint('Nenhuma foto.'),
          for (final photo in procedure.photos) ...[
            AppSurfaceCard(
              child: ListTile(
                leading: photo.path.isEmpty
                    ? const Icon(Icons.image_outlined)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photo.path),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                title: Text(photo.caption),
                subtitle: Text(photo.path.isEmpty ? 'Legenda sem arquivo' : 'Arquivo local'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => _addPhoto(context, viewModel),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Adicionar foto'),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Ações'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.push('/procedures/${procedure.id}/certificate'),
            child: const Text('Emitir certificado'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _visit(context, viewModel, procedure),
            child: const Text('Registrar consulta'),
          ),
          for (final followUp in procedure.followUps)
            if (followUp.status == ReturnStatus.agendado) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _complete(context, viewModel, procedure, followUp.id),
                child: Text('Registrar ${returnReasonLabel(followUp.reason)}'),
              ),
            ],
        ],
      ),
    );
  }

  Future<void> _editNotes(BuildContext context, ProcedureViewModel viewModel) async {
    final notes = TextEditingController(text: viewModel.procedure.notes);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notas do procedimento'),
        content: TextField(
          controller: notes,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Observação'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) viewModel.saveNotes(notes.text);
    notes.dispose();
  }

  Future<void> _addPhoto(BuildContext context, ProcedureViewModel viewModel) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !context.mounted) return;
    final caption = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legenda da foto'),
        content: TextField(
          controller: caption,
          decoration: const InputDecoration(labelText: 'Legenda'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true) {
      caption.dispose();
      return;
    }
    final id = viewModel.repository.allocateId('fot');
    final extension = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    final path = await ClinicFiles().copyFile(picked.path, '$id.$extension');
    viewModel.addPhoto(
      ClinicPhoto(
        id: id,
        caption: caption.text.trim().isEmpty ? 'Foto' : caption.text.trim(),
        path: path,
      ),
    );
    caption.dispose();
  }

  Future<void> _visit(
    BuildContext context,
    ProcedureViewModel viewModel,
    Procedure procedure,
  ) async {
    final result = await _consultationDialog(context, procedure, title: 'Registrar consulta');
    if (result == null) return;
    viewModel.addVisit(note: result.note, statusLabel: result.statusLabel);
  }

  Future<void> _complete(
    BuildContext context,
    ProcedureViewModel viewModel,
    Procedure procedure,
    String followUpId,
  ) async {
    final followUp = procedure.followUps.firstWhere((item) => item.id == followUpId);
    final result = await _consultationDialog(
      context,
      procedure,
      title: 'Registrar retorno',
      withAttendance: true,
      showStatus: followUp.reason != ReturnReason.sutura,
    );
    if (result == null) return;
    viewModel.completeFollowUp(
      followUpId: followUpId,
      note: result.note,
      statusLabel: result.statusLabel,
      returnStatus: result.attendance,
    );
  }
}

class _ConsultationResult {
  const _ConsultationResult({
    required this.note,
    required this.statusLabel,
    required this.attendance,
  });

  final String note;
  final String statusLabel;
  final ReturnStatus attendance;
}

Future<_ConsultationResult?> _consultationDialog(
  BuildContext context,
  Procedure procedure, {
  required String title,
  bool withAttendance = false,
  bool showStatus = true,
}) {
  final options = procedure.modality == Modality.enxerto
      ? [for (final status in GraftStatus.values) graftStatusLabel(status)]
      : [for (final status in ImplantStatus.values) implantStatusLabel(status)];
  final status = options.contains(procedure.statusLabel) ? procedure.statusLabel : options.first;
  return showDialog<_ConsultationResult>(
    context: context,
    builder: (context) => _ConsultationDialog(
      title: title,
      options: options,
      initialStatus: status,
      withAttendance: withAttendance,
      showStatus: showStatus,
    ),
  );
}

class _ConsultationDialog extends StatefulWidget {
  const _ConsultationDialog({
    required this.title,
    required this.options,
    required this.initialStatus,
    required this.withAttendance,
    required this.showStatus,
  });

  final String title;
  final List<String> options;
  final String initialStatus;
  final bool withAttendance;
  final bool showStatus;

  @override
  State<_ConsultationDialog> createState() => _ConsultationDialogState();
}

class _ConsultationDialogState extends State<_ConsultationDialog> {
  late String status = widget.initialStatus;
  var attendance = ReturnStatus.realizado;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final askStatus = widget.showStatus && (!widget.withAttendance || attendance == ReturnStatus.realizado);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.withAttendance)
            SegmentedButton<ReturnStatus>(
              segments: const [
                ButtonSegment(value: ReturnStatus.realizado, label: Text('Realizado')),
                ButtonSegment(value: ReturnStatus.faltou, label: Text('Faltou')),
              ],
              selected: {attendance},
              onSelectionChanged: (value) => setState(() => attendance = value.first),
            ),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Observação'),
          ),
          const SizedBox(height: 12),
          if (askStatus)
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final option in widget.options) DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => status = value);
              },
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ConsultationResult(
              note: note.text,
              statusLabel: status,
              attendance: widget.withAttendance ? attendance : ReturnStatus.realizado,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
