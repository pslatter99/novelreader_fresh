// lib/book_pages/_template.dart
import 'package:flutter/material.dart';
import '../components/stars.dart';

// Reader
import '../reader/book_configs.dart';
import '../reader/reader_swipe_clean.dart';

class BookDetailTemplate extends StatelessWidget {
  const BookDetailTemplate({
    super.key,
    required this.title,
    this.subtitle,
    required this.coverAsset,
    this.tagline,
    required this.description,
    this.comingSoon = false,
    this.showButtons = true,
    this.topReview,
    this.book,
    this.reviews = const <String>[],
  });

  final String title;
  final String? subtitle;
  final String coverAsset;
  final String? tagline;
  final String description;
  final bool comingSoon;
  final bool showButtons;
  final String? topReview;
  final BookConfig? book;
  final List<String> reviews;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: .3,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: const Text(
          'NovelReader',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Stars(size: 22),

            if (tagline != null) ...[
              const SizedBox(height: 8),
              Text(
                tagline!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],

            const SizedBox(height: 14),

            // Cover (responsive)
            Center(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final imgW = w > 340 ? 320.0 : w * 0.9;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      coverAsset,
                      width: imgW,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Title + optional subtitle
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, textAlign: TextAlign.center),
            ],

            const SizedBox(height: 14),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            // Buttons
            if (showButtons && !comingSoon) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    style: buttonStyle,
                    onPressed: () {
                      if (book == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reader not configured yet for this book.'),
                          ),
                        );
                        return;
                      }
                      final cfg = book!;

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReaderSwipeClean(
                            // ✅ use the per-chapter folder:
                            chaptersDir: 'assets/chapters/burn',
                            // (fallback single-file mode is still supported via assetPath if you ever need it)

                            title: cfg.title,
                            coverAsset: cfg.coverAsset,
                            author: 'Paul Slatter',
                            startAt: ReaderStart.cover,
                            maxChapters: 39,
                            frontMatter: const [
                              FrontMatterItem('assets/front_matter/burn_copyright.txt', scrollable: true),
                              FrontMatterItem('assets/front_matter/burn_also_by.txt'),
                              FrontMatterItem('assets/front_matter/burn_for_page.txt'),
                              FrontMatterItem('assets/front_matter/burn_title_page_2.txt'),
                            ],
                          ),
                        ),
                      );
                    },
                    child: const Text('READ NOW'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: buttonStyle,
                    onPressed: () {},
                    child: const Text('AUDIOBOOK'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Featured review (optional)
            if (topReview != null) ...[
              Text(
                '"$topReview"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
            ],

            // Reviews list (centered + bold)
            if (reviews.isNotEmpty) ...[
              ...reviews.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    r,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (comingSoon)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
