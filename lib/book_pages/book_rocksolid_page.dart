import 'package:flutter/material.dart';
import '_template.dart';
import '../reader/book_configs.dart';

class BookRocksolidPage extends StatelessWidget {
  const BookRocksolidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BookDetailTemplate(
      title: 'Rock Solid',
      subtitle: 'Book Two',
      coverAsset: 'assets/images/rock-solid-vancouver-kenya-thailand-thriller.webp',
      description:
          'Blackmail spreads from Bangkok brothels to million dollar yachts as greed and madness pull a PI deeper into a surreal spiral of crime and chaos.',
      topReview: 'A relentless, gritty ride with humor and heart.',
      book: rocksolid,
    );
  }
}
