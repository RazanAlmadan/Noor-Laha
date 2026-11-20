import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_settings.dart';

// About screen.
// NOTE: the wording below is a placeholder.
// Replace it with the text the client approves.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'عن التطبيق',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: colors.backgroundTop,
        foregroundColor: colors.title,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.backgroundTop, colors.background],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              // App name.
              Text(
                'نور لها',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.title,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Short description.
              Text(
                'تطبيق لقراءة القرآن الكريم،\n'
                    'صدقة جارية يُهدى ثوابها للمرحومة بإذن الله.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.bodyText,
                  fontSize: 17,
                  height: 1.9,
                ),
              ),

              const SizedBox(height: 28),

              // Dedication card.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'اللهم اجعل نور القرآن\nنورًا لها في قبرها',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              const _CreditsCard(),

              const SizedBox(height: 22),

              // App version.
              Text(
                'الإصدار $kAppVersion',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedText, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Thanks and sources: required attribution for the Quran text and fonts.
class _CreditsCard extends StatelessWidget {
  const _CreditsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    const List<(String, String)> items = [
      (
      'نص القرآن الكريم',
      'مشروع Tanzil (tanzil.net)، الرسم العثماني، برخصة CC BY 3.0',
      ),
      (
      'خط المصحف',
      'Amiri Quran وScheherazade New، برخصة SIL OFL',
      ),
      (
      'خط الواجهة',
      'Tajawal، برخصة SIL OFL',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الشكر والمصادر',
            style: TextStyle(
              color: colors.title,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          for (final (String title, String source) in items) ...[
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: colors.bodyText,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              source,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
