import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _wirdKey = 'wird';

// Number of pages in the mushaf (the same as the page data of the app).
const int kMushafPages = 604;

// How the daily portion of a khatma is measured.
enum WirdUnit { pages, juz, hizb }

// 60 days is one hizb a day. Durations that divide 30 evenly (30, 15, 10,
// 6, 5, 3, 2, 1) are whole juz a day. Anything else is measured in pages.
WirdUnit wirdUnitForDays(int days) {
  if (days == 60) return WirdUnit.hizb;
  if (days >= 1 && days <= 30 && 30 % days == 0) return WirdUnit.juz;
  return WirdUnit.pages;
}

// The page where each juz starts (built from the app's own Quran data).
const List<int> _kJuzStartPages = [
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
  201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
  402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
];

// Juz that start in the middle of a page (the page is shared with the
// end of the juz before it).
const Set<int> _kJuzMidPages = {62, 121, 201, 502};

// The page where each hizb starts.
const List<int> _kHizbStartPages = [
  1, 11, 22, 32, 42, 51, 62, 72, 82, 92,
  102, 112, 121, 132, 142, 151, 162, 173, 182, 192,
  201, 212, 222, 231, 242, 252, 262, 272, 282, 292,
  302, 312, 322, 332, 342, 352, 362, 371, 382, 392,
  402, 413, 422, 431, 442, 451, 462, 472, 482, 491,
  502, 513, 522, 531, 542, 553, 562, 572, 582, 591,
];

const Set<int> _kHizbMidPages = {
  11, 51, 62, 72, 92, 112, 121, 192, 201, 231, 272, 292, 312, 371, 413, //
  431, 451, 491, 502, 513, 531, 591,
};

List<int> _startsOf(WirdUnit unit) =>
    unit == WirdUnit.juz ? _kJuzStartPages : _kHizbStartPages;

Set<int> _midOf(WirdUnit unit) =>
    unit == WirdUnit.juz ? _kJuzMidPages : _kHizbMidPages;

// The last page of unit number [k] (0-based), and whether the next unit
// starts in the middle of that same page.
({int page, bool shared}) _unitEnd(WirdUnit unit, int k) {
  final List<int> starts = _startsOf(unit);
  if (k == starts.length - 1) return (page: kMushafPages, shared: false);

  final int nextStart = starts[k + 1];
  final bool shared = _midOf(unit).contains(nextStart);
  return (page: shared ? nextStart : nextStart - 1, shared: shared);
}

// Where every unit ends, as positions of the wird, in order.
List<({int endPos, bool shared})> _unitEnds(Wird wird) {
  final WirdUnit unit = wird.unit;
  if (unit == WirdUnit.pages) return const [];

  final List<({int endPos, bool shared})> ends = [];
  for (int k = 0; k < _startsOf(unit).length; k++) {
    final ({int page, bool shared}) end = _unitEnd(unit, k);
    ends.add((endPos: wird.posOf(end.page), shared: end.shared));
  }
  ends.sort((a, b) => a.endPos.compareTo(b.endPos));
  return ends;
}

// The two kinds of wird for now. Later we add "selected surahs" and "custom".
enum WirdType {
  khatma, // Finish the Quran in a chosen number of days
  fixedPages, // A fixed number of pages every day
}

int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;

// ---------- Dates ----------

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

