// lib/book_pages/_template.dart
import 'package:flutter/material.dart';
import '../reader/book_configs.dart';
import '../reader/reader_swipe_clean.dart';

/// ONE top-level helper: order FM and choose which pages scroll.
/// Order: title_page -> copyright -> also_by -> for_page -> title_page_2
List<FrontMatterItem> _canonicalizeFrontMatter(List<String> fmPaths) {
  String _name(String p) => p.split('/').last.toLowerCase();
  String? _find(String suffix) {
    for (final p in fmPaths) {
      if (_name(p).endsWith(suffix)) return p;
    }
    return null;
  }

  final items = <FrontMatterItem>[];

  final pTitle1    = _find('_title_page.txt');
  final pCopyright = _find('_copyright.txt');
  final pAlsoBy    = _find('_also_by.txt');
  final pForPage   = _find('_for_page.txt');
  final pTitle2    = _find('_title_page_2.txt');

  if (pTitle1 != null)    items.add(FrontMatterItem(pTitle1,    scrollable: false));
  if (pCopyright != null) items.add(FrontMatterItem(pCopyright, scrollable: true)); // ONLY copyright scrolls
  if (pAlsoBy != null)    items.add(FrontMatterItem(pAlsoBy,    scrollable: false));
  if (pForPage != null)   items.add(FrontMatterItem(pForPage,   scrollable: false)); // make true if you want it scrollable
  if (pTitle2 != null)    items.add(FrontMatterItem(pTitle2,    scrollable: false));

  // Append any extras not matched above (non-scrollable)
  final used = items.map((i) => i.assetPath).toSet();
  for (final p in fmPaths) {
    if (!used.contains(p)) items.add(FrontMatterItem(p, scrollable: false));
  }
  return items;
}

class BookDetailTemplate extends StatelessWidget {
  const BookDetailTemplate({
    super.key,
    this.book,
    this.title,
    this.subtitle,
    this.coverAsset,
    this.tagline,
    this.description,
    this.topReview,
    this.reviews,
    this.showButtons = true,
    this.showAudioButton = false,
    this.audioOnPressed,
    this.primaryButtonLabel = 'READ ME',
    this.secondaryButtonLabel = 'Audiobook',
    this.showFrontMatterPreview = false,
    this.comingSoon = false,
  });

  // fields
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

    // Use the helper above
    final fmItems = hasBook
        ? _canonicalizeFrontMatter(book!.frontMatter)
        : const <FrontMatterItem>[];

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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderSwipeClean(
                                title: book!.title,
                                author: 'Paul Slatter',
                                coverAsset: book!.coverAsset,
                                chaptersDir: 'assets/chapters/${book!.key}',
                                maxChapters: book!.chapterCount,
                                frontMatter: fmItems, // ordered/scrollable FM
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

              // Optional: preview FM on the detail page (off by default)
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
