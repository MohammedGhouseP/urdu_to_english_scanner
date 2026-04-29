import 'package:uuid/uuid.dart';

import 'scanned_page_model.dart';

class PageTheme {
  const PageTheme({
    required this.id,
    required this.name,
    required this.backgroundColorHex,
    required this.textColorHex,
    required this.headingColorHex,
    required this.borderColorHex,
    this.fontFamily = 'Source Serif 4',
    this.headingFontFamily = 'Playfair Display',
  });

  final String id;
  final String name;
  final String backgroundColorHex;
  final String textColorHex;
  final String headingColorHex;
  final String borderColorHex;
  final String fontFamily;
  final String headingFontFamily;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'backgroundColorHex': backgroundColorHex,
        'textColorHex': textColorHex,
        'headingColorHex': headingColorHex,
        'borderColorHex': borderColorHex,
        'fontFamily': fontFamily,
        'headingFontFamily': headingFontFamily,
      };

  factory PageTheme.fromJson(Map<String, dynamic> json) => PageTheme(
        id: json['id'] as String? ?? 'classic',
        name: json['name'] as String? ?? 'Classic',
        backgroundColorHex: json['backgroundColorHex'] as String? ?? '#FFF8E7',
        textColorHex: json['textColorHex'] as String? ?? '#1B1B1B',
        headingColorHex: json['headingColorHex'] as String? ?? '#0E2A47',
        borderColorHex: json['borderColorHex'] as String? ?? '#C9A24A',
        fontFamily: json['fontFamily'] as String? ?? 'Source Serif 4',
        headingFontFamily: json['headingFontFamily'] as String? ?? 'Playfair Display',
      );

  static const PageTheme defaultTheme = PageTheme(
    id: 'classic-ivory',
    name: 'Classic Ivory',
    backgroundColorHex: '#FFF8E7',
    textColorHex: '#1B1B1B',
    headingColorHex: '#0E2A47',
    borderColorHex: '#C9A24A',
  );
}

enum PageColumns { single, double }

PageColumns _columnsFromString(String? s) =>
    s == 'double' ? PageColumns.double : PageColumns.single;

enum PageMargin { narrow, normal, wide }

PageMargin _marginFromString(String? s) {
  switch (s) {
    case 'narrow':
      return PageMargin.narrow;
    case 'wide':
      return PageMargin.wide;
    default:
      return PageMargin.normal;
  }
}

class PageLayout {
  const PageLayout({
    this.columns = PageColumns.single,
    this.margin = PageMargin.normal,
    this.showHeader = false,
    this.showFooter = true,
    this.showPageNumbers = true,
  });

  final PageColumns columns;
  final PageMargin margin;
  final bool showHeader;
  final bool showFooter;
  final bool showPageNumbers;

  PageLayout copyWith({
    PageColumns? columns,
    PageMargin? margin,
    bool? showHeader,
    bool? showFooter,
    bool? showPageNumbers,
  }) =>
      PageLayout(
        columns: columns ?? this.columns,
        margin: margin ?? this.margin,
        showHeader: showHeader ?? this.showHeader,
        showFooter: showFooter ?? this.showFooter,
        showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      );

  Map<String, dynamic> toJson() => {
        'columns': columns.name,
        'margin': margin.name,
        'showHeader': showHeader,
        'showFooter': showFooter,
        'showPageNumbers': showPageNumbers,
      };

  factory PageLayout.fromJson(Map<String, dynamic> json) => PageLayout(
        columns: _columnsFromString(json['columns'] as String?),
        margin: _marginFromString(json['margin'] as String?),
        showHeader: json['showHeader'] as bool? ?? false,
        showFooter: json['showFooter'] as bool? ?? true,
        showPageNumbers: json['showPageNumbers'] as bool? ?? true,
      );
}

class ExportSettings {
  const ExportSettings({
    this.pageSize = 'A4',
    this.dpi = 300,
    this.includeCover = true,
    this.includeTableOfContents = false,
    this.includePageNumbers = true,
  });

  final String pageSize;
  final int dpi;
  final bool includeCover;
  final bool includeTableOfContents;
  final bool includePageNumbers;

  ExportSettings copyWith({
    String? pageSize,
    int? dpi,
    bool? includeCover,
    bool? includeTableOfContents,
    bool? includePageNumbers,
  }) =>
      ExportSettings(
        pageSize: pageSize ?? this.pageSize,
        dpi: dpi ?? this.dpi,
        includeCover: includeCover ?? this.includeCover,
        includeTableOfContents:
            includeTableOfContents ?? this.includeTableOfContents,
        includePageNumbers: includePageNumbers ?? this.includePageNumbers,
      );

  Map<String, dynamic> toJson() => {
        'pageSize': pageSize,
        'dpi': dpi,
        'includeCover': includeCover,
        'includeTableOfContents': includeTableOfContents,
        'includePageNumbers': includePageNumbers,
      };

  factory ExportSettings.fromJson(Map<String, dynamic> json) => ExportSettings(
        pageSize: json['pageSize'] as String? ?? 'A4',
        dpi: json['dpi'] as int? ?? 300,
        includeCover: json['includeCover'] as bool? ?? true,
        includeTableOfContents:
            json['includeTableOfContents'] as bool? ?? false,
        includePageNumbers: json['includePageNumbers'] as bool? ?? true,
      );
}

class Project {
  Project({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? lastModified,
    List<ScannedPage>? pages,
    this.appliedTheme = PageTheme.defaultTheme,
    this.layout = const PageLayout(),
    this.exportSettings = const ExportSettings(),
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now(),
        pages = pages ?? <ScannedPage>[];

  final String id;
  String name;
  DateTime createdAt;
  DateTime lastModified;
  List<ScannedPage> pages;
  PageTheme appliedTheme;
  PageLayout layout;
  ExportSettings exportSettings;

  int get approvedPageCount => pages.where((p) => p.isApproved).length;
  int get totalPageCount => pages.length;
  double get completionRatio =>
      totalPageCount == 0 ? 0.0 : approvedPageCount / totalPageCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'pages': pages.map((p) => p.toJson()).toList(),
        'appliedTheme': appliedTheme.toJson(),
        'layout': layout.toJson(),
        'exportSettings': exportSettings.toJson(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Untitled',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        lastModified:
            DateTime.tryParse(json['lastModified'] as String? ?? '') ??
                DateTime.now(),
        pages: (json['pages'] as List<dynamic>? ?? [])
            .map((e) => ScannedPage.fromJson(e as Map<String, dynamic>))
            .toList(),
        appliedTheme: json['appliedTheme'] is Map<String, dynamic>
            ? PageTheme.fromJson(json['appliedTheme'] as Map<String, dynamic>)
            : PageTheme.defaultTheme,
        layout: json['layout'] is Map<String, dynamic>
            ? PageLayout.fromJson(json['layout'] as Map<String, dynamic>)
            : const PageLayout(),
        exportSettings: json['exportSettings'] is Map<String, dynamic>
            ? ExportSettings.fromJson(
                json['exportSettings'] as Map<String, dynamic>)
            : const ExportSettings(),
      );
}
