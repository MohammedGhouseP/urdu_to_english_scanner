import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_model.dart';
import '../services/pdf_export_service.dart';
import '../state/project_store.dart';
import '../widgets/export_options_sheet.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _busy = false;
  File? _lastFile;
  String? _error;

  Future<void> _generatePdf() async {
    final store = context.read<ProjectStore>();
    final pdfService = context.read<PdfExportService>();
    final project = store.active;
    if (project == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await pdfService.generatePdf(project);
      if (!mounted) return;
      setState(() => _lastFile = file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editOptions() async {
    final project = context.read<ProjectStore>().active;
    if (project == null) return;
    final updated = await showModalBottomSheet<ExportSettings>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExportOptionsSheet(initial: project.exportSettings),
    );
    if (updated != null) {
      project.exportSettings = updated;
      context.read<ProjectStore>().touchActive();
    }
  }

  Future<void> _share() async {
    final f = _lastFile;
    if (f == null) return;
    await Share.shareXFiles([XFile(f.path)], text: 'Exported manuscript');
  }

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectStore>().active;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Export')),
        body: const Center(child: Text('No active project.')),
      );
    }

    final approved = project.pages.where((p) => p.isApproved).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
        actions: [
          IconButton(
            tooltip: 'Options',
            icon: const Icon(Icons.tune),
            onPressed: _editOptions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '$approved of ${project.totalPageCount} pages approved',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Page size: ${project.exportSettings.pageSize} • DPI: ${project.exportSettings.dpi}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Full Book PDF'),
              onPressed:
                  _busy || approved == 0 ? null : _generatePdf,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.image_outlined),
              label: const Text('Export single page (PDF)  — TODO'),
              onPressed: null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.archive_outlined),
              label: const Text('ZIP of images  — TODO'),
              onPressed: null,
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (_lastFile != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Saved to:',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        _lastFile!.path,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              onPressed: _share,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
