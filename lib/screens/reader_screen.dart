import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/app_colors.dart';
import '../core/arabic_text.dart';
import '../core/reader_settings.dart';
import '../data/quran_data.dart';
import '../core/saved_items.dart';

// Quran reader. The user chooses between swiping pages or scrolling.
class ReaderScreen extends StatefulWidget {
  final QuranData data;
  final int initialPage; // 1-based

  const ReaderScreen({
    super.key,
    required this.data,
    required this.initialPage,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // The page the user is on. It survives switching the view mode.
  late int _page = widget.initialPage;

  // Highlighted ayahs: the ayah of the open sheet, or the ayahs chosen in
  // selection mode. Pages listen to it.
  final ValueNotifier<Set<AyahRef>> _selection =
  ValueNotifier<Set<AyahRef>>(<AyahRef>{});

  // True while the user is choosing several ayahs.
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    // Save the first page as the last read position. We wait for the first
    // frame because saving notifies other screens (like the home card).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _saveLastRead(_page);
    });
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  // The last read position is the first ayah of the current page.
  void _saveLastRead(int page) {
    final AyahRef first = widget.data.ayahsOfPage(page).first;
    setLastRead(LastRead(first, page));
  }

  void _onPageChanged(int page) {
    if (page == _page) return;
    setState(() => _page = page);
    _saveLastRead(page);
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReaderSettingsSheet(),
    );
  }

  // ---------- Selection mode ----------

  void _enterSelectMode(AyahRef first) {
    setState(() => _selectMode = true);
    _selection.value = {first};
  }

  void _exitSelectMode() {
    setState(() => _selectMode = false);
    _selection.value = <AyahRef>{};
  }

  // Adds the ayah to the selection, or removes it if it is already selected.
  void _toggleSelected(AyahRef ref) {
    final Set<AyahRef> next = {..._selection.value};
    if (!next.remove(ref)) next.add(ref);

    if (next.isEmpty) {
      _exitSelectMode();
    } else {
      _selection.value = next;
    }
  }

  // A tap opens the ayah sheet, or selects the ayah in selection mode.
  void _onTapAyah(AyahRef ref) {
    if (_selectMode) {
      _toggleSelected(ref);
    } else {
      _openAyahSheet(ref);
    }
  }

  // A long press starts selecting several ayahs.
  void _onLongPressAyah(AyahRef ref) {
    HapticFeedback.mediumImpact();
    if (_selectMode) {
      _toggleSelected(ref);
    } else {
      _enterSelectMode(ref);
    }
  }

  Future<void> _openAyahSheet(AyahRef ref) async {
    _selection.value = {ref};

    // The sheet returns true when the user chose "select several ayahs".
    final bool? selectMore = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AyahSheet(data: widget.data, ref: ref),
    );

    // The screen may have been closed while the sheet was open.
    if (!mounted) return;

    if (selectMore == true) {
      setState(() => _selectMode = true); // the ayah stays selected
    } else {
      _selection.value = <AyahRef>{};
    }
  }

  Future<void> _copySelection() async {
    final messenger = ScaffoldMessenger.of(context);
    final Set<AyahRef> chosen = _selection.value;
    final String text = _copyTextFor(widget.data, chosen);
    final bool many = chosen.length > 1;

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    _exitSelectMode();
    messenger.showSnackBar(_snack(many ? 'تم نسخ الآيات' : 'تم نسخ الآية'));
  }

  // Adds a bookmark to all selected ayahs, or removes them if all have one.
  Future<void> _bookmarkSelection() async {
    final messenger = ScaffoldMessenger.of(context);
    final Set<AyahRef> chosen = _selection.value;
    final bool allMarked = chosen.every(isBookmarked);

    if (allMarked) {
      await removeBookmarks(chosen);
    } else {
      await addBookmarks(chosen);
    }
    if (!mounted) return;

    _exitSelectMode();
    messenger.showSnackBar(
      _snack(allMarked ? 'أُزيلت العلامة المرجعية' : 'تمت إضافة علامة مرجعية'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // The first ayah on the current page decides the title, juz and hizb.
    final AyahRef first = widget.data.ayahsOfPage(_page).first;
    final Surah surah = widget.data.surahs[first.surah - 1];
    final int juz = widget.data.juzOf(first.surah, first.ayah);
    final int? hizb = widget.data.hizbOf(first.surah, first.ayah);

    final String info = [
      'الجزء ${toArabicDigits(juz)}',
      if (hizb != null) 'الحزب ${toArabicDigits(hizb)}',
      'صفحة ${toArabicDigits(_page)}',
    ].join(' · ');

    return PopScope(
      // In selection mode the back button only closes the selection.
      canPop: !_selectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelectMode();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          foregroundColor: colors.title,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          // null keeps the normal back button.
          leading: _selectMode
              ? IconButton(
            tooltip: 'إلغاء التحديد',
            icon: const Icon(Icons.close_rounded),
            onPressed: _exitSelectMode,
          )
              : null,
          title: _selectMode
              ? ValueListenableBuilder<Set<AyahRef>>(
            valueListenable: _selection,
            builder: (context, chosen, _) {
              return Text(
                '${toArabicDigits(chosen.length)} '
                    '${chosen.length == 1 ? 'آية' : 'آيات'} محددة',
                style: TextStyle(
                  color: colors.title,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              );
            },
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سورة ${surah.name}',
                style: TextStyle(
                  color: colors.title,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              Text(
                info,
                style: TextStyle(color: colors.mutedText, fontSize: 12),
              ),
            ],
          ),
          actions: _selectMode
              ? const []
              : [
            // Favorite button for the surah on the current page.
            ValueListenableBuilder<Set<int>>(
              valueListenable: favoriteSurahsNotifier,
              builder: (context, favorites, _) {
                final bool isFavorite = favorites.contains(surah.number);
                return IconButton(
                  tooltip: isFavorite
                      ? 'إزالة السورة من المفضلة'
                      : 'إضافة السورة للمفضلة',
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? colors.accent : null,
                  ),
                  onPressed: () => toggleFavoriteSurah(surah.number),
                );
              },
            ),
            IconButton(
              tooltip: 'إعدادات القراءة',
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openSettings,
            ),
          ],
        ),
        // The scope gives the pages the selection and the tap actions.
        body: _ReaderScope(
          selection: _selection,
          onTapAyah: _onTapAyah,
          onLongPressAyah: _onLongPressAyah,
          // The keys make Flutter rebuild the body from the current page
          // when the user switches the view mode.
          child: ValueListenableBuilder<ReaderViewMode>(
            valueListenable: readerViewModeNotifier,
            builder: (context, mode, _) {
              if (mode == ReaderViewMode.pages) {
                return _PagedBody(
                  key: const ValueKey('pages'),
                  data: widget.data,
                  initialPage: _page,
                  onPageChanged: _onPageChanged,
                );
              }
              return _ScrollBody(
                key: const ValueKey('scroll'),
                data: widget.data,
                initialPage: _page,
                onPageChanged: _onPageChanged,
              );
            },
          ),
        ),
        bottomNavigationBar: _selectMode
            ? _SelectionBar(
          selection: _selection,
          onCopy: _copySelection,
          onBookmark: _bookmarkSelection,
        )
            : null,
      ),
    );
  }
}

