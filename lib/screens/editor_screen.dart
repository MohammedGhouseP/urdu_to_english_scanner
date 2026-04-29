import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scanned_page_model.dart';
import '../models/text_block_model.dart';
import '../state/project_store.dart';
import '../widgets/text_editor_block.dart';
import 'page_designer_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.page});

  final ScannedPage page;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late List<TextBlock> _blocks;
  bool _showUrdu = true;

  static const _maxUndo = 50;
  final List<List<TextBlock>> _undo = [];
  final List<List<TextBlock>> _redo = [];

  @override
  void initState() {
    super.initState();
    _blocks = widget.page.textBlocks
        .map((b) => b.copyWith())
        .toList(growable: true);
  }

  void _snapshot() {
    _undo.add(_blocks.map((b) => b.copyWith()).toList());
    if (_undo.length > _maxUndo) _undo.removeAt(0);
    _redo.clear();
  }

  void _undoOne() {
    if (_undo.isEmpty) return;
    setState(() {
      _redo.add(_blocks.map((b) => b.copyWith()).toList());
      _blocks = _undo.removeLast();
    });
  }

  void _redoOne() {
    if (_redo.isEmpty) return;
    setState(() {
      _undo.add(_blocks.map((b) => b.copyWith()).toList());
      _blocks = _redo.removeLast();
    });
  }

  void _onBlockChanged(int index, TextBlock updated) {
    _snapshot();
    setState(() => _blocks[index] = updated);
  }

  void _onDelete(int index) {
    _snapshot();
    setState(() => _blocks.removeAt(index));
  }

  void _onMergeWithNext(int index) {
    if (index >= _blocks.length - 1) return;
    _snapshot();
    setState(() {
      final a = _blocks[index];
      final b = _blocks[index + 1];
      _blocks[index] = a.copyWith(
        urduContent: [a.urduContent, b.urduContent].where((s) => s.isNotEmpty).join(' '),
        romanContent: [a.romanContent, b.romanContent].where((s) => s.isNotEmpty).join(' '),
        isEdited: true,
      );
      _blocks.removeAt(index + 1);
    });
  }

  void _onSplitAtCursor(int index, int cursor) {
    final block = _blocks[index];
    final text = block.romanContent;
    if (cursor <= 0 || cursor >= text.length) return;
    _snapshot();
    setState(() {
      final left = text.substring(0, cursor).trimRight();
      final right = text.substring(cursor).trimLeft();
      _blocks[index] = block.copyWith(romanContent: left, isEdited: true);
      _blocks.insert(
        index + 1,
        TextBlock(
          urduContent: '',
          romanContent: right,
          confidence: block.confidence,
          isEdited: true,
          type: block.type,
        ),
      );
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    _snapshot();
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
    });
  }

  Future<void> _approveAndContinue() async {
    widget.page.textBlocks = _blocks;
    widget.page.romanEnglishText =
        _blocks.map((b) => b.romanContent).join('\n\n');
    widget.page.urduText = _blocks.map((b) => b.urduContent).join('\n\n');
    widget.page.isApproved = true;
    final store = context.read<ProjectStore>();
    store.replacePage(widget.page);
    store.approvePage(widget.page.id);
    await store.persist();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PageDesignerScreen()),
    );
  }

  int get _wordCount => _blocks
      .map((b) => b.romanContent.trim().split(RegExp(r'\s+')))
      .expand((l) => l)
      .where((w) => w.isNotEmpty)
      .length;

  int get _charCount =>
      _blocks.fold(0, (sum, b) => sum + b.romanContent.length);

  int get _readMinutes => (_wordCount / 230).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit page ${widget.page.pageNumber}'),
        actions: [
          IconButton(
            tooltip: _showUrdu ? 'Hide Urdu' : 'Show Urdu',
            icon: Icon(_showUrdu ? Icons.translate : Icons.translate_outlined),
            onPressed: () => setState(() => _showUrdu = !_showUrdu),
          ),
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _undo.isEmpty ? null : _undoOne,
          ),
          IconButton(
            tooltip: 'Redo',
            icon: const Icon(Icons.redo),
            onPressed: _redo.isEmpty ? null : _redoOne,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        buildDefaultDragHandles: false,
        itemCount: _blocks.length,
        onReorder: _onReorder,
        itemBuilder: (context, i) {
          final block = _blocks[i];
          return TextEditorBlock(
            key: ValueKey(block.id),
            block: block,
            index: i,
            showUrduOriginal: _showUrdu,
            onChanged: (b) => _onBlockChanged(i, b),
            onDelete: () => _onDelete(i),
            onMergeWithNext: () => _onMergeWithNext(i),
            onSplitAtCursor: (cursor) => _onSplitAtCursor(i, cursor),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Words: $_wordCount',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('Chars: $_charCount',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('~$_readMinutes min read',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add block'),
                      onPressed: () {
                        _snapshot();
                        setState(() {
                          _blocks.add(TextBlock(isEdited: true));
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Page Approved'),
                      onPressed: _blocks.isEmpty ? null : _approveAndContinue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
