import 'package:flutter/material.dart';
import '_template.dart';
import '../reader/book_configs.dart';

class BookDraculiPage extends StatelessWidget {
  const BookDraculiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BookDetailTemplate(
      title: 'The Disciples of Coont Draculi',
      coverAsset: 'assets/images/disciples-of-coont-draculi-cover.webp',
      tagline: 'Blood? Crack cocaine? – Never mix your drinks.',
      description:
          'A twisted vampire tale from medieval Europe to modern Vancouver. Dark, outrageous, and deliciously depraved.',
      book: draculi,
    );
  }
}