// "2026-11-18": the day of a wird portion.
String _keyOf(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

DateTime? _parseKey(String key) {
  final List<String> parts = key.split('-');
  if (parts.length != 3) return null;
  final int? y = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  final int? d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime.utc(y, m, d);
}

// ---------- The wird ----------

// The wird works with "positions": 0 is the page where the wird started and
// 603 is the last page of one full khatma. When the wird starts in the middle
// of the Quran, the positions wrap around, so the khatma is still complete.
class Wird {
  final WirdType type;
  final int startPage; // 1..604, where the wird began
  final int durationDays; // khatma only: the chosen number of days
  final String endDay; // khatma only: the planned last day
  final int pagesPerDay; // fixedPages only: the chosen number of pages

  // Today's portion: [dayStartPos, dayStartPos + dayCount).
  final String dayKey;
  final int dayStartPos;
  final int dayCount;

  // Positions read today, and the ones added by the "completed" button
  // (so the button can be undone without losing the pages read for real).
  final Set<int> done;
  final Set<int> manual;
  // Unread pages of the previous portion, to tell the user once
  // when the app opens (0 means there is nothing to tell).
  final int missedPages;

  const Wird({
    required this.type,
    required this.startPage,
    required this.durationDays,
    required this.endDay,
    required this.pagesPerDay,
    required this.dayKey,
    required this.dayStartPos,
    required this.dayCount,
    required this.done,
    required this.manual,
    this.missedPages = 0,
  });

  Wird copyWith({
    String? dayKey,
    int? dayStartPos,
    int? dayCount,
    Set<int>? done,
    Set<int>? manual,
    int? missedPages,
  }) {
    return Wird(
      type: type,
      startPage: startPage,
      durationDays: durationDays,
      endDay: endDay,
      pagesPerDay: pagesPerDay,
      dayKey: dayKey ?? this.dayKey,
      dayStartPos: dayStartPos ?? this.dayStartPos,
      dayCount: dayCount ?? this.dayCount,
      done: done ?? this.done,
      manual: manual ?? this.manual,
      missedPages: missedPages ?? this.missedPages,
    );
  }

  // ---------- Pages and positions ----------

  int pageAt(int pos) => (startPage - 1 + pos) % kMushafPages + 1;

  int posOf(int page) => (page - startPage + kMushafPages) % kMushafPages;

  List<int> get dayPositions => [
    for (int i = 0; i < dayCount; i++) dayStartPos + i,
  ];

  int get firstPage => pageAt(dayStartPos);

  int get lastPage => pageAt(dayStartPos + dayCount - 1);

  // The first page of today's portion that was not read yet.
  int? get firstUndonePage {
    for (final int pos in dayPositions) {
      if (!done.contains(pos)) return pageAt(pos);
    }
    return null;
  }

  // ---------- Progress ----------

  int get doneCount => done.length;

  bool get todayComplete => doneCount >= dayCount;

  double get todayFraction =>
      dayCount == 0 ? 0 : (doneCount / dayCount).clamp(0.0, 1.0).toDouble();

  // True when today's portion is the last one and it is finished.
  bool get isKhatmaComplete =>
      dayStartPos + dayCount >= kMushafPages && todayComplete;

  int get pagesReadTotal =>
      isKhatmaComplete ? kMushafPages : dayStartPos + doneCount;

  double get khatmaFraction =>
      (pagesReadTotal / kMushafPages).clamp(0.0, 1.0).toDouble();

  bool get canUndo => manual.isNotEmpty;

  // How this wird is measured: pages, juz or hizb.
  WirdUnit get unit =>
      type == WirdType.khatma ? wirdUnitForDays(durationDays) : WirdUnit.pages;

  // True when today's portion ends on a page that the next portion shares
  // (the next juz or hizb starts in the middle of that page).
  bool get endsOnSharedPage {
    final int endPos = dayStartPos + dayCount - 1;
    for (final end in _unitEnds(this)) {
      if (end.endPos == endPos) return end.shared;
    }
    return false;
  }

  // The juz or hizb numbers (1-based) that today's portion covers, when it
  // covers whole units. Null otherwise.
  ({WirdUnit unit, int first, int last})? get unitSpan {
    if (unit == WirdUnit.pages) return null;

    final List<int> starts = _startsOf(unit);
    final int first = starts.indexOf(firstPage);
    if (first < 0) return null;

    for (int k = first; k < starts.length; k++) {
      final int endPage = _unitEnd(unit, k).page;
      if (endPage == lastPage) {
        return (unit: unit, first: first + 1, last: k + 1);
      }
      if (endPage > lastPage) break;
    }
    return null;
  }

  // ---------- Dates ----------

  // The last day of the wird (khatma) or the expected last day (fixed pages).
  DateTime? plannedEnd(DateTime now) {
    if (type == WirdType.khatma) return _parseKey(endDay);

    final int remaining = kMushafPages - dayStartPos;
    final int days = _ceilDiv(remaining, math.max(1, pagesPerDay));
    return _dateOnly(now).add(Duration(days: days - 1));
  }

  // Days left including today (never below 0). Null for fixed pages.
  int? daysLeft(DateTime now) {
    final DateTime? end = plannedEnd(now);
    if (end == null) return null;
    return math.max(0, end.difference(_dateOnly(now)).inDays + 1);
  }

  // ---------- Saving ----------

  Map<String, Object> toJson() => {
    'type': type.index,
    'startPage': startPage,
    'durationDays': durationDays,
    'endDay': endDay,
    'pagesPerDay': pagesPerDay,
    'dayKey': dayKey,
    'dayStartPos': dayStartPos,
    'dayCount': dayCount,
    'done': done.toList(),
    'manual': manual.toList(),
    'missed': missedPages,
  };

  static Wird? fromJson(Object? json) {
    if (json is! Map) return null;

    int? readInt(String key) {
      final Object? value = json[key];
      return value is int ? value : null;
    }

    Set<int> readSet(String key) {
      final Object? value = json[key];
      return value is List ? value.whereType<int>().toSet() : <int>{};
    }

    final int? typeIndex = readInt('type');
    final int? startPage = readInt('startPage');
    final int? durationDays = readInt('durationDays');
    final int? pagesPerDay = readInt('pagesPerDay');
    final int? dayStartPos = readInt('dayStartPos');
    final int? dayCount = readInt('dayCount');
    final Object? endDay = json['endDay'];
    final Object? dayKey = json['dayKey'];

    if (typeIndex == null ||
        typeIndex < 0 ||
        typeIndex >= WirdType.values.length ||
        startPage == null ||
        startPage < 1 ||
        startPage > kMushafPages ||
        durationDays == null ||
        pagesPerDay == null ||
        dayStartPos == null ||
        dayStartPos < 0 ||
        dayStartPos >= kMushafPages ||
        dayCount == null ||
        dayCount < 1 ||
        dayCount > kMushafPages ||
        endDay is! String ||
        dayKey is! String) {
      return null;
    }

    return Wird(
      type: WirdType.values[typeIndex],
      startPage: startPage,
      durationDays: durationDays,
      endDay: endDay,
      pagesPerDay: pagesPerDay,
      dayKey: dayKey,
      dayStartPos: dayStartPos,
      dayCount: dayCount,
      done: readSet('done'),
      manual: readSet('manual'),
      missedPages: readInt('missed') ?? 0,
    );
  }
}

// ---------- State ----------

// Screens listen to this. It is null until the user creates a wird.
final ValueNotifier<Wird?> wirdNotifier = ValueNotifier<Wird?>(null);

void _setWird(Wird? wird) {
  // The screen updates first, the saving happens in the background.
  wirdNotifier.value = wird;
  unawaited(_persistWird());
}

Future<void> _persistWird() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final Wird? wird = wirdNotifier.value;
  if (wird == null) {
    await prefs.remove(_wirdKey);
  } else {
    await prefs.setString(_wirdKey, jsonEncode(wird.toJson()));
  }
}

