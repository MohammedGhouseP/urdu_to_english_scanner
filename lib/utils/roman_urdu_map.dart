/// Lossy character-level Urdu → Roman English transliteration.
///
/// This map favors readability over scholarly accuracy. Context-dependent
/// letters (و, ی, ہ, ع) cannot be perfectly disambiguated from a per-glyph map;
/// we pick the most common rendering and let users hand-correct in the editor.
///
/// To plug in a higher-quality transliteration (context-aware rules or an API),
/// override `TranslationService.transliterateToRoman`.
class RomanUrduMap {
  static const Map<String, String> letters = {
    // Hamza family
    'ء': "'",
    'آ': 'aa',
    'أ': 'a',
    'ؤ': 'o',
    'ئ': 'i',
    // Alif family
    'ا': 'a',
    // Beh family
    'ب': 'b',
    'پ': 'p',
    'ت': 't',
    'ٹ': 'T',
    'ث': 's',
    // Jeem family
    'ج': 'j',
    'چ': 'ch',
    'ح': 'h',
    'خ': 'kh',
    // Dal family
    'د': 'd',
    'ڈ': 'D',
    'ذ': 'z',
    // Reh family
    'ر': 'r',
    'ڑ': 'R',
    'ز': 'z',
    'ژ': 'zh',
    // Seen family
    'س': 's',
    'ش': 'sh',
    'ص': 's',
    'ض': 'z',
    // Toe family
    'ط': 't',
    'ظ': 'z',
    // Ain family
    'ع': "'",
    'غ': 'gh',
    // Feh family
    'ف': 'f',
    'ق': 'q',
    // Kaaf family
    'ک': 'k',
    'ك': 'k',
    'گ': 'g',
    // Lam, meem, noon
    'ل': 'l',
    'م': 'm',
    'ن': 'n',
    'ں': 'n',
    // Waw family
    'و': 'o',
    // Heh family
    'ہ': 'h',
    'ھ': 'h',
    'ۂ': 'h',
    'ۃ': 'h',
    'ة': 'h',
    // Yeh family
    'ی': 'i',
    'ي': 'i',
    'ے': 'e',
    'ى': 'a',
  };

  /// Diacritics (harakat). Most are dropped or mapped to their vowel.
  static const Map<String, String> diacritics = {
    'َ': 'a', // fatha (zabar)
    'ُ': 'u', // damma (pesh)
    'ِ': 'i', // kasra (zair)
    'ّ': '', // shadda (tashdid) — handled by doubling, see transliterate()
    'ْ': '', // sukun
    'ً': 'an', // tanwin fatha
    'ٌ': 'un', // tanwin damma
    'ٍ': 'in', // tanwin kasra
    'ٰ': 'a', // alif khanjariya
    'ۖ': '',
    'ۗ': '',
    'ۘ': '',
    'ۙ': '',
    'ۚ': '',
    'ۛ': '',
    'ۜ': '',
    '۟': '',
    '۠': '',
    'ۡ': '',
    'ۢ': '',
    'ۣ': '',
    'ۤ': '',
    'ۥ': '',
    'ۦ': '',
    'ۧ': '',
    'ۨ': '',
    '۪': '',
    '۫': '',
    '۬': '',
    'ۭ': '',
  };

  /// Common multi-character substitutions applied first. These catch a few
  /// frequent letter sequences that map better as a unit than letter-by-letter.
  static const Map<String, String> digraphs = {
    'بھ': 'bh',
    'پھ': 'ph',
    'تھ': 'th',
    'ٹھ': 'Th',
    'جھ': 'jh',
    'چھ': 'chh',
    'دھ': 'dh',
    'ڈھ': 'Dh',
    'کھ': 'kh',
    'گھ': 'gh',
    'لھ': 'lh',
    'مھ': 'mh',
    'نھ': 'nh',
    'رھ': 'rh',
    'ڑھ': 'Rh',
  };

  /// Punctuation translation.
  static const Map<String, String> punctuation = {
    '۔': '.',
    '،': ',',
    '؛': ';',
    '؟': '?',
    '٪': '%',
    '٬': ',',
    '٫': '.',
  };

  /// Indic / Arabic digits → ASCII.
  static const Map<String, String> digits = {
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  };
}
