# Urdu to English Scanner

A Flutter tool app for book owners/publishers to scan Urdu pages, OCR them, transliterate to Roman English, edit, design pages, and export PDF.

## First-time setup

This repo ships with `lib/`, `pubspec.yaml`, and assets, but **not** the platform runner directories (`android/`, `ios/`, `windows/`). Generate them once:

```bash
flutter --version          # Flutter SDK >= 3.10 required
flutter create .           # populates android/ ios/ windows/ etc. — preserves lib/
flutter pub get
flutter run
```

## Known limitations (v0.1.0)

| Area | Limitation | Workaround |
| --- | --- | --- |
| **OCR** | `google_mlkit_text_recognition` does **not** support Arabic/Urdu script (only Latin / Chinese / Devanagari / Japanese / Korean). The current `OcrService` uses Latin recognition as a placeholder. | Swap `OcrService` to `flutter_tesseract_ocr` with `urd.traineddata`, or use Google Cloud Vision / Azure OCR. The service interface is small and pluggable. |
| **Camera live preview + edge detection** | Dropped in favor of `image_picker` (system camera + gallery), which is cross-platform and reliable. | Add the `camera` package + custom edge-detection overlay later if desired. |
| **`image_cropper` Android setup** | Requires `<activity android:name="com.yalantis.ucrop.UCropActivity" .../>` in `AndroidManifest.xml`. | Add it after `flutter create .`. See [package docs](https://pub.dev/packages/image_cropper#android). |
| **Persistence** | Projects are stored as JSON files under app docs dir. No Hive yet. | Swap to Hive boxes when projects exceed ~hundreds. |
| **Roman Urdu transliteration** | Character-map based. Lossy on context-dependent letters (و, ی, ہ). | `TranslationService.translateViaApi` is a stub for a cloud fallback. |

## Project structure

```
lib/
├── main.dart
├── models/         # Project, ScannedPage, TextBlock
├── screens/        # Home, Scanner, OcrPreview, Editor, PageDesigner, Export, ProjectManager
├── widgets/        # Reusable UI pieces
├── services/       # OCR, transliteration, PDF export, storage
├── utils/          # Theme, Roman Urdu map
└── data/           # Color theme presets
assets/
├── scanned_pages/  # User scans saved here at runtime
└── exported_pdfs/  # Final exports saved here at runtime
```

## What's wired in v0.1.0

- ✅ Home, Scanner, OCR Preview, Editor — full flow
- ✅ Image picker (camera + gallery)
- ✅ OCR pipeline (Latin placeholder; see limitations above)
- ✅ Roman Urdu transliteration map
- ✅ Editable text blocks (reorder, delete, merge, split, edit)
- ✅ Local JSON persistence
- 🟡 Page Designer — stub UI (color theme list works; layout controls TODO)
- 🟡 Export — stub UI (PDF export service is wired; UI controls TODO)
- 🟡 Project Manager — stub (lists projects; rename/delete TODO)
