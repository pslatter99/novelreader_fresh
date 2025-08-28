import 'package:flutter/material.dart';
import '_template.dart';
import '../reader/book_configs.dart';

class BookTrustmePage extends StatelessWidget {
  const BookTrustmePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookDetailTemplate(
      title: 'Trust Me',
      coverAsset: 'assets/images/trust-me-front-cover-paul-slatter.webp',
      description:
          'A woman’s life is turned upside down when a dangerous man from her past resurfaces, forcing her to confront the lies she’s been living.',
      topReview:
          'Great plots, plenty of sex. Lots of fun characters—all in all a great read. A real page-turner. I really enjoyed the whole book.',
      book: BookConfig.trustme,
    );
  }
}
