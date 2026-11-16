import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/arabic_text.dart';
import '../data/quran_data.dart';
import 'reader_screen.dart';

// Surah list with a search box. Data comes from assets/data/quran.json.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  // Created once, so rebuilding the screen does not reload the data.
  late final Future<QuranData> _future = QuranRepository.instance.load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Matches by surah name (ignoring diacritics), number, or English name.
  List<Surah> _filter(List<Surah> all) {
    final String q = normalizeArabic(_query.trim()).toLowerCase();
    if (q.isEmpty) return all;

    return all.where((s) {
      return normalizeArabic(s.name).contains(q) ||
          s.number.toString() == q ||
          s.transliteration.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FutureBuilder<QuranData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر تحميل المصحف\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.mutedText),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: colors.accent),
              );
            }

            final QuranData data = snapshot.data!;
            final List<Surah> shown = _filter(data.surahs);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المصحف الشريف',
                        style: TextStyle(
                          color: colors.title,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(color: colors.bodyText),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن سورة',
                          hintStyle: TextStyle(color: colors.mutedText),
                          prefixIcon:
                          Icon(Icons.search_rounded, color: colors.accent),
                          filled: true,
                          fillColor: colors.card,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                            BorderSide(color: colors.accent, width: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: shown.isEmpty
                      ? Center(
                    child: Text(
                      'لا توجد نتائج',
                      style: TextStyle(color: colors.mutedText),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final Surah surah = shown[i];
                      return _SurahTile(
                        surah: surah,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderScreen(
                                data: data,
                                // Open on the page where this surah starts.
                                initialPage: data.pageOf(surah.number, 1),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// One row in the surah list: number badge, name, and type + ayah count.
class _SurahTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const _SurahTile({required this.surah, required this.onTap});

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
                // Number badge (on the right in RTL).
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

                Icon(
                  Icons.chevron_left_rounded,
                  color: colors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}