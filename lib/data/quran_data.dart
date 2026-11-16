import 'dart:convert';

import 'package:flutter/services.dart';

// A position in the Quran: surah number + ayah number (both start at 1).
class AyahRef {
  final int surah;
  final int ayah;

  const AyahRef(this.surah, this.ayah);

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);
}

// One surah with all of its ayahs (index 0 = ayah 1).
class Surah {
  final int number;
  final String name;
  final String transliteration;
  final String englishName;
  final String type; // 'meccan' or 'medinan'
  final int revelationOrder;
  final int ayahCount;
  final List<String> ayahs;

  const Surah({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.englishName,
    required this.type,
    required this.revelationOrder,
    required this.ayahCount,
    required this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      name: json['name'] as String,
      transliteration: json['transliteration'] as String,
      englishName: json['englishName'] as String,
      type: json['type'] as String,
      revelationOrder: json['revelationOrder'] as int,
      ayahCount: json['ayahCount'] as int,
      ayahs: (json['ayahs'] as List).cast<String>(),
    );
  }

  bool get isMeccan => type == 'meccan';

  // Al-Fatiha has the Basmala as a real ayah, and At-Tawba has none.
  bool get showsBasmalaHeader => number != 1 && number != 9;
}

// The whole Quran: the Basmala text, the 114 surahs, and page/juz starts.
class QuranData {
  final String basmala;
  final List<Surah> surahs;

  // pageStarts[0] is where page 1 begins, and so on (604 pages).
  final List<AyahRef> pageStarts;

  // juzStarts[0] is where juz 1 begins, and so on (30 juz).
  final List<AyahRef> juzStarts;

  // quarterStarts[0] is where the first hizb quarter begins (240 quarters).
  // It can be empty if the JSON was built without them.
  final List<AyahRef> quarterStarts;

  const QuranData({
    required this.basmala,
    required this.surahs,
    required this.pageStarts,
    required this.juzStarts,
    required this.quarterStarts,
  });

  factory QuranData.fromJson(Map<String, dynamic> json) {
    List<AyahRef> readRefs(String key) {
      final Object? raw = json[key];
      if (raw == null) return [];
      return (raw as List).map((e) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        return AyahRef(m['surah'] as int, m['ayah'] as int);
      }).toList();
    }

    return QuranData(
      basmala: json['basmala'] as String,
      surahs: (json['surahs'] as List)
          .map((s) => Surah.fromJson(s as Map<String, dynamic>))
          .toList(),
      pageStarts: readRefs('pageStarts'),
      juzStarts: readRefs('juzStarts'),
      quarterStarts: readRefs('quarterStarts'),
    );
  }

  int get pageCount => pageStarts.length;

  static bool _startsAtOrBefore(AyahRef start, int surah, int ayah) {
    return start.surah < surah || (start.surah == surah && start.ayah <= ayah);
  }

  // Index of the last start position that is at or before (surah, ayah).
  int _lastStartIndex(List<AyahRef> starts, int surah, int ayah) {
    int result = 0;
    for (int i = 0; i < starts.length; i++) {
      if (_startsAtOrBefore(starts[i], surah, ayah)) {
        result = i;
      } else {
        break;
      }
    }
    return result;
  }

  // Page number (1-based) that contains this ayah.
  int pageOf(int surah, int ayah) => _lastStartIndex(pageStarts, surah, ayah) + 1;

  // Juz number (1-based) that contains this ayah.
  int juzOf(int surah, int ayah) => _lastStartIndex(juzStarts, surah, ayah) + 1;

  // Hizb number (1-60) that contains this ayah, or null if we have no data.
  // Each hizb has 4 quarters, so we divide the quarter index by 4.
  int? hizbOf(int surah, int ayah) {
    if (quarterStarts.isEmpty) return null;
    return _lastStartIndex(quarterStarts, surah, ayah) ~/ 4 + 1;
  }

  // All ayahs on a page (1-based), in reading order.
  List<AyahRef> ayahsOfPage(int page) {
    final AyahRef start = pageStarts[page - 1];
    final AyahRef? next = page < pageStarts.length ? pageStarts[page] : null;

    final List<AyahRef> result = [];
    int s = start.surah;
    int a = start.ayah;

    while (s <= surahs.length) {
      if (next != null && s == next.surah && a == next.ayah) break;
      result.add(AyahRef(s, a));

      // Move to the next ayah, or to the first ayah of the next surah.
      if (a < surahs[s - 1].ayahCount) {
        a++;
      } else {
        s++;
        a = 1;
      }
    }
    return result;
  }
}

// Loads assets/data/quran.json once and keeps it in memory.
class QuranRepository {
  QuranRepository._();

  static final QuranRepository instance = QuranRepository._();

  Future<QuranData>? _future;

  // The first call reads the file; later calls reuse the same result.
  Future<QuranData> load() => _future ??= _read();

  Future<QuranData> _read() async {
    final String raw = await rootBundle.loadString('assets/data/quran.json');
    return QuranData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}