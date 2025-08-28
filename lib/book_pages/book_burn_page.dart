// lib/book_pages/book_burn_page.dart
import 'package:flutter/material.dart';
import '../reader/book_configs.dart';
import '_template.dart';

class BookBurnPage extends StatelessWidget {
  const BookBurnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookDetailTemplate(
      title: 'Burn',
      subtitle: 'Book One',
      coverAsset: 'assets/images/burn-cover.webp',
      tagline: 'If you like Carl Hiaasen — you’ll love this.',
      description:
          'In tranquil Vancouver a charred corpse and a paralyzed woman drag a washed-up PI into a darkly funny world of arson, models, and buried secrets.',
      // Reviews shown UNDER the buttons (centered + bold)
      reviews: [
        '⭐️⭐️⭐️⭐️⭐️ — Slatter is a genius!\nThe dialogue, pace, and twisted humor in this book made it one of the most unique thrillers I\'ve ever read. Slatter manages to surprise at every turn.',
        '⭐️⭐️⭐️⭐️⭐️ — Unputdownable\nDarkly funny, stylish, violent, and surprisingly heartfelt. Slatter has created something unique with “Burn.”',
        '⭐️⭐️⭐️⭐️⭐️ — Dark, fast, funny\nA brilliant mix of crime, dark humour, and unforgettable characters. Felt like I was watching a Netflix thriller in book form.',
      ],
      book: BookConfig.burn,
    );
  }
}