// Mode 1: swipe between pages like a real book.
class _PagedBody extends StatefulWidget {
  final QuranData data;
  final int initialPage;
  final ValueChanged<int> onPageChanged;

  const _PagedBody({
    super.key,
    required this.data,
    required this.initialPage,
    required this.onPageChanged,
  });

  @override
  State<_PagedBody> createState() => _PagedBodyState();
}

class _PagedBodyState extends State<_PagedBody> {
  late final PageController _controller =
  PageController(initialPage: widget.initialPage - 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // In RTL, PageView turns pages from left to right, like a real book.
    return PageView.builder(
      controller: _controller,
      itemCount: widget.data.pageCount,
      onPageChanged: (i) => widget.onPageChanged(i + 1),
      itemBuilder: (context, i) {
        return _MushafPage(
          key: ValueKey(i + 1),
          data: widget.data,
          page: i + 1,
          scrollable: true,
        );
      },
    );
  }
}

// Mode 2: all pages stacked in one list that scrolls up and down.
class _ScrollBody extends StatefulWidget {
  final QuranData data;
  final int initialPage;
  final ValueChanged<int> onPageChanged;

  const _ScrollBody({
    super.key,
    required this.data,
    required this.initialPage,
    required this.onPageChanged,
  });

  @override
  State<_ScrollBody> createState() => _ScrollBodyState();
}

class _ScrollBodyState extends State<_ScrollBody> {
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  late int _lastReported = widget.initialPage;

  @override
  void initState() {
    super.initState();
    _positions.itemPositions.addListener(_onPositions);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_onPositions);
    super.dispose();
  }

  // Finds the first page that is still visible and reports it.
  void _onPositions() {
    final Iterable<ItemPosition> visible =
    _positions.itemPositions.value.where((p) => p.itemTrailingEdge > 0.15);
    if (visible.isEmpty) return;

    final int page =
        visible.reduce((a, b) => a.index <= b.index ? a : b).index + 1;
    if (page == _lastReported) return;
    _lastReported = page;

    // Wait for the frame to end so we never call setState during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPageChanged(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemCount: widget.data.pageCount,
      initialScrollIndex: widget.initialPage - 1,
      itemPositionsListener: _positions,
      itemBuilder: (context, i) {
        return _MushafPage(
          key: ValueKey(i + 1),
          data: widget.data,
          page: i + 1,
          scrollable: false,
        );
      },
    );
  }
}

// Ayahs of one surah that appear on the same page.
class _PageBlock {
  final int surah;
  final List<int> ayahs = [];

  _PageBlock(this.surah);

  // True when the surah begins on this page (so we show its header).
  bool get startsSurah => ayahs.first == 1;
}

// One mushaf page: framed, flowing text with ayah number rosettes.
// scrollable = true: the page scrolls inside itself (swipe mode).
// scrollable = false: the page has its full height (list mode).
class _MushafPage extends StatefulWidget {
  final QuranData data;
  final int page;
  final bool scrollable;

  const _MushafPage({
    super.key,
    required this.data,
    required this.page,
    required this.scrollable,
  });

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  late final List<_PageBlock> _blocks = _buildBlocks();

