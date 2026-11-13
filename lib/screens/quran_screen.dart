import 'package:flutter/material.dart';
import '../core/app_colors.dart';

// Quran screen that displays a list of surahs
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> surahs = [
      {'number': '1', 'name': 'الفاتحة', 'ayahs': '7 آيات'},
      {'number': '2', 'name': 'البقرة', 'ayahs': '286 آية'},
      {'number': '3', 'name': 'آل عمران', 'ayahs': '200 آية'},
      {'number': '4', 'name': 'النساء', 'ayahs': '176 آية'},
      {'number': '5', 'name': 'المائدة', 'ayahs': '120 آية'},
      {'number': '6', 'name': 'الأنعام', 'ayahs': '165 آية'},
      {'number': '7', 'name': 'الأعراف', 'ayahs': '206 آيات'},
      {'number': '8', 'name': 'الأنفال', 'ayahs': '75 آية'},
      {'number': '9', 'name': 'التوبة', 'ayahs': '129 آية'},
      {'number': '10', 'name': 'يونس', 'ayahs': '109 آيات'},
    ];

    return Container(
      // Apply a soft background gradient
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.softLavender,
            AppColors.background,
            AppColors.cream,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Display the top page header
            const _QuranHeader(),

            const SizedBox(height: 18),

            // Display quick summary card
            const _QuranSummaryCard(),

            const SizedBox(height: 18),

            // Display the list of surahs
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                itemCount: surahs.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final surah = surahs[index];

                  return _SurahCard(
                    number: surah['number']!,
                    name: surah['name']!,
                    ayahs: surah['ayahs']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Display the top page header
class _QuranHeader extends StatelessWidget {
  const _QuranHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'المصحف الشريف',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPurple,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'اختر السورة التي ترغب بقراءتها',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Display a summary card at the top of the screen
class _QuranSummaryCard extends StatelessWidget {
  const _QuranSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF5B3D78),
              Color(0xFF7A5895),
              Color(0xFFB494C4),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ابدأ تلاوتك بهدوء وسكينة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'واجهة مرتبة تساعدك على الوصول السريع إلى السور.',
                    style: TextStyle(
                      color: Color(0xFFF8ECFF),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable card for each surah
class _SurahCard extends StatelessWidget {
  final String number;
  final String name;
  final String ayahs;

  const _SurahCard({
    required this.number,
    required this.name,
    required this.ayahs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(22),
      elevation: 1.5,
      shadowColor: AppColors.primary.withOpacity(0.10),
      child: InkWell(
        // Handle tapping on a surah card
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم اختيار سورة $name'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Display surah number
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Display surah name and ayah count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.deepPurple,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ayahs,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Display arrow icon
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}