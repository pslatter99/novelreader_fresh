import 'package:flutter/material.dart';
import '_template.dart';

class BookLoserPage extends StatelessWidget {
  const BookLoserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookDetailTemplate(
      title: 'Loser',
      coverAsset: 'assets/images/loser-cover.webp',
      tagline: 'Sex, sun, and secrets — paradise has a dark side.',
      description:
          'Take a dangerously seductive detour into Thailand’s sun-soaked chaos—through tropical beaches, Muay Thai boxing, beautiful women… and ladyboys.',
      comingSoon: true,
      showButtons: false,
    );
  }
}