  // Ayahs where a new quarter of a hizb begins (used for the ۞ sign).
  // The first quarter is the start of the Quran itself, so it gets no sign.
  late final Set<AyahRef> _quarterStarts =
  widget.data.quarterStarts.skip(1).toSet();

  // Groups the page ayahs by surah, because a surah header can sit in between.
  List<_PageBlock> _buildBlocks() {
    final List<_PageBlock> blocks = [];
    for (final AyahRef ref in widget.data.ayahsOfPage(widget.page)) {
      if (blocks.isEmpty || blocks.last.surah != ref.surah) {
        blocks.add(_PageBlock(ref.surah));
      }
      blocks.last.ayahs.add(ref.ayah);
    }
    return blocks;
  }

  // Builds the flowing text of one surah block on this page.
  // [selected] are the highlighted ayahs, [marked] the bookmarked ones.
  Widget _buildAyahText(
      _PageBlock block,
      double fontSize,
      String family,
      AppPalette colors,
      Set<AyahRef> selected,
      Set<AyahRef> marked,
      _ReaderScope scope,
      ) {
    final Surah surah = widget.data.surahs[block.surah - 1];
    final List<TextSpan> spans = [];
    final List<TextRange> lineRanges = [];
    final List<_AyahRange> ayahRanges = [];

    // Length of the text so far. The sajda line and the taps need exact
    // positions inside the text.
    int offset = 0;
    void add(TextSpan span) {
      spans.add(span);
      offset += span.text?.length ?? 0;
    }

    for (final int n in block.ayahs) {
      final AyahRef ref = AyahRef(block.surah, n);
      final int ayahStart = offset;
      final bool isMarked = marked.contains(ref);

      // A selected ayah has a stronger highlight than a bookmarked one.
      final Color? highlight = selected.contains(ref)
          ? colors.accent.withValues(alpha: 0.18)
          : isMarked
          ? colors.accent.withValues(alpha: 0.08)
          : null;
      final TextStyle base = TextStyle(backgroundColor: highlight);
      final String ayahText = surah.ayahs[n - 1];

      // Rub el Hizb sign at the start of every quarter of a hizb.
      if (_quarterStarts.contains(ref) && !ayahText.contains('\u06DE')) {
        add(
          TextSpan(
            text: _kHizbSign,
            style: _signStyle(family, fontSize, colors.accent, highlight),
          ),
        );
        add(TextSpan(text: ' ', style: base));
      }

      // The ayah words, with the signs drawn by the sign font.
      final List<TextSpan> words = _ayahTextSpans(
        ayahText,
        fontSize: fontSize,
        family: family,
        signColor: colors.accent,
        highlight: highlight,
        startOffset: offset,
        lineWords: _kSajdaLines['${block.surah}:$n'],
        lineRanges: lineRanges,
      );
      for (final TextSpan s in words) {
        add(s);
      }

      // U+200F (RLM) keeps the sign and the ayah number as separate runs,
      // so they can never swap places.
      add(TextSpan(text: ' \u200F', style: base));

      // The ayah number is a glyph from our AyahMarker font (U+E000 + number).
      add(
        TextSpan(
          text: String.fromCharCode(0xE000 + n),
          style: TextStyle(
            fontFamily: 'AyahMarker',
            fontSize: fontSize,
            color: colors.accent,
            height: 0.01,
            backgroundColor: highlight,
          ),
        ),
      );
      add(const TextSpan(text: ' \u200F'));

      ayahRanges.add(_AyahRange(ayahStart, offset, ref));
    }

    return _LinedText(
      span: TextSpan(children: spans),
      style: TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        height: 2.0,
        color: colors.bodyText,
      ),
      lineRanges: lineRanges,
      lineColor: colors.accent,
      fontSize: fontSize,
      // Share of the line box that is above the baseline (depends on the font).
      ascentRatio: family == 'ScheherazadeNew' ? 0.658 : 0.741,
      ayahRanges: ayahRanges,
      onTapAyah: scope.onTapAyah,
      onLongPressAyah: scope.onLongPressAyah,
    );
  }

  // One surah block inside the box: optional small banner, Basmala, ayahs.
  Widget _buildBlock(
      _PageBlock block,
      bool isFirst,
      double fontSize,
      String family,
      AppPalette colors,
      Set<AyahRef> selected,
      Set<AyahRef> marked,
      _ReaderScope scope,
      ) {
    final Surah surah = widget.data.surahs[block.surah - 1];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A surah that begins in the middle of the page gets a small banner
        // inside the same box. (At the top of a page the big arch is used.)
        if (block.startsSurah && !isFirst)
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 6),
            child: _InlineSurahBanner(surah: surah),
          ),
        if (block.startsSurah && surah.showsBasmalaHeader)
          _BasmalaHeader(
            basmala: widget.data.basmala,
            fontSize: fontSize,
            fontFamily: family,
          ),
        _buildAyahText(
          block,
          fontSize,
          family,
          colors,
          selected,
          marked,
          scope,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final _ReaderScope scope = _ReaderScope.of(context);

    // Rebuild when the font, the selection or the bookmarks change.
    return ListenableBuilder(
      listenable: Listenable.merge([
        readerFontSizeNotifier,
        readerFontNotifier,
        scope.selection,
        bookmarksNotifier,
      ]),
      builder: (context, _) {
        final double fontSize = readerFontSizeNotifier.value;
        final String family = fontFamilyOf(readerFontNotifier.value);
        final Set<AyahRef> selected = scope.selection.value;
        final Set<AyahRef> marked = bookmarksNotifier.value.toSet();

        // One box for the whole page.
        final Widget box = _AyahBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < _blocks.length; i++)
                _buildBlock(
                  _blocks[i],
                  i == 0,
                  fontSize,
                  family,
                  colors,
                  selected,
                  marked,
                  scope,
                ),
            ],
          ),
        );

        // If a surah starts at the very top of the page, the big arch banner
        // sits on top of the box and touches it.
        final _PageBlock first = _blocks.first;
        final Widget framed = first.startsSurah
            ? _BannerOverBox(
          surah: widget.data.surahs[first.surah - 1],
          child: box,
        )
            : box;

        final Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            framed,
            const SizedBox(height: 12),
            Text(
              toArabicDigits(widget.page),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.mutedText, fontSize: 14),
            ),
          ],
        );

        const EdgeInsets padding = EdgeInsets.fromLTRB(12, 6, 12, 16);

        return widget.scrollable
            ? SingleChildScrollView(padding: padding, child: content)
            : Padding(padding: padding, child: content);
      },
    );
  }
}


