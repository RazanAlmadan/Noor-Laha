import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quran_data.dart';

// The last reading position: the first ayah of the page the user was on.
class LastRead {
  final AyahRef ref;
  final int page; // 1-based

  const LastRead(this.ref, this.page);
}

const String _favoriteSurahsKey = 'favorite_surahs';
const String _bookmarksKey = 'bookmarks';
const String _lastReadKey = 'last_read';

// Surah numbers the user added to favorites.
final ValueNotifier<Set<int>> favoriteSurahsNotifier =
ValueNotifier<Set<int>>(<int>{});

// Bookmarked ayahs, oldest first.
final ValueNotifier<List<AyahRef>> bookmarksNotifier =
ValueNotifier<List<AyahRef>>(<AyahRef>[]);

// Where the user stopped reading (null until the first reading).
final ValueNotifier<LastRead?> lastReadNotifier = ValueNotifier<LastRead?>(null);

// Reads "surah:ayah" back into an AyahRef (null if the text is not valid).
AyahRef? _parseRef(String text) {
  final List<String> parts = text.split(':');
  if (parts.length < 2) return null;

  final int? surah = int.tryParse(parts[0]);
  final int? ayah = int.tryParse(parts[1]);
  if (surah == null || ayah == null) return null;

  return AyahRef(surah, ayah);
}

String _refToText(AyahRef ref) => '${ref.surah}:${ref.ayah}';

// Call once before runApp to restore everything that was saved.
Future<void> loadSavedItems() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  favoriteSurahsNotifier.value =
      (prefs.getStringList(_favoriteSurahsKey) ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

  bookmarksNotifier.value =
      (prefs.getStringList(_bookmarksKey) ?? const <String>[])
          .map(_parseRef)
          .whereType<AyahRef>()
          .toList();

  final String? raw = prefs.getString(_lastReadKey);
  if (raw != null) {
    final List<String> parts = raw.split(':');
    final AyahRef? ref = _parseRef(raw);
    final int? page = parts.length == 3 ? int.tryParse(parts[2]) : null;
    if (ref != null && page != null) {
      lastReadNotifier.value = LastRead(ref, page);
    }
  }
}

// ---------- Favorite surahs ----------

Future<void> toggleFavoriteSurah(int surah) async {
  final Set<int> next = {...favoriteSurahsNotifier.value};
  if (!next.remove(surah)) next.add(surah);

  // Update the screen first, then save on the device.
  favoriteSurahsNotifier.value = next;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _favoriteSurahsKey,
    next.map((n) => n.toString()).toList(),
  );
}

// ---------- Bookmarks (on ayahs) ----------

bool isBookmarked(AyahRef ref) => bookmarksNotifier.value.contains(ref);

// How many ayahs of this surah have a bookmark.
int bookmarkCountOfSurah(int surah) {
  return bookmarksNotifier.value.where((r) => r.surah == surah).length;
}

Future<void> addBookmarks(Iterable<AyahRef> refs) async {
  final List<AyahRef> next = [...bookmarksNotifier.value];
  for (final AyahRef ref in refs) {
    if (!next.contains(ref)) next.add(ref);
  }
  await _saveBookmarks(next);
}

Future<void> removeBookmarks(Iterable<AyahRef> refs) async {
  final Set<AyahRef> remove = refs.toSet();
  await _saveBookmarks(
    bookmarksNotifier.value.where((r) => !remove.contains(r)).toList(),
  );
}

Future<void> _saveBookmarks(List<AyahRef> next) async {
  bookmarksNotifier.value = next;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_bookmarksKey, next.map(_refToText).toList());
}

// ---------- Last read ----------

Future<void> setLastRead(LastRead value) async {
  lastReadNotifier.value = value;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _lastReadKey,
    '${_refToText(value.ref)}:${value.page}',
  );
}