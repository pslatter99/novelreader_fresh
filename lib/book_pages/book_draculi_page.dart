// lib/book_pages/book_draculi_page.dart
import 'package:flutter/material.dart';
import '../reader/book_configs.dart';
import '_template.dart';
import '../audio/audiobook_player.dart';

class BookDraculiPage extends StatelessWidget {
  const BookDraculiPage({super.key});

  @override
  Widget build(BuildContext context) {
    const deepRed = Color(0xFFB71C1C);
    const boldWhite = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      letterSpacing: .5,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );

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
            backgroundColor: deepRed, // match primary
            foregroundColor: Colors.white,
            textStyle: boldWhite,
            shape: shape,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ),
      child: BookDetailTemplate(
        book: draculi,
        title: 'The Disciples of Coont Draculi',
        coverAsset: 'assets/images/disciples-of-coont-draculi-cover.webp',
        tagline: 'Blood? Crack cocaine? – Never mix your drinks.',
        description:
            'A twisted vampire tale from medieval Europe to modern Vancouver. Dark, outrageous, and deliciously depraved.',

        // 🔴 Buttons
        showButtons: true,
        showAudioButton: true,
        primaryButtonLabel: 'READ ME',
        secondaryButtonLabel: 'AUDIOBOOK',
        audioOnPressed: () {
          // Use RELATIVE asset paths (no "assets/" prefix)
          final paths = List<String>.generate(
            28,
            (i) => 'audio/draculi/draculi_CHAPTER_${i + 1}.mp3',
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AudiobookPlayerScreen(
                book: draculi,
                chapterAudioPaths: paths,
              ),
            ),
          );
        },
      ),
    );
  }
}