// Where one ayah starts and ends inside the page text (used to find the
// ayah that was tapped).
class _AyahRange {
  final int start;
  final int end;
  final AyahRef ref;

  const _AyahRange(this.start, this.end, this.ref);
}

// Gives the pages the selection and the tap actions, so we do not have to pass
// them through every widget.
class _ReaderScope extends InheritedWidget {
  final ValueNotifier<Set<AyahRef>> selection;
  final void Function(AyahRef) onTapAyah;
  final void Function(AyahRef) onLongPressAyah;

  const _ReaderScope({
    required this.selection,
    required this.onTapAyah,
    required this.onLongPressAyah,
    required super.child,
  });

  static _ReaderScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ReaderScope>()!;
  }

  // The notifier and the actions never change, so nothing needs rebuilding.
  @override
  bool updateShouldNotify(_ReaderScope oldWidget) => false;
}

SnackBar _snack(String message) {
  return SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  );
}

// Text to copy for one or more ayahs, in Quran order.
// Each surah gets its own group with a line under it.
String _copyTextFor(QuranData data, Iterable<AyahRef> refs) {
  final List<AyahRef> sorted = refs.toList()
    ..sort((a, b) {
      return a.surah != b.surah
          ? a.surah.compareTo(b.surah)
          : a.ayah.compareTo(b.ayah);
    });

  final StringBuffer out = StringBuffer();
  int i = 0;
  while (i < sorted.length) {
    final int surahNumber = sorted[i].surah;
    final List<int> numbers = [];
    while (i < sorted.length && sorted[i].surah == surahNumber) {
      numbers.add(sorted[i].ayah);
      i++;
    }

    final Surah surah = data.surahs[surahNumber - 1];
    if (out.isNotEmpty) out.write('\n\n');

    out.write(
      numbers
          .map((n) => '${surah.ayahs[n - 1]} ﴿${toArabicDigits(n)}﴾')
          .join(' '),
    );
    out.write(
      '\n— سورة ${surah.name} · '
          '${numbers.length == 1 ? 'الآية' : 'الآيات'} '
          '${_ayahNumbersLabel(numbers)}',
    );
  }
  return out.toString();
}

// Writes sorted ayah numbers as short ranges: [3, 4, 5, 9] -> "٣–٥، ٩".
String _ayahNumbersLabel(List<int> numbers) {
  final List<String> parts = [];
  int start = numbers.first;
  int previous = start;

  void close() {
    parts.add(
      start == previous
          ? toArabicDigits(start)
          : '${toArabicDigits(start)}–${toArabicDigits(previous)}',
    );
  }

  for (int k = 1; k < numbers.length; k++) {
    if (numbers[k] == previous + 1) {
      previous = numbers[k];
    } else {
      close();
      start = numbers[k];
      previous = start;
    }
  }
  close();
  return parts.join('، ');
}

// Ayah text with the pause / sajda signs drawn by our sign fonts.
// Other screens (like favorites) use this to show an ayah correctly.
List<TextSpan> quranAyahSpans(
    String text, {
      required double fontSize,
      required String family,
      required Color signColor,
    }) {
  return _ayahTextSpans(
    text,
    fontSize: fontSize,
    family: family,
    signColor: signColor,
  );
}

// Bar at the bottom while the user is selecting several ayahs.
class _SelectionBar extends StatelessWidget {
  final ValueNotifier<Set<AyahRef>> selection;
  final VoidCallback onCopy;
  final VoidCallback onBookmark;

