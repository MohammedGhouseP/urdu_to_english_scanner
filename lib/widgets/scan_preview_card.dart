import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scanned_page_model.dart';

class ScanPreviewCard extends StatelessWidget {
  const ScanPreviewCard({
    super.key,
    required this.page,
    this.onTap,
    this.onDelete,
    this.compact = false,
  });

  final ScannedPage page;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(page.imagePath);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: compact ? 4 / 3 : 3 / 4,
              child: imageFile.existsSync()
                  ? Image.file(imageFile, fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Page ${page.pageNumber}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (page.isApproved)
                    const Icon(Icons.check_circle, size: 18, color: Colors.green)
                  else
                    Icon(
                      Icons.pending,
                      size: 18,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  if (onDelete != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
