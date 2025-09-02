// lib/reader/book_configs.dart
import 'package:flutter/services.dart' show rootBundle;

class BookConfig {
  final String key;                 // e.g., "rocksolid"
  final String title;               // e.g., "Rock Solid"
  final String coverAsset;          // e.g., assets/images/rock-...webp
  final int chapterCount;           // e.g., 41
  final List<String> frontMatter;   // ordered pages (title, also_by, copyright, foreword, etc.)
  final List<String> chapterTitles; // chNN_title.txt
  final List<String> chapterBodies; // chNN_<key>_body.txt

  const BookConfig({
    required this.key,
    required this.title,
    required this.coverAsset,
    required this.chapterCount,
    required this.frontMatter,
    required this.chapterTitles,
    required this.chapterBodies,
  });
}

// helpers
String _p2(int n) => n.toString().padLeft(2, '0');
List<String> _titles(String key, int count) =>
    List.generate(count, (i) => 'assets/chapters/$key/ch${_p2(i + 1)}_title.txt');

List<String> _bodies(String key, int count) =>
    List.generate(count, (i) => 'assets/chapters/$key/ch${_p2(i + 1)}_${key}_body.txt');

// You can include more FM pages—reader should try/catch missing ones.
List<String> _frontMatter(String key) => [
  'assets/front_matter/${key}_title_page.txt',
  'assets/front_matter/${key}_title_page_2.txt',
  'assets/front_matter/${key}_also_by.txt',
  'assets/front_matter/${key}_copyright.txt',
  'assets/front_matter/${key}_for_page.txt',
];

final burn = BookConfig(
  key: 'burn',
  title: 'Burn',
  coverAsset: 'assets/images/burn-cover.webp',
  chapterCount: 39,
  frontMatter: _frontMatter('burn'),
  chapterTitles: _titles('burn', 39),
  chapterBodies: _bodies('burn', 39),
);

final rocksolid = BookConfig(
  key: 'rocksolid',
  title: 'Rock Solid',
  coverAsset: 'assets/images/rock-solid-vancouver-kenya-thailand-thriller.webp',
  chapterCount: 41,
  frontMatter: _frontMatter('rock_solid'), // note front_matter filenames use rock_solid_ prefix
  chapterTitles: _titles('rocksolid', 41),
  chapterBodies: _bodies('rocksolid', 41),
);

final trustme = BookConfig(
  key: 'trustme',
  title: 'Trust Me',
  coverAsset: 'assets/images/trust-me-front-cover-paul-slatter.webp',
  chapterCount: 19,
  frontMatter: _frontMatter('trust_me'),
  chapterTitles: _titles('trustme', 19),
  chapterBodies: _bodies('trustme', 19),
);

final draculi = BookConfig(
  key: 'draculi',
  title: 'The Disciples of Coont Draculi',
  coverAsset: 'assets/images/disciples-of-coont-draculi-cover.webp',
  chapterCount: 28,
  frontMatter: _frontMatter('draculi'),
  chapterTitles: _titles('draculi', 28),
  chapterBodies: _bodies('draculi', 28),
);

final loser = BookConfig(
  key: 'loser',
  title: 'Loser',
  coverAsset: 'assets/images/loser-cover.webp',
  chapterCount: 13,
  frontMatter: _frontMatter('loser'),
  chapterTitles: _titles('loser', 13),
  chapterBodies: _bodies('loser', 13),
);

// Optional: a lookup map if you route by key
final booksByKey = {
  'burn': burn,
  'rocksolid': rocksolid,
  'trustme': trustme,
  'draculi': draculi,
  'loser': loser,
};

// Utility to load a text file safely (skips missing FM pages)
Future<List<String>> loadFrontMatterTexts(BookConfig book) async {
  final texts = <String>[];
  for (final path in book.frontMatter) {
    try {
      final t = await rootBundle.loadString(path);
      if (t.trim().isNotEmpty) texts.add(t);
    } catch (_) {
      // ignore missing page
    }
  }
  return texts;
}
