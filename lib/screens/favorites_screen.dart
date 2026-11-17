import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/arabic_text.dart';
import '../core/reader_settings.dart';
import '../core/saved_items.dart';
import '../data/quran_data.dart';
import 'reader_screen.dart';

// Favorites: the favorite surahs and the bookmarked ayahs, in one page.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.title,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'المفضلة',
          style: TextStyle(
            color: colors.title,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<QuranData>(
        future: QuranRepository.instance.load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر تحميل المصحف',
                style: TextStyle(color: colors.mutedText),
              ),
            );
          }

          final QuranData? data = snapshot.data;
          if (data == null) {
            return Center(
              child: CircularProgressIndicator(color: colors.accent),
            );
          }

          // Rebuild when favorites or bookmarks change.
          return ListenableBuilder(
            listenable: Listenable.merge([
              favoriteSurahsNotifier,
              bookmarksNotifier,
            ]),
            builder: (context, _) => _FavoritesList(data: data),
          );
        },
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final QuranData data;

  const _FavoritesList({required this.data});

  // Opens the reader on the page of this ayah.
  void _openReader(BuildContext context, int surah, int ayah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          data: data,
          initialPage: data.pageOf(surah, ayah),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final List<int> surahs = favoriteSurahsNotifier.value.toList()..sort();
    // Newest bookmark first.
    final List<AyahRef> marks = bookmarksNotifier.value.reversed.toList();

    if (surahs.isEmpty && marks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded, size: 56, color: colors.accent),
              const SizedBox(height: 16),
              Text(
                'لا يوجد شيء محفوظ بعد',
                style: TextStyle(
                  color: colors.title,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط على القلب بجانب أي سورة لإضافتها، '
                    'أو اضغط على آية ثم اختر «علامة مرجعية».',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedText, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (surahs.isNotEmpty) ...[
          _SectionTitle(
            icon: Icons.favorite_rounded,
            title: 'السور المفضلة',
            count: surahs.length,
          ),
          for (final int number in surahs)
            _FavoriteSurahCard(
              surah: data.surahs[number - 1],
              onTap: () => _openReader(context, number, 1),
            ),
          const SizedBox(height: 18),
        ],
        if (marks.isNotEmpty) ...[
          _SectionTitle(
            icon: Icons.bookmark_rounded,
            title: 'العلامات المرجعية',
            count: marks.length,
          ),
          for (final AyahRef ref in marks)
            _BookmarkCard(
              data: data,
              ref: ref,
              onTap: () => _openReader(context, ref.surah, ref.ayah),
            ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: colors.accent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: colors.title,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            toArabicDigits(count),
            style: TextStyle(color: colors.mutedText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// A favorite surah: tap to open it, tap the heart to remove it.
class _FavoriteSurahCard extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const _FavoriteSurahCard({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String type = surah.isMeccan ? 'مكية' : 'مدنية';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border.withValues(alpha: 0.8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.softSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    toArabicDigits(surah.number),
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سورة ${surah.name}',
                        style: TextStyle(
                          color: colors.title,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$type · ${toArabicDigits(surah.ayahCount)} آية',
                        style: TextStyle(color: colors.mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة من المفضلة',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.favorite_rounded,
                    color: colors.accent,
                    size: 22,
                  ),
                  onPressed: () => toggleFavoriteSurah(surah.number),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A bookmarked ayah: its place, a short preview of the text, and a button to
// remove the bookmark.
class _BookmarkCard extends StatelessWidget {
  final QuranData data;
  final AyahRef ref;
  final VoidCallback onTap;

  const _BookmarkCard({
    required this.data,
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Surah surah = data.surahs[ref.surah - 1];
    final String family = fontFamilyOf(readerFontNotifier.value);
    final int page = data.pageOf(ref.surah, ref.ayah);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border.withValues(alpha: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark_rounded, color: colors.accent, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'سورة ${surah.name} · الآية ${toArabicDigits(ref.ayah)}',
                        style: TextStyle(
                          color: colors.title,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'صفحة ${toArabicDigits(page)}',
                      style: TextStyle(color: colors.mutedText, fontSize: 12),
                    ),
                    IconButton(
                      tooltip: 'إزالة العلامة المرجعية',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.bookmark_remove_rounded,
                        color: colors.mutedText,
                        size: 22,
                      ),
                      onPressed: () => removeBookmarks([ref]),
                    ),
                  ],
                ),
                // A short preview of the ayah (two lines at most).
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text.rich(
                    TextSpan(
                      children: quranAyahSpans(
                        surah.ayahs[ref.ayah - 1],
                        fontSize: 20,
                        family: family,
                        signColor: colors.accent,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: family,
                      fontSize: 20,
                      height: 2.0,
                      color: colors.bodyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}