  const _SelectionBar({
    required this.selection,
    required this.onCopy,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.card,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListenableBuilder(
            listenable: Listenable.merge([selection, bookmarksNotifier]),
            builder: (context, _) {
              final Set<AyahRef> chosen = selection.value;
              final bool allMarked =
                  chosen.isNotEmpty && chosen.every(isBookmarked);

              return Row(
                children: [
                  Expanded(
                    child: _BarButton(
                      icon: Icons.copy_rounded,
                      label: 'نسخ',
                      onTap: onCopy,
                    ),
                  ),
                  Expanded(
                    child: _BarButton(
                      icon: allMarked
                          ? Icons.bookmark_remove_rounded
                          : Icons.bookmark_add_outlined,
                      label: allMarked ? 'إزالة العلامة' : 'علامة مرجعية',
                      onTap: onBookmark,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.accent, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: colors.bodyText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Quran signs are drawn with our own sign fonts, so they always sit in the
// right place. The Quran text itself is never changed (copy uses it).
const Map<int, int> _kSignGlyphs = {
  0x06D6: 0xE300, // pause signs
  0x06D7: 0xE301,
  0x06D8: 0xE302,
  0x06D9: 0xE303,
  0x06DA: 0xE304,
  0x06DB: 0xE305,
  0x06DC: 0xE306,
  0x06DE: 0xE310, // rub el hizb
  0x06E9: 0xE311, // sajda
};

// Rub el Hizb glyph (added at the start of each quarter).
const String _kHizbSign = '\uE310';

// True when the token is only signs (no letters).
bool _isSignToken(String token) {
  return token.isNotEmpty && token.runes.every(_kSignGlyphs.containsKey);
}

// Pause signs (ج، قلى، صلى...) sit on top of the last letter of the word.
bool _isPauseSign(String token) {
  return token.runes.every((c) => c >= 0x06D6 && c <= 0x06DC);
}

// Each sign font has the same vertical metrics as its reading font, so a
// sign never changes the line height and is highlighted like normal text.
String _signFamilyOf(String readerFamily) {
  return readerFamily == 'ScheherazadeNew'
      ? 'QuranSignsSch'
      : 'QuranSignsAmiri';
}

TextStyle _signStyle(
    String readerFamily,
    double fontSize,
    Color color,
    Color? highlight,
    ) {
  return TextStyle(
    fontFamily: _signFamilyOf(readerFamily),
    fontSize: fontSize,
    color: color,
    backgroundColor: highlight,
  );
}

// Splits the ayah text into spans: normal words stay as text, sign tokens
// become sign-font glyphs.
// If [lineWords] is given, the text range of those words is added to
// [lineRanges] (it is used to draw the sajda line above them).
List<TextSpan> _ayahTextSpans(
    String text, {
      required double fontSize,
      required String family,
      required Color signColor,
      GestureRecognizer? recognizer,
      Color? highlight,
      int startOffset = 0,
      _WordRange? lineWords,
      List<TextRange>? lineRanges,
    }) {
  final List<TextSpan> spans = [];
  final TextStyle plainStyle = TextStyle(backgroundColor: highlight);
  final StringBuffer plain = StringBuffer();
  int pos = startOffset;
  int? lineStart;
  int? lineEnd;

  void flush() {
    if (plain.isEmpty) return;
    spans.add(
      TextSpan(text: plain.toString(), recognizer: recognizer, style: plainStyle),
    );
    plain.clear();
  }

  final List<String> tokens = text.split(' ');
  for (int i = 0; i < tokens.length; i++) {
    final String token = tokens[i];
    final bool isSign = _isSignToken(token);

    // A pause sign has no space before it: it sits on the last letter of the
    // word before it. Every other token keeps its normal space.
    if (i > 0 && !(isSign && _isPauseSign(token))) {
      plain.write(' ');
      pos += 1;
    }

    if (isSign) {
      flush();
      final String glyphs =
      String.fromCharCodes(token.runes.map((c) => _kSignGlyphs[c]!));
      spans.add(
        TextSpan(
          text: glyphs,
          recognizer: recognizer,
          style: _signStyle(family, fontSize, signColor, highlight),
        ),
      );
      pos += glyphs.length;
    } else {
      if (lineWords != null && i == lineWords.from) lineStart = pos;
      plain.write(token);
      pos += token.length;
      if (lineWords != null && i == lineWords.to) lineEnd = pos;
    }
  }
  flush();

  if (lineStart != null && lineEnd != null) {
    lineRanges?.add(TextRange(start: lineStart, end: lineEnd));
  }
  return spans;
}

// Word range (word numbers inside the ayah, starting at 0) that gets the
// sajda line above it.
class _WordRange {
  final int from;
  final int to; // inclusive

  const _WordRange(this.from, this.to);
}

// Words that get the sajda line. Key is 'surah:ayah'.
// NOTE: this list came from the user's reference and must be checked
// against the mushaf. Edit the numbers here if a line is on the wrong words.
const Map<String, _WordRange> _kSajdaLines = {
  '7:206': _WordRange(9, 10), // وَلَهُۥ يَسْجُدُونَ
  '13:15': _WordRange(0, 5), // وَلِلَّهِ يَسْجُدُ ... وَٱلْأَرْضِ
  '16:49': _WordRange(1, 1), // يَسْجُدُ
  '17:107': _WordRange(16, 16), // يَخِرُّونَ
  '19:58': _WordRange(27, 29), // خَرُّوا۟ سُجَّدًا وَبُكِيًّا
  '22:18': _WordRange(0, 11), // أَلَمْ تَرَ ... ٱلْأَرْضِ
  '22:77': _WordRange(0, 4), // يَـٰٓأَيُّهَا ... وَٱسْجُدُوا۟
  '25:60': _WordRange(0, 4), // وَإِذَا قِيلَ لَهُمُ ٱسْجُدُوا۟ لِلرَّحْمَـٰنِ
  '27:25': _WordRange(1, 1), // يَسْجُدُوا۟
  '32:15': _WordRange(0, 8), // إِنَّمَا ... خَرُّوا۟ سُجَّدًا
  '38:24': _WordRange(29, 33), // فَٱسْتَغْفَرَ ... وَأَنَابَ
  '41:37': _WordRange(12, 12), // وَٱسْجُدُوا۟
  '53:62': _WordRange(0, 2), // فَٱسْجُدُوا۟ لِلَّهِ وَٱعْبُدُوا۟
  '84:21': _WordRange(0, 5), // وَإِذَا قُرِئَ ... لَا يَسْجُدُونَ
  '96:19': _WordRange(0, 4), // كَلَّا لَا تُطِعْهُ وَٱسْجُدْ وَٱقْتَرِب
};

// How high above the baseline the sajda line is drawn (in font sizes).
const double _kSajdaLineHeight = 1.25;

// A text with an optional line above some words, and ayah taps.
// A tap or a long press is mapped to the ayah that sits at that position.
class _LinedText extends StatefulWidget {
  final TextSpan span;
  final TextStyle style;
  final List<TextRange> lineRanges;
  final Color lineColor;
  final double fontSize;
  final double ascentRatio;
  final List<_AyahRange> ayahRanges;
  final void Function(AyahRef) onTapAyah;
  final void Function(AyahRef) onLongPressAyah;

  const _LinedText({
    required this.span,
    required this.style,
    required this.lineRanges,
    required this.lineColor,
    required this.fontSize,
    required this.ascentRatio,
    required this.ayahRanges,
    required this.onTapAyah,
    required this.onLongPressAyah,
  });

  @override
  State<_LinedText> createState() => _LinedTextState();
}

class _LinedTextState extends State<_LinedText> {
  final GlobalKey _textKey = GlobalKey();

  RenderParagraph? _findParagraph(RenderObject? object) {
    if (object is RenderParagraph) return object;
    RenderParagraph? found;
    object?.visitChildren((child) {
      found ??= _findParagraph(child);
    });
    return found;
  }

  // Finds the ayah under the finger and calls the matching action.
  void _handle(Offset position, {required bool longPress}) {
    if (widget.ayahRanges.isEmpty) return;

    final RenderParagraph? paragraph =
    _findParagraph(_textKey.currentContext?.findRenderObject());
    if (paragraph == null) return;

    final int offset = paragraph.getPositionForOffset(position).offset;

    // The first ayah that ends after the tapped position. A tap after the
    // last character counts for the last ayah.
    _AyahRange hit = widget.ayahRanges.last;
    for (final _AyahRange range in widget.ayahRanges) {
      if (offset < range.end) {
        hit = range;
        break;
      }
    }

    if (longPress) {
      widget.onLongPressAyah(hit.ref);
    } else {
      widget.onTapAyah(hit.ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget text = Text.rich(
      widget.span,
      key: _textKey,
      textAlign: TextAlign.justify,
      style: widget.style,
    );

    // Most pages have no sajda line, so they stay a plain Text.
    final Widget content = widget.lineRanges.isEmpty
        ? text
        : Stack(
      children: [
        text,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SajdaLinePainter(
                textKey: _textKey,
                ranges: widget.lineRanges,
                color: widget.lineColor,
                fontSize: widget.fontSize,
                ascentRatio: widget.ascentRatio,
              ),
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handle(details.localPosition, longPress: false),
      onLongPressStart: (details) =>
          _handle(details.localPosition, longPress: true),
      child: content,
    );
  }
}

// Draws the sajda line above the given text ranges. It asks the text for the
// real position of the words, so it follows the layout at any font size.
class _SajdaLinePainter extends CustomPainter {
  final GlobalKey textKey;
  final List<TextRange> ranges;
  final Color color;
  final double fontSize;
  final double ascentRatio;

  const _SajdaLinePainter({
    required this.textKey,
    required this.ranges,
    required this.color,
    required this.fontSize,
    required this.ascentRatio,
  });

  RenderParagraph? _findParagraph(RenderObject? object) {
    if (object is RenderParagraph) return object;
    RenderParagraph? found;
    object?.visitChildren((child) {
      found ??= _findParagraph(child);
    });
    return found;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final RenderParagraph? paragraph =
    _findParagraph(textKey.currentContext?.findRenderObject());
    if (paragraph == null) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (final TextRange range in ranges) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );

      // One segment per text line: [left, right, baseline].
      final Map<int, List<double>> segments = {};
      for (final box in boxes) {
        if (box.right - box.left <= 0) continue;

        // The baseline is a fixed share of the box height (from the top).
        final double baseline =
            box.top + (box.bottom - box.top) * ascentRatio;
        final int lineKey = baseline.round();

        final List<double>? s = segments[lineKey];
        if (s == null) {
          segments[lineKey] = [box.left, box.right, baseline];
        } else {
          if (box.left < s[0]) s[0] = box.left;
          if (box.right > s[1]) s[1] = box.right;
        }
      }

      for (final List<double> s in segments.values) {
        final double y = s[2] - fontSize * _kSajdaLineHeight;
        canvas.drawLine(Offset(s[0] - 1, y), Offset(s[1] + 1, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Folder of the ornament images. They are black with a transparent
// background, so we can paint them in any color.
const String _ornamentsPath = 'assets/images/ornaments';

// Shows one ornament image painted in [color].
// BlendMode.srcIn keeps the shape of the image and replaces its color.
class _Ornament extends StatelessWidget {
  final String file;
  final Color color;
  final BoxFit fit;

  const _Ornament({
    required this.file,
    required this.color,
    this.fit = BoxFit.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '$_ornamentsPath/$file',
      color: color,
      colorBlendMode: BlendMode.srcIn,
      fit: fit,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}

// Width / height of the arch banner (a bit taller than the image so the
// name and the details both fit).
const double _kArchRatio = 1200 / 430;

// Puts the arch banner on top of the box so that it touches the box edge.
class _BannerOverBox extends StatelessWidget {
  final Surah surah;
  final Widget child; // the box

  const _BannerOverBox({required this.surah, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double bannerHeight = constraints.maxWidth / _kArchRatio;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // The box starts 3px above the banner bottom so they overlap.
            Padding(
              padding: EdgeInsets.only(top: bannerHeight - 3),
              child: child,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: bannerHeight,
              child: _SurahBanner(surah: surah),
            ),
          ],
        );
      },
    );
  }
}

// Big arch banner with the surah name and its details inside.
// It fills the space it is given (see _BannerOverBox).
class _SurahBanner extends StatelessWidget {
  final Surah surah;

  const _SurahBanner({required this.surah});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String type = surah.isMeccan ? 'مكية' : 'مدنية';

    return Stack(
      fit: StackFit.expand,
      children: [
        _Ornament(file: 'ornament_banner_fill.png', color: colors.softSurface),
        _Ornament(file: 'ornament_banner_line.png', color: colors.accent),
        // Name in the wide body of the frame.
        Align(
          alignment: const Alignment(0, 0.30),
          child: Text(
            'سورة ${surah.name}',
            style: TextStyle(
              color: colors.title,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.66),
          child: Text(
            '$type · ${toArabicDigits(surah.ayahCount)} آية',
            style: TextStyle(color: colors.mutedText, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}

// Small banner for a surah that starts in the middle of a page.
// It sits inside the box, between the ayahs.
class _InlineSurahBanner extends StatelessWidget {
  final Surah surah;

  const _InlineSurahBanner({required this.surah});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String type = surah.isMeccan ? 'مكية' : 'مدنية';

    return AspectRatio(
      aspectRatio: 1000 / 153,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Ornament(file: 'ornament_inline_fill.png', color: colors.softSurface),
          _Ornament(file: 'ornament_inline_line.png', color: colors.accent),
          // scaleDown only shrinks the text if a long name does not fit.
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'سورة ${surah.name}',
                    style: TextStyle(
                      color: colors.title,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$type · ${toArabicDigits(surah.ayahCount)} آية',
                    style: TextStyle(color: colors.mutedText, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The framed box that holds the ayahs (double border, like a mushaf page).
class _AyahBox extends StatelessWidget {
  final Widget child;

  const _AyahBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border, width: 1.5),
      ),
      // Inner thin frame: gives the double border.
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
        ),
        child: child,
      ),
    );
  }
}

// The Basmala with a soft divider under it (inside the box, above the ayahs).
class _BasmalaHeader extends StatelessWidget {
  final String basmala;
  final double fontSize;
  final String fontFamily;

  const _BasmalaHeader({
    required this.basmala,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Text(
          basmala,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            height: 2.0,
            color: colors.title,
          ),
        ),
        SizedBox(
          height: 22,
          width: double.infinity,
          child: CustomPaint(
            painter: _SoftDividerPainter(line: colors.accent),
          ),
        ),
      ],
    );
  }
}

// Soft divider: two lines that fade out at the ends, two tiny diamonds,
// and a small outlined four-petal flower in the middle.
class _SoftDividerPainter extends CustomPainter {
  final Color line;

  const _SoftDividerPainter({required this.line});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double cx = w / 2;
    final double cy = size.height / 2;
    const double gap = 24; // empty space for the ornament in the middle
    final double lineLength = math.max(cx - gap - 10, 1);

    // Left line fades in toward the center, right line fades out.
    final Paint linePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    linePaint.shader = LinearGradient(
      colors: [line.withValues(alpha: 0), line.withValues(alpha: 0.8)],
    ).createShader(Rect.fromLTWH(10, 0, lineLength, size.height));
    canvas.drawLine(Offset(10, cy), Offset(cx - gap, cy), linePaint);

    linePaint.shader = LinearGradient(
      colors: [line.withValues(alpha: 0.8), line.withValues(alpha: 0)],
    ).createShader(Rect.fromLTWH(cx + gap, 0, lineLength, size.height));
    canvas.drawLine(Offset(cx + gap, cy), Offset(w - 10, cy), linePaint);

    // Two tiny diamonds next to the flower.
    final Paint diamondPaint = Paint()..color = line.withValues(alpha: 0.7);
    for (final double dx in [-16.0, 16.0]) {
      final Path d = Path()
        ..moveTo(cx + dx, cy - 2.4)
        ..lineTo(cx + dx + 2.4, cy)
        ..lineTo(cx + dx, cy + 2.4)
        ..lineTo(cx + dx - 2.4, cy)
        ..close();
      canvas.drawPath(d, diamondPaint);
    }

    // Four thin pointed petals, outline only.
    final Paint petalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round
      ..color = line.withValues(alpha: 0.9);

    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(i * math.pi / 2);
      final Path petal = Path()
        ..moveTo(0, -1.8)
        ..quadraticBezierTo(-3.8, -4.7, 0, -7.6)
        ..quadraticBezierTo(3.8, -4.7, 0, -1.8);
      canvas.drawPath(petal, petalPaint);
      canvas.restore();
    }

    // Small dot in the center.
    canvas.drawCircle(Offset(cx, cy), 1.2, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_SoftDividerPainter old) => old.line != line;
}

// Bottom sheet shown when an ayah is tapped. It returns true when the user
// chose to select several ayahs. More actions come later (tafsir, audio).
class _AyahSheet extends StatelessWidget {
  final QuranData data;
  final AyahRef ref;

  const _AyahSheet({required this.data, required this.ref});

  Future<void> _copy(BuildContext context) async {
    // Capture these before the await so we do not use context after it.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await Clipboard.setData(ClipboardData(text: _copyTextFor(data, [ref])));
    navigator.pop(false);
    messenger.showSnackBar(_snack('تم نسخ الآية'));
  }

  Future<void> _toggleBookmark(BuildContext context, bool marked) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (marked) {
      await removeBookmarks([ref]);
    } else {
      await addBookmarks([ref]);
    }
    navigator.pop(false);
    messenger.showSnackBar(
      _snack(marked ? 'أُزيلت العلامة المرجعية' : 'تمت إضافة علامة مرجعية'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Surah surah = data.surahs[ref.surah - 1];
    final String family = fontFamilyOf(readerFontNotifier.value);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The title and the ayah scroll when the ayah is long.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سورة ${surah.name} · الآية ${toArabicDigits(ref.ayah)}',
                      style: TextStyle(
                        color: colors.title,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: _ayahTextSpans(
                          surah.ayahs[ref.ayah - 1],
                          fontSize: 24,
                          family: family,
                          signColor: colors.accent,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: family,
                        fontSize: 24,
                        height: 2.0,
                        color: colors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bookmark: the text changes if this ayah already has one.
            ValueListenableBuilder<List<AyahRef>>(
              valueListenable: bookmarksNotifier,
              builder: (context, marks, _) {
                final bool marked = marks.contains(ref);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    marked
                        ? Icons.bookmark_remove_rounded
                        : Icons.bookmark_add_outlined,
                    color: colors.accent,
                  ),
                  title: Text(
                    marked ? 'إزالة العلامة المرجعية' : 'علامة مرجعية',
                    style: TextStyle(color: colors.bodyText),
                  ),
                  onTap: () => _toggleBookmark(context, marked),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.checklist_rounded, color: colors.accent),
              title: Text(
                'تحديد عدة آيات',
                style: TextStyle(color: colors.bodyText),
              ),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.copy_rounded, color: colors.accent),
              title: Text('نسخ الآية', style: TextStyle(color: colors.bodyText)),
              onTap: () => _copy(context),
            ),
          ],
        ),
      ),
    );
  }
}

// Reader settings: view mode, font, and font size with a live preview.
class _ReaderSettingsSheet extends StatelessWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final ButtonStyle segmentStyle = SegmentedButton.styleFrom(
      foregroundColor: colors.mutedText,
      selectedForegroundColor: colors.title,
      selectedBackgroundColor: colors.softSurface,
    );

    Widget label(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: colors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            readerViewModeNotifier,
            readerFontNotifier,
            readerFontSizeNotifier,
          ]),
          builder: (context, _) {
            final ReaderViewMode mode = readerViewModeNotifier.value;
            final ReaderFont font = readerFontNotifier.value;
            final double size = readerFontSizeNotifier.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات القراءة',
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                label('طريقة العرض'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ReaderViewMode>(
                    style: segmentStyle,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ReaderViewMode.pages,
                        icon: Icon(Icons.menu_book_rounded),
                        label: Text('صفحات'),
                      ),
                      ButtonSegment(
                        value: ReaderViewMode.scroll,
                        icon: Icon(Icons.swap_vert_rounded),
                        label: Text('تمرير'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => setReaderViewMode(s.first),
                  ),
                ),

                label('الخط'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ReaderFont>(
                    style: segmentStyle,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ReaderFont.amiriQuran,
                        label: Text('أميري'),
                      ),
                      ButtonSegment(
                        value: ReaderFont.scheherazade,
                        label: Text('شهرزاد'),
                      ),
                    ],
                    selected: {font},
                    onSelectionChanged: (s) => setReaderFont(s.first),
                  ),
                ),

                label('حجم الخط'),
                Center(
                  child: Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamilyOf(font),
                      fontSize: size,
                      height: 2.0,
                      color: colors.bodyText,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'تصغير',
                      onPressed: size > kMinFontSize
                          ? () => setReaderFontSize(size - 2)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Expanded(
                      child: Slider(
                        value: size,
                        min: kMinFontSize,
                        max: kMaxFontSize,
                        divisions: 12,
                        activeColor: colors.accent,
                        onChanged: setReaderFontSize,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'تكبير',
                      onPressed: size < kMaxFontSize
                          ? () => setReaderFontSize(size + 2)
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}