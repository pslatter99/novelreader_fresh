// lib/book_pages/book_burn_page.dart
import 'package:flutter/material.dart';
import '../reader/book_configs.dart';
import '_template.dart';

class BookBurnPage extends StatelessWidget {
  const BookBurnPage({super.key});

  @override
  Widget build(BuildContext context) {
    const deepRed = Color(0xFFB71C1C);
    const boldWhite = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      letterSpacing: .5,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    return Theme(
      data: Theme.of(context).copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: deepRed,
            foregroundColor: Colors.white,
            textStyle: boldWhite,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: deepRed, // make it match the primary button
            foregroundColor: Colors.white,
            textStyle: boldWhite,
            shape: shape,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ),
      child: BookDetailTemplate(
        book: burn,
        title: 'Burn',
        subtitle: 'Book One',
        coverAsset: 'assets/images/burn-cover.webp',
        tagline: 'If you like Carl Hiaasen — you’ll love this.',
        // taglineOnTop: true, // ← removed line
        description:
            'In tranquil Vancouver a charred corpse and a paralyzed woman drag a washed-up PI into a darkly funny world of arson, models, and buried secrets.',
        reviews: const [
          '⭐️⭐️⭐️⭐️⭐️ — Slatter is a genius!\nThe dialogue, pace, and twisted humor in this book made it one of the most unique thrillers I\'ve ever read. Slatter manages to surprise at every turn.',
          '⭐️⭐️⭐️⭐️⭐️ — Unputdownable\nDarkly funny, stylish, violent, and surprisingly heartfelt. Slatter has created something unique with “Burn.”',
          '⭐️⭐️⭐️⭐️⭐️ — Dark, fast, funny\nA brilliant mix of crime, dark humour, and unforgettable characters. Felt like I was watching a Netflix thriller in book form.',
        ],
        showButtons: true,
        showAudioButton: true,
        primaryButtonLabel: 'READ ME',
        secondaryButtonLabel: 'AUDIOBOOK',
        audioOnPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audiobook coming soon')),
          );
        },
        showFrontMatterPreview: false,
      ),
    );
  }
}
