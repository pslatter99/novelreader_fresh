import "../reader/book_configs.dart";
import 'package:flutter/material.dart';
import '_template.dart';

class BookBonesPage extends StatelessWidget {
  const BookBonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookDetailTemplate(
      title: 'Bones In The Water',
      coverAsset: 'assets/images/bones-in-the-water-cover.webp',
      description:
          'While tracking a missing woman in sordid Pattaya, a Thai detective uncovers a chilling world of body disposal and murder-for-hire.',
      comingSoon: true,
      showButtons: false,
    );
  }
}
