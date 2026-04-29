import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/ocr_service.dart';
import 'services/pdf_export_service.dart';
import 'services/storage_service.dart';
import 'services/translation_service.dart';
import 'state/project_store.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const UrduScannerApp());
}

class UrduScannerApp extends StatelessWidget {
  const UrduScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<OcrService>(
          create: (_) => OcrService(),
          dispose: (_, s) => s.dispose(),
        ),
        Provider<TranslationService>(create: (_) => TranslationService()),
        Provider<PdfExportService>(create: (_) => PdfExportService()),
        ChangeNotifierProvider<ProjectStore>(
          create: (_) => ProjectStore(storage)..loadAll(),
        ),
      ],
      child: MaterialApp(
        title: 'Urdu to English Scanner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
