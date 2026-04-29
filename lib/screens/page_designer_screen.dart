import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../state/project_store.dart';
import '../widgets/color_palette_picker.dart';
import '../widgets/page_layout_selector.dart';
import 'export_screen.dart';

class PageDesignerScreen extends StatefulWidget {
  const PageDesignerScreen({super.key});

  @override
  State<PageDesignerScreen> createState() => _PageDesignerScreenState();
}

class _PageDesignerScreenState extends State<PageDesignerScreen> {
  Color _hex(String h) {
    var s = h.replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    return Color(int.parse(s, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectStore>().active;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Page Designer')),
        body: const Center(child: Text('No active project.')),
      );
    }

    final approved = project.pages.where((p) => p.isApproved).toList();
    final preview = approved.isNotEmpty
        ? approved.first
        : (project.pages.isEmpty ? null : project.pages.first);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Designer'),
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1 / 1.4,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _hex(project.appliedTheme.backgroundColorHex),
                border: Border.all(
                  color: _hex(project.appliedTheme.borderColorHex),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: preview == null
                  ? Center(
                      child: Text(
                        'Approve a page to preview here.',
                        style: TextStyle(
                          color: _hex(project.appliedTheme.textColorHex),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        preview.romanEnglishText.isEmpty
                            ? preview.textBlocks
                                .map((b) => b.romanContent)
                                .join('\n\n')
                            : preview.romanEnglishText,
                        style: TextStyle(
                          color: _hex(project.appliedTheme.textColorHex),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Color theme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ColorPalettePicker(
            selected: project.appliedTheme,
            onSelected: (t) {
              setState(() => project.appliedTheme = t);
              context.read<ProjectStore>().touchActive();
            },
          ),
          const Divider(height: 32),
          PageLayoutSelector(
            layout: project.layout,
            onChanged: (l) {
              setState(() => project.layout = l);
              context.read<ProjectStore>().touchActive();
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to Export'),
              onPressed: () async {
                await context.read<ProjectStore>().persist();
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExportScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

