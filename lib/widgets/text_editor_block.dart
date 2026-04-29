import 'package:flutter/material.dart';

import '../models/text_block_model.dart';
import '../utils/app_theme.dart';

class TextEditorBlock extends StatefulWidget {
  const TextEditorBlock({
    super.key,
    required this.block,
    required this.index,
    required this.onChanged,
    required this.onDelete,
    required this.onMergeWithNext,
    required this.onSplitAtCursor,
    this.showUrduOriginal = true,
  });

  final TextBlock block;
  final int index;
  final ValueChanged<TextBlock> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onMergeWithNext;
  final ValueChanged<int> onSplitAtCursor;
  final bool showUrduOriginal;

  @override
  State<TextEditorBlock> createState() => _TextEditorBlockState();
}

class _TextEditorBlockState extends State<TextEditorBlock> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.romanContent);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant TextEditorBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id ||
        oldWidget.block.romanContent != widget.block.romanContent &&
            !_focusNode.hasFocus) {
      _controller.text = widget.block.romanContent;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _confidenceColor(double c) {
    if (c >= 0.8) return Colors.green;
    if (c >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    return Card(
      key: ValueKey(block.id),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_indicator, size: 20),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        _confidenceColor(block.confidence).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(block.confidence * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: _confidenceColor(block.confidence),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<TextBlockType>(
                  value: block.type,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: TextBlockType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (t) {
                    if (t == null) return;
                    widget.onChanged(block.copyWith(type: t, isEdited: true));
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Split at cursor',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.call_split, size: 20),
                  onPressed: () =>
                      widget.onSplitAtCursor(_controller.selection.baseOffset),
                ),
                IconButton(
                  tooltip: 'Merge with next',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.merge, size: 20),
                  onPressed: widget.onMergeWithNext,
                ),
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            if (widget.showUrduOriginal && block.urduContent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 2),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    block.urduContent,
                    style: AppTheme.nastaliq(size: 16),
                  ),
                ),
              ),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Roman English…',
              ),
              style: TextStyle(
                fontSize: block.type == TextBlockType.heading ? 18 : 15,
                fontWeight: block.type == TextBlockType.heading
                    ? FontWeight.w600
                    : FontWeight.w400,
                fontStyle:
                    block.type == TextBlockType.verse ? FontStyle.italic : null,
              ),
              onChanged: (v) {
                widget.onChanged(block.copyWith(romanContent: v, isEdited: true));
              },
            ),
          ],
        ),
      ),
    );
  }
}