// How many pages today's portion has, when it starts at [startPos].
int _dayCountFor(Wird wird, int startPos, DateTime now) {
  final int remaining = kMushafPages - startPos;

  switch (wird.type) {
    case WirdType.fixedPages:
      return math.min(remaining, math.max(1, wird.pagesPerDay));

    case WirdType.khatma:
      final DateTime? end = _parseKey(wird.endDay);
      final int daysLeft =
      end == null ? 1 : end.difference(_dateOnly(now)).inDays + 1;

      final int pages;
      if (daysLeft < 1) {
        // Past the planned end: keep the normal pace instead of putting
        // everything that is left on a single day.
        pages = math.min(
          remaining,
          _ceilDiv(kMushafPages, math.max(1, wird.durationDays)),
        );
      } else {
        pages = math.min(remaining, _ceilDiv(remaining, daysLeft));
      }
      return _snappedToUnit(wird, startPos, pages);
  }
}

// In juz or hizb mode, moves the end of the portion to the nearest end of a
// unit, so the wird stops at a familiar place. In pages mode nothing changes.
int _snappedToUnit(Wird wird, int startPos, int pages) {
  if (wird.unit == WirdUnit.pages) return pages;

  const int lastPos = kMushafPages - 1;
  final int target = math.min(startPos + pages - 1, lastPos);

  // The end of the Quran is always a possible end.
  int best = lastPos;
  int bestDistance = (lastPos - target).abs();

  for (final end in _unitEnds(wird)) {
    if (end.endPos < startPos) continue;
    // A unit that ends on the page we start from is the previous unit.
    if (end.shared && end.endPos == startPos) continue;

    final int distance = (end.endPos - target).abs();
    // On a tie, prefer the longer portion.
    if (distance < bestDistance ||
        (distance == bestDistance && end.endPos > best)) {
      best = end.endPos;
      bestDistance = distance;
    }
  }
  return best - startPos + 1;
}

