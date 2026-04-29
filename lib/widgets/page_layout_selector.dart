import 'package:flutter/material.dart';

import '../models/project_model.dart';

class PageLayoutSelector extends StatelessWidget {
  const PageLayoutSelector({
    super.key,
    required this.layout,
    required this.onChanged,
  });

  final PageLayout layout;
  final ValueChanged<PageLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Columns',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SegmentedButton<PageColumns>(
          segments: const [
            ButtonSegment(
                value: PageColumns.single, label: Text('Single'), icon: Icon(Icons.view_agenda)),
            ButtonSegment(
                value: PageColumns.double, label: Text('Two'), icon: Icon(Icons.view_column)),
          ],
          selected: {layout.columns},
          onSelectionChanged: (s) =>
              onChanged(layout.copyWith(columns: s.first)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Margin',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SegmentedButton<PageMargin>(
          segments: const [
            ButtonSegment(value: PageMargin.narrow, label: Text('Narrow')),
            ButtonSegment(value: PageMargin.normal, label: Text('Normal')),
            ButtonSegment(value: PageMargin.wide, label: Text('Wide')),
          ],
          selected: {layout.margin},
          onSelectionChanged: (s) =>
              onChanged(layout.copyWith(margin: s.first)),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Show header'),
          value: layout.showHeader,
          onChanged: (v) => onChanged(layout.copyWith(showHeader: v)),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Show footer'),
          value: layout.showFooter,
          onChanged: (v) => onChanged(layout.copyWith(showFooter: v)),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Page numbers'),
          value: layout.showPageNumbers,
          onChanged: (v) => onChanged(layout.copyWith(showPageNumbers: v)),
        ),
      ],
    );
  }
}
