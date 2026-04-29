import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/scanned_page_model.dart';
import '../services/storage_service.dart';
import '../state/project_store.dart';
import '../widgets/scan_preview_card.dart';
import 'ocr_preview_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  bool _batchMode = false;

  Future<void> _captureFromCamera() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked != null) {
        await _ingest([picked.path]);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final List<XFile> picked;
      if (_batchMode) {
        picked = await _picker.pickMultiImage(imageQuality: 92);
      } else {
        final one = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 92,
        );
        picked = one == null ? <XFile>[] : <XFile>[one];
      }
      final paths = picked.map((f) => f.path).toList(growable: false);
      if (paths.isNotEmpty) await _ingest(paths);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ingest(List<String> paths) async {
    final storage = context.read<StorageService>();
    final scansDir = await storage.scansDirectory();
    final store = context.read<ProjectStore>();

    final newPages = <ScannedPage>[];
    for (final src in paths) {
      final cropped = await _cropAndCorrect(src);
      final finalPath = cropped ?? src;
      final basename = finalPath
          .replaceAll('\\', '/')
          .split('/')
          .last;
      final destFilename =
          '${DateTime.now().millisecondsSinceEpoch}_$basename';
      final dest = File('${scansDir.path}/$destFilename');
      await File(finalPath).copy(dest.path);

      final page = ScannedPage(imagePath: dest.path);
      store.addPage(page);
      newPages.add(page);
    }

    if (newPages.isNotEmpty && mounted) {
      // Jump straight into OCR preview for the first new page; user can
      // navigate back to scan more.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OcrPreviewScreen(page: newPages.first),
        ),
      );
    }
  }

  Future<String?> _cropAndCorrect(String path) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: path,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop & deskew',
            lockAspectRatio: false,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(title: 'Crop & deskew'),
        ],
      );
      return cropped?.path;
    } catch (_) {
      // Cropper unavailable on this platform — pass-through original.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final pages = store.active?.pages ?? const <ScannedPage>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan pages'),
        actions: [
          Tooltip(
            message: _batchMode
                ? 'Batch mode on — pick multiple at once'
                : 'Batch mode off — one image at a time',
            child: IconButton(
              icon: Icon(_batchMode ? Icons.collections : Icons.photo),
              onPressed: () => setState(() => _batchMode = !_batchMode),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: _busy ? null : _captureFromCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(_batchMode ? 'Gallery (multi)' : 'Gallery'),
                    onPressed: _busy ? null : _pickFromGallery,
                  ),
                ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          const Divider(height: 1),
          Expanded(
            child: pages.isEmpty
                ? _EmptyHint(busy: _busy)
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: pages.length,
                    itemBuilder: (context, i) {
                      final page = pages[i];
                      return ScanPreviewCard(
                        page: page,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OcrPreviewScreen(page: page),
                            ),
                          );
                        },
                        onDelete: () {
                          context.read<ProjectStore>().removePage(page.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: pages.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Save & continue'),
                  onPressed: () async {
                    await context.read<ProjectStore>().persist();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.busy});
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              busy ? 'Working…' : 'Use Camera or Gallery to scan a page.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Each page goes through OCR → Editor → Designer → Export.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
