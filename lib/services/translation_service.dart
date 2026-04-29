import '../utils/roman_urdu_map.dart';

class TranslationService {
  /// Synchronous, offline transliteration. Applies digraphs, then per-character
  /// mappings, with shadda-aware doubling.
  String transliterateToRoman(String urduText) {
    if (urduText.isEmpty) return '';

    var text = urduText;

    // Strip digraphs first (multi-character → roman).
    RomanUrduMap.digraphs.forEach((urdu, roman) {
      text = text.replaceAll(urdu, '$roman');
    });

    final out = StringBuffer();
    final units = text.runes.toList();
    String? previousRoman;

    for (var i = 0; i < units.length; i++) {
      final ch = String.fromCharCode(units[i]);

      if (ch == '') continue;

      // Shadda doubles the previous consonant.
      if (ch == 'ّ') {
        if (previousRoman != null && previousRoman.isNotEmpty) {
          out.write(previousRoman[previousRoman.length - 1]);
        }
        continue;
      }

      // Diacritic / harakat.
      final dia = RomanUrduMap.diacritics[ch];
      if (dia != null) {
        out.write(dia);
        if (dia.isNotEmpty) previousRoman = dia;
        continue;
      }

      // Punctuation.
      final punct = RomanUrduMap.punctuation[ch];
      if (punct != null) {
        out.write(punct);
        previousRoman = null;
        continue;
      }

      // Digits.
      final digit = RomanUrduMap.digits[ch];
      if (digit != null) {
        out.write(digit);
        previousRoman = digit;
        continue;
      }

      // Letter map.
      final letter = RomanUrduMap.letters[ch];
      if (letter != null) {
        out.write(letter);
        previousRoman = letter;
        continue;
      }

      // Pass-through (latin letters, whitespace, unknown punctuation).
      out.write(ch);
      previousRoman = ch;
    }

    return _tidy(out.toString());
  }

  String _tidy(String s) {
    var t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAll(RegExp(r" {2,}"), ' ');
    t = t.replaceAllMapped(RegExp(r'^([a-z])', multiLine: true), (m) {
      return m.group(1)!.toUpperCase();
    });
    return t;
  }

  /// Cloud fallback. Wire this to a translation/transliteration API if needed.
  /// Returns the local result by default.
  Future<String> translateViaApi(String urduText) async {
    return transliterateToRoman(urduText);
  }
}
