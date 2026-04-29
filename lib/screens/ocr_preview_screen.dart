import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scanned_page_model.dart';
import '../models/text_block_model.dart';
import '../services/ocr_service.dart';
import '../services/translation_service.dart';
import '../state/project_store.dart';
import '../utils/app_theme.dart';
import 'editor_screen.dart';

class OcrPreviewScreen extends StatefulWidget {
  const OcrPreviewScreen({super.key, required this.page});

  final ScannedPage page;

  @override
  State<OcrPreviewScreen> createState() => _OcrPreviewScreenState();
}

class _OcrPreviewScreenState extends State<OcrPreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    if (widget.page.textBlocks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runOcr());
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _runOcr() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final ocr = context.read<OcrService>();
      final translator = context.read<TranslationService>();
      final blocks = await ocr.extractTextBlocks(widget.page.imagePath);
      for (final b in blocks) {
        if (b.romanContent.isEmpty) {
          b.romanContent = translator.transliterateToRoman(b.urduContent);
        }
      }
      widget.page.textBlocks = blocks;
      widget.page.urduText = blocks.map((b) => b.urduContent).join('\n\n');
      widget.page.romanEnglishText =
          blocks.map((b) => b.romanContent).join('\n\n');
      context.read<ProjectStore>().replacePage(widget.page);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Color _confidenceColor(double c) {
    if (c >= 0.8) return Colors.green;
    if (c >= 0.6) return Colors.orange;
    return Colors.red;
  }

  bool get _shouldSuggestRescan {
    if (widget.page.textBlocks.isEmpty) return false;
    final avg = widget.page.textBlocks
            .map((b) => b.confidence)
            .fold<double>(0, (a, b) => a + b) /
        widget.page.textBlocks.length;
    return avg < 0.7;
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.page.imagePath);
    return Scaffold(
      appBar: AppBar(
        title: Text('Page ${widget.page.pageNumber}'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Urdu (Original)'),
            Tab(text: 'Roman English'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Re-scan OCR',
            icon: const Icon(Icons.refresh),
            onPressed: _running ? null : _runOcr,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            child: imageFile.existsSync()
                ? InteractiveViewer(
                    child: Image.file(imageFile, fit: BoxFit.contain),
                  )
                : const Center(child: Icon(Icons.broken_image, size: 64)),
          ),
          if (_running) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.all(10),
              child: Text(
                'OCR error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_shouldSuggestRescan)
            Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Text(
                'Low average OCR confidence — try better lighting and a flatter page, then re-scan.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _UrduList(blocks: widget.page.textBlocks),
                _RomanList(
                  blocks: widget.page.textBlocks,
                  confidenceColor: _confidenceColor,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.edit_note),
            label: const Text('Confirm & Edit'),
            onPressed: widget.page.textBlocks.isEmpty || _running
                ? null
                : () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => EditorScreen(page: widget.page),
                      ),
                    );
                  },
          ),
        ),
      ),
    );
  }
}

class _UrduList extends StatelessWidget {
  const _UrduList({required this.blocks});
  final List<TextBlock> blocks;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Center(child: Text('Run OCR to extract text.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: blocks.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (_, i) => Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          blocks[i].urduContent.isEmpty ? '—' : blocks[i].urduContent,
          style: AppTheme.nastaliq(size: 18),
        ),
      ),
    );
  }
}

class _RomanList extends StatelessWidget {
  const _RomanList({required this.blocks, required this.confidenceColor});
  final List<TextBlock> blocks;
  final Color Function(double) confidenceColor;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Center(child: Text('No text yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: blocks.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (_, i) {
        final b = blocks[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: confidenceColor(b.confidence).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(b.confidence * 100).round()}% • ${b.type.name}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: confidenceColor(b.confidence),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              b.romanContent.isEmpty ? '—' : b.romanContent,
              style: TextStyle(
                fontSize: b.type == TextBlockType.heading ? 18 : 15,
                fontWeight: b.type == TextBlockType.heading
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        );
      },
    );
  }
}
