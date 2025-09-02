import "../reader/book_configs.dart";
import 'package:flutter/material.dart';
import '_template.dart';

class BookLoserPage extends StatelessWidget {
  const BookLoserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BookDetailTemplate(
      book: loser, // <-- this powers FM + chapters
      tagline: 'Sex, sun, and secrets — paradise has a dark side.',
      description:
          'Take a dangerously seductive detour into Thailand’s sun-soaked chaos—through tropical beaches, Muay Thai boxing, beautiful women… and ladyboys.',
      showButtons: true,
      comingSoon: false,
    );
  }
}
