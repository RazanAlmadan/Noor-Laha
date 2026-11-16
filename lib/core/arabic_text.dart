// Small helpers for Arabic text.

// Removes diacritics, tatweel and dagger alef, and unifies some letter forms.
// Used for SEARCH only, never to change the displayed Quran text.
String normalizeArabic(String s) {
  final StringBuffer b = StringBuffer();
  for (final int c in s.runes) {
    final bool isMark = (c >= 0x064B && c <= 0x065F) || // harakat
        c == 0x0670 || // dagger alef
        c == 0x0640 || // tatweel
        (c >= 0x06D6 && c <= 0x06ED); // Quranic marks
    if (isMark) continue;

    switch (c) {
      case 0x0622: // آ
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0671: // ٱ
        b.writeCharCode(0x0627); // ا
      case 0x0649: // ى
        b.writeCharCode(0x064A); // ي
      case 0x0629: // ة
        b.writeCharCode(0x0647); // ه
      default:
        b.writeCharCode(c);
    }
  }
  return b.toString();
}

// Converts 123 to ١٢٣ (Arabic-Indic digits).
String toArabicDigits(int number) {
  const List<String> digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number.toString().split('').map((d) => digits[int.parse(d)]).join();
}