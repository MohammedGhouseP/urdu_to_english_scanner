import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/project_model.dart';
import '../models/scanned_page_model.dart';
import '../models/text_block_model.dart';

class PdfExportService {
  Future<File> generatePdf(Project project) async {
    final pdf = pw.Document(
      title: project.name,
      author: 'Urdu to English Scanner',
    );

    final theme = project.appliedTheme;
    final bg = _hexToPdfColor(theme.backgroundColorHex);
    final textColor = _hexToPdfColor(theme.textColorHex);
    final headingColor = _hexToPdfColor(theme.headingColorHex);
    final pageFormat = _resolvePageFormat(project.exportSettings.pageSize);
    final margin = _resolveMargin(project.layout.margin);

    final approved = project.pages.where((p) => p.isApproved).toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    if (project.exportSettings.includeCover) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (ctx) => pw.Container(
            color: bg,
            child: pw.Center(
              child: pw.Text(
                project.name,
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: headingColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    for (final page in approved) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: margin,
          build: (ctx) => pw.Container(
            color: bg,
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page.textBlocks.isNotEmpty)
                  ...page.textBlocks.map(
                    (b) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Text(
                        b.romanContent,
                        style: pw.TextStyle(
                          fontSize:
                              b.type == TextBlockType.heading ? 18 : 12,
                          fontWeight: b.type == TextBlockType.heading
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                          color: b.type == TextBlockType.heading
                              ? headingColor
                              : textColor,
                        ),
                      ),
                    ),
                  )
                else
                  pw.Text(
                    page.romanEnglishText,
                    style: pw.TextStyle(fontSize: 12, color: textColor),
                  ),
                pw.Spacer(),
                if (project.exportSettings.includePageNumbers)
                  pw.Align(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Text(
                      '${page.pageNumber}',
                      style: pw.TextStyle(fontSize: 10, color: textColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final exportsDir = await _ensureExportsDir();
    final safeName = project.name.replaceAll(RegExp(r'[^A-Za-z0-9_\- ]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${exportsDir.path}/${safeName}_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> exportSinglePage(ScannedPage page, PageTheme theme) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Container(
          color: _hexToPdfColor(theme.backgroundColorHex),
          padding: const pw.EdgeInsets.all(32),
          child: pw.Text(
            page.romanEnglishText.isEmpty
                ? page.textBlocks.map((b) => b.romanContent).join('\n\n')
                : page.romanEnglishText,
            style: pw.TextStyle(
              fontSize: 12,
              color: _hexToPdfColor(theme.textColorHex),
            ),
          ),
        ),
      ),
    );

    final exportsDir = await _ensureExportsDir();
    final file = File(
      '${exportsDir.path}/page_${page.pageNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<Directory> _ensureExportsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exports = Directory('${dir.path}/exports');
    if (!exports.existsSync()) await exports.create(recursive: true);
    return exports;
  }

  PdfPageFormat _resolvePageFormat(String size) {
    switch (size.toUpperCase()) {
      case 'A5':
        return PdfPageFormat.a5;
      case 'LETTER':
        return PdfPageFormat.letter;
      case 'A4':
      default:
        return PdfPageFormat.a4;
    }
  }

  pw.EdgeInsets _resolveMargin(PageMargin m) {
    switch (m) {
      case PageMargin.narrow:
        return const pw.EdgeInsets.all(24);
      case PageMargin.wide:
        return const pw.EdgeInsets.all(72);
      case PageMargin.normal:
        return const pw.EdgeInsets.all(48);
    }
  }

  PdfColor _hexToPdfColor(String hex) {
    var s = hex.replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    final value = int.parse(s, radix: 16);
    return PdfColor.fromInt(value);
  }
}
