// lib/book_pages/_template.dart
import 'package:flutter/material.dart';
import '../reader/book_configs.dart';
import '../reader/reader_swipe_clean.dart';

class BookDetailTemplate extends StatelessWidget {
  const BookDetailTemplate({
    super.key,

    // Book powers "Read Me" and front matter (optional so Bones can be const without a book)
    this.book,

    // Display fields (you already use these on your pages)
    this.title,          // falls back to book?.title
    this.subtitle,
    this.coverAsset,     // falls back to book?.coverAsset
    this.tagline,
    this.description,
    this.topReview,
    this.reviews,

    // Controls
    this.showButtons = true,                  // shows READ ME if a book is present
    this.showAudioButton = false,             // optional 2nd button
    this.audioOnPressed,                      // handler for audiobook
    this.primaryButtonLabel = 'READ ME',      // restore your old label
    this.secondaryButtonLabel = 'Audiobook',
    this.showFrontMatterPreview = false,      // keep OFF to avoid scroll of FM here
    this.comingSoon = false,
  });

  final BookConfig? book;

  final String? title;
  final String? subtitle;
  final String? coverAsset;
  final String? tagline;
  final String? description;
  final String? topReview;
  final List<String>? reviews;

  final bool showButtons;
  final bool showAudioButton;
  final VoidCallback? audioOnPressed;
  final String primaryButtonLabel;
  final String secondaryButtonLabel;
  final bool showFrontMatterPreview;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final hasBook = book != null;
    final String displayTitle = (title ?? (hasBook ? book!.title : '')).trim();
    final String displayCover = (coverAsset ?? (hasBook ? book!.coverAsset : '')).trim();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (displayCover.isNotEmpty) Image.asset(displayCover, height: 320),
              const SizedBox(height: 12),

              if (displayTitle.isNotEmpty) ...[
                Text(
                  displayTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: .2),
                ),
                if ((subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 8),
              ],

              if ((tagline ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    tagline!.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),

              if ((description ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Text(
                    description!.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.45),
                  ),
                ),

              if ((topReview ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    '“${topReview!.trim()}”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.45),
                  ),
                ),

              if (comingSoon)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 12),
                  child: Text('Coming Soon', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

              // Buttons row (READ ME + optional Audiobook)
              if (!comingSoon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasBook && showButtons)
                      ElevatedButton(
                        onPressed: () {
                          final fmItems = book!.frontMatter.map((p) => FrontMatterItem(p)).toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderSwipeClean(
                                title: book!.title,
                                author: 'Paul Slatter',
                                coverAsset: book!.coverAsset,
                                chaptersDir: 'assets/chapters/${book!.key}',
                                maxChapters: book!.chapterCount,
                                frontMatter: fmItems,
                                startAt: ReaderStart.cover,
                              ),
                            ),
                          );
                        },
                        child: Text(primaryButtonLabel),
                      ),
                    if (hasBook && showButtons && showAudioButton) const SizedBox(width: 12),
                    if (showAudioButton)
                      OutlinedButton(
                        onPressed: audioOnPressed ??
                            () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$secondaryButtonLabel coming soon')),
                                ),
                        child: Text(secondaryButtonLabel),
                      ),
                  ],
                ),

              const SizedBox(height: 12),

              if (reviews != null && reviews!.isNotEmpty)
                Column(
                  children: [
                    for (final r in reviews!)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Text(
                          r,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700, height: 1.45),
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                ),

              // Front-matter preview (off by default to keep detail pages clean)
              if (hasBook && showFrontMatterPreview)
                FutureBuilder<List<String>>(
                  future: loadFrontMatterTexts(book!),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      );
                    }
                    final pages = snap.data ?? const [];
                    if (pages.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        for (final t in pages)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              t,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
