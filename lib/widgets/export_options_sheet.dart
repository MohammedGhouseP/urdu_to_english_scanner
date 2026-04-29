import 'package:flutter/material.dart';

import '../models/project_model.dart';

class ExportOptionsSheet extends StatefulWidget {
  const ExportOptionsSheet({super.key, required this.initial});

  final ExportSettings initial;

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet> {
  late ExportSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _settings.pageSize,
              decoration: const InputDecoration(labelText: 'Page size'),
              items: const [
                DropdownMenuItem(value: 'A4', child: Text('A4')),
                DropdownMenuItem(value: 'A5', child: Text('A5')),
                DropdownMenuItem(value: 'Letter', child: Text('Letter')),
              ],
              onChanged: (v) =>
                  setState(() => _settings = _settings.copyWith(pageSize: v)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _settings.dpi,
              decoration: const InputDecoration(labelText: 'DPI'),
              items: const [
                DropdownMenuItem(value: 150, child: Text('150')),
                DropdownMenuItem(value: 300, child: Text('300')),
                DropdownMenuItem(value: 600, child: Text('600')),
              ],
              onChanged: (v) =>
                  setState(() => _settings = _settings.copyWith(dpi: v)),
            ),
            CheckboxListTile(
              dense: true,
              title: const Text('Cover page'),
              value: _settings.includeCover,
              onChanged: (v) => setState(() =>
                  _settings = _settings.copyWith(includeCover: v ?? false)),
            ),
            CheckboxListTile(
              dense: true,
              title: const Text('Table of contents'),
              value: _settings.includeTableOfContents,
              onChanged: (v) => setState(() => _settings =
                  _settings.copyWith(includeTableOfContents: v ?? false)),
            ),
            CheckboxListTile(
              dense: true,
              title: const Text('Page numbers'),
              value: _settings.includePageNumbers,
              onChanged: (v) => setState(() => _settings =
                  _settings.copyWith(includePageNumbers: v ?? true)),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
              onPressed: () => Navigator.of(context).pop(_settings),
            ),
          ],
        ),
      ),
    );
  }
}