// Moves the wird to today when a new day started. The new portion begins at
// the first page that was not read, so nothing is lost.
Wird _rolledToToday(Wird wird, DateTime now) {
  final String key = _keyOf(now);
  if (wird.dayKey == key || wird.isKhatmaComplete) return wird;

  // When everything was read, continue after the portion, or on its last
  // page if the next juz or hizb starts in the middle of that page.
  int next =
      wird.dayStartPos + wird.dayCount - (wird.endsOnSharedPage ? 1 : 0);
  for (final int pos in wird.dayPositions) {
    if (!wird.done.contains(pos)) {
      next = pos;
      break;
    }
  }

  // Days that passed with no reading at all (the day of the old portion and
  // today are not counted). Calendar days are compared in UTC so a daylight
  // saving change cannot shift the result.
  final DateTime? last = _parseKey(wird.dayKey);
  int skippedDays = 0;
  if (last != null) {
    final int gap = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(last.year, last.month, last.day))
        .inDays;
    skippedDays = math.max(0, gap - 1);
  }

  // Pages the user is behind: what was left of the old portion, plus one
  // portion for every day that was skipped completely. It can never be more
  // than what is left in the Quran.
  final int perDay =
  wird.type == WirdType.fixedPages ? wird.pagesPerDay : wird.dayCount;
  final int unreadOld = math.max(0, wird.dayCount - wird.done.length);
  final int missed = math.min(
    kMushafPages - next,
    unreadOld + skippedDays * math.max(1, perDay),
  );

  final Wird moved = wird.copyWith(
    dayKey: key,
    dayStartPos: next,
    done: <int>{},
    manual: <int>{},
    // Shown once in the notice, then cleared by dismissWirdNotice.
    missedPages: math.max(0, missed),
  );
  return moved.copyWith(dayCount: _dayCountFor(moved, next, now));
}

// Call when the app opens and when it comes back to the screen.
void refreshWirdDay() {
  final Wird? wird = wirdNotifier.value;
  if (wird == null) return;

  final Wird rolled = _rolledToToday(wird, DateTime.now());
  if (!identical(rolled, wird)) _setWird(rolled);
}

// Called when the user closes the "you missed part of your wird" notice.
void dismissWirdNotice() {
  final Wird? wird = wirdNotifier.value;
  if (wird == null || wird.missedPages == 0) return;

  _setWird(wird.copyWith(missedPages: 0));
}

// Creates a new wird. It replaces the current one.
void startWird({
  required WirdType type,
  required int startPage,
  int durationDays = 0,
  int pagesPerDay = 0,
}) {
  final DateTime now = DateTime.now();
  final DateTime today = _dateOnly(now);

  final Wird base = Wird(
    type: type,
    startPage: startPage,
    durationDays: durationDays,
    endDay: type == WirdType.khatma
        ? _keyOf(today.add(Duration(days: durationDays - 1)))
        : '',
    pagesPerDay: pagesPerDay,
    dayKey: _keyOf(now),
    dayStartPos: 0,
    dayCount: 1,
    done: const <int>{},
    manual: const <int>{},
  );

  _setWird(base.copyWith(dayCount: _dayCountFor(base, 0, now)));
}

void stopWird() => _setWird(null);

// Called by the reader when the user stayed on a page long enough.
// Only pages of today's portion count. Returns true if something changed.
bool markWirdPageRead(int page) {
  refreshWirdDay();

  final Wird? wird = wirdNotifier.value;
  if (wird == null) return false;

  final int pos = wird.posOf(page);
  final bool inToday =
      pos >= wird.dayStartPos && pos < wird.dayStartPos + wird.dayCount;
  if (!inToday || wird.done.contains(pos)) return false;

  _setWird(wird.copyWith(done: {...wird.done, pos}));
  return true;
}

// The manual "completed" button: marks the whole of today's portion as read.
void completeWirdToday() {
  refreshWirdDay();

  final Wird? wird = wirdNotifier.value;
  if (wird == null) return;

  final Set<int> added = {
    for (final int pos in wird.dayPositions)
      if (!wird.done.contains(pos)) pos,
  };
  if (added.isEmpty) return;

  _setWird(wird.copyWith(
    done: {...wird.done, ...added},
    manual: {...wird.manual, ...added},
  ));
}

// Takes back the "completed" button and keeps the pages read for real.
void undoCompleteWirdToday() {
  final Wird? wird = wirdNotifier.value;
  if (wird == null || wird.manual.isEmpty) return;

  _setWird(wird.copyWith(
    done: wird.done.difference(wird.manual),
    manual: <int>{},
  ));
}

// Call once before runApp to restore the saved wird.
Future<void> loadWird() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? raw = prefs.getString(_wirdKey);
  if (raw == null) return;

  try {
    final Wird? wird = Wird.fromJson(jsonDecode(raw));
    if (wird == null) return;

    final Wird rolled = _rolledToToday(wird, DateTime.now());
    wirdNotifier.value = rolled;
    if (!identical(rolled, wird)) unawaited(_persistWird());
  } on FormatException {
    // Damaged saved data: start clean instead of crashing the app.
  }
}