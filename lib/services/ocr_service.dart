import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;

import '../models/text_block_model.dart';

/// OCR for Urdu pages.
///
/// LIMITATION: `google_mlkit_text_recognition` does not support Arabic/Urdu
/// script — only Latin / Chinese / Devanagari / Japanese / Korean. This
/// implementation uses Latin recognition as a placeholder so the pipeline
/// runs; for real Urdu OCR, swap to `flutter_tesseract_ocr` (with
/// `urd.traineddata`) or a cloud OCR provider like Google Cloud Vision.
///
/// Keep this service as the single place where OCR is invoked; the rest of
/// the app calls `extractTextBlocks()` and doesn't care about the backend.
class OcrService {
  mlkit.TextRecognizer? _recognizer;

  mlkit.TextRecognizer _ensureRecognizer() {
    return _recognizer ??=
        mlkit.TextRecognizer(script: mlkit.TextRecognitionScript.latin);
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }

  Future<String> extractText(String imagePath) async {
    final blocks = await extractTextBlocks(imagePath);
    return blocks
        .map((b) => b.urduContent)
        .where((s) => s.isNotEmpty)
        .join('\n\n');
  }

  Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    if (!File(imagePath).existsSync()) {
      throw ArgumentError('Image not found at $imagePath');
    }

    final input = mlkit.InputImage.fromFilePath(imagePath);
    final recognizer = _ensureRecognizer();
    final mlkit.RecognizedText recognized;
    try {
      recognized = await recognizer.processImage(input);
    } on Exception catch (e) {
      // OCR can fail on unsupported platforms (desktop, web) or when the
      // ML Kit native binding isn't installed yet. Surface a single block
      // with the error so the UI can show it instead of crashing.
      return [
        TextBlock(
          urduContent: '',
          romanContent: '[OCR failed: $e]',
          confidence: 0.0,
          type: TextBlockType.paragraph,
        ),
      ];
    }

    final blocks = <TextBlock>[];
    for (final block in recognized.blocks) {
      final urdu = block.text.trim();
      if (urdu.isEmpty) continue;
      blocks.add(
        TextBlock(
          urduContent: urdu,
          confidence: _estimateConfidence(block),
          type: _guessType(urdu),
        ),
      );
    }
    return blocks;
  }

  /// ML Kit doesn't expose a per-block confidence directly; approximate.
  /// Calibrate when you move to a backend that returns real confidence.
  double _estimateConfidence(mlkit.TextBlock block) {
    final lineCount = block.lines.length;
    if (lineCount == 0) return 0.5;
    return 0.85;
  }

  TextBlockType _guessType(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 40 && !trimmed.contains('\n')) {
      return TextBlockType.heading;
    }
    return TextBlockType.paragraph;
  }
}
