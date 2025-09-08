import 'package:flutter/material.dart';
import '../reader/book_configs.dart';

class AudiobookPlaceholderScreen extends StatelessWidget {
  final BookConfig book;
  const AudiobookPlaceholderScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${book.title} — Audiobook')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Audiobook player coming soon.\n\n'
            'This is a temporary screen so the button works today.\n'
            'Next step: add real audio + resume + paywall.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
        ),
      ),
    );
  }
}
