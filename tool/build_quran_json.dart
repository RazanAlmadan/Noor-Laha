// ignore_for_file: avoid_print
//
// One-time tool: converts the Tanzil text file and the Tanzil metadata file
// into a single assets/data/quran.json used by the app.
//
// Run it from the project root:
//   dart run tool/build_quran_json.dart
//
// The ayah text is copied verbatim. The only thing we do is split the
// Basmala out of the first ayah of each surah (Tanzil puts it inside the
// first ayah), so the app can show it as a separate header.

import 'dart:convert';
import 'dart:io';

const String textPath = 'tool/data/quran-uthmani.txt';
const String metaPath = 'tool/data/quran-data.xml';
const String outPath = 'assets/data/quran.json';

// Removes diacritics, tatweel and dagger alef, and turns alef wasla into a
// plain alef. Used only to COMPARE words, never to change the stored text.
String normalizeArabic(String s) {
  final StringBuffer b = StringBuffer();
  for (final int c in s.runes) {
    final bool isMark = (c >= 0x064B && c <= 0x065F) || // harakat
        c == 0x0670 || // dagger alef
        c == 0x0640 || // tatweel
        (c >= 0x06D6 && c <= 0x06ED); // Quranic marks
    if (isMark) continue;
    b.writeCharCode(c == 0x0671 ? 0x0627 : c); // alef wasla -> alef
  }
  return b.toString();
}

// The four words of the Basmala without any marks.
const List<String> basmalaWords = ['بسم', 'الله', 'الرحمن', 'الرحيم'];

// If the text starts with the Basmala (compared without marks), returns the
// rest of the text. Otherwise returns null.
String? removeBasmalaPrefix(String text) {
  final List<String> words = text.split(' ');
  if (words.length <= basmalaWords.length) return null;

  for (int i = 0; i < basmalaWords.length; i++) {
    if (normalizeArabic(words[i]) != basmalaWords[i]) return null;
  }
  return words.sublist(basmalaWords.length).join(' ');
}

void main() {
  final List<String> lines = File(textPath).readAsLinesSync();

  // ayahsBySurah[surah] = list of ayah texts (index 0 = ayah 1).
  final Map<int, List<String>> ayahsBySurah = {};

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i];
    // Remove a possible BOM at the start of the file.
    if (i == 0 && line.startsWith('\uFEFF')) line = line.substring(1);
    line = line.trim();

    // Skip empty lines and the copyright comment block.
    if (line.isEmpty || line.startsWith('#')) continue;

    // Format: surah|ayah|text   (the text itself never contains '|').
    final int first = line.indexOf('|');
    final int second = line.indexOf('|', first + 1);
    if (first < 0 || second < 0) {
      throw FormatException('Bad line ${i + 1}: $line');
    }

    final int surah = int.parse(line.substring(0, first));
    final int ayah = int.parse(line.substring(first + 1, second));
    final String text = line.substring(second + 1).trim();

    final List<String> list = ayahsBySurah.putIfAbsent(surah, () => []);
    // Ayahs must arrive in order: 1, 2, 3 ...
    if (ayah != list.length + 1) {
      throw FormatException(
        'Unexpected ayah order at surah $surah: got $ayah, '
            'expected ${list.length + 1}',
      );
    }
    list.add(text);
  }

  // The Basmala is ayah 1 of Al-Fatiha, so we take its exact text from there.
  final String basmala = ayahsBySurah[1]![0];

  // Split the Basmala out of the first ayah of every surah except
  // Al-Fatiha (1, where it is a real ayah) and At-Tawba (9, no Basmala).
  int stripped = 0;
  for (int s = 2; s <= 114; s++) {
    if (s == 9) continue;
    final String? rest = removeBasmalaPrefix(ayahsBySurah[s]![0]);
    if (rest == null || rest.trim().isEmpty) {
      print('WARNING: surah $s ayah 1 does not start with the Basmala.');
      continue;
    }
    ayahsBySurah[s]![0] = rest.trim();
    stripped++;
  }
  print('Basmala split from $stripped surahs (expected 112).');

  // ---- Metadata (XML) ----
  final String xml = File(metaPath).readAsStringSync();

  // Reads attributes like name="value" from the inside of one XML tag.
  Map<String, String> attrs(String tagInner) {
    final Map<String, String> map = {};
    for (final m in RegExp(r'(\w+)="([^"]*)"').allMatches(tagInner)) {
      map[m.group(1)!] = m.group(2)!;
    }
    return map;
  }

  final List<Map<String, String>> suraMeta = RegExp(r'<sura\s+([^>]*?)/>')
      .allMatches(xml)
      .map((m) => attrs(m.group(1)!))
      .toList();

  // Juz and page start positions (optional: used for navigation later).
  List<Map<String, int>> starts(String tag) {
    return RegExp('<$tag\\s+([^>]*?)/>').allMatches(xml).map((m) {
      final a = attrs(m.group(1)!);
      return {
        'index': int.parse(a['index']!),
        'surah': int.parse(a['sura']!),
        'ayah': int.parse(a['aya']!),
      };
    }).toList();
  }

  final List<Map<String, int>> juzStarts = starts('juz');
  final List<Map<String, int>> pageStarts = starts('page');

  // Hizb quarters (240 of them): used to show the hizb number.
  final List<Map<String, int>> quarterStarts = starts('quarter');
  if (quarterStarts.length != 240) {
    print('WARNING: expected 240 quarters, found ${quarterStarts.length}.');
  }

  // ---- Validation ----
  if (suraMeta.length != 114) {
    throw StateError('Expected 114 surahs in metadata, got ${suraMeta.length}');
  }

  int total = 0;
  final List<Map<String, Object>> surahs = [];

  for (final Map<String, String> meta in suraMeta) {
    final int number = int.parse(meta['index']!);
    final int expected = int.parse(meta['ayas']!);
    final List<String> ayahs = ayahsBySurah[number]!;

    if (ayahs.length != expected) {
      throw StateError(
        'Surah $number: metadata says $expected ayahs, text has ${ayahs.length}',
      );
    }
    if (ayahs.any((a) => a.isEmpty)) {
      throw StateError('Surah $number has an empty ayah');
    }
    total += ayahs.length;

    surahs.add({
      'number': number,
      'name': meta['name']!,
      'transliteration': meta['tname']!,
      'englishName': meta['ename']!,
      'type': meta['type']!.toLowerCase(), // meccan / medinan
      'revelationOrder': int.parse(meta['order']!),
      'ayahCount': expected,
      'ayahs': ayahs,
    });
  }

  if (total != 6236) {
    throw StateError('Expected 6236 ayahs in total, got $total');
  }

  // ---- Output ----
  final Map<String, Object> output = {
    'source': 'Tanzil Project (tanzil.net) - Uthmani text v1.1 - CC BY 3.0',
    'basmala': basmala,
    'surahs': surahs,
    'juzStarts': juzStarts,
    'pageStarts': pageStarts,
    'quarterStarts': quarterStarts,
  };

  final File out = File(outPath);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(jsonEncode(output));

  print('OK: $total ayahs, ${surahs.length} surahs, '
      '${juzStarts.length} juz marks, ${pageStarts.length} page marks.');
  print('Written to $outPath (${out.lengthSync()} bytes).');
}