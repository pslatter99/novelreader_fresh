// lib/reader/book_configs.dart

/// Immutable config for a book used by the reader.
class BookConfig {
  final String id;
  final String title;
  final String coverAsset;
  final String? textAsset;        // e.g., 'assets/books/burn_full.txt'
  final int paywallChapterGate;   // reserved for later (e.g., lock after Chapter 5)

  const BookConfig({
    required this.id,
    required this.title,
    required this.coverAsset,
    this.textAsset,
    this.paywallChapterGate = 5,
  });

  // —— Known books ——
  static const burn = BookConfig(
  id: 'burn',
  title: 'Burn',
  coverAsset: 'assets/images/burn-cover.webp',
  textAsset: 'assets/manuscripts/burn.txt', // <-- actual path
  paywallChapterGate: 5,
);


  static const rocksolid = BookConfig(
    id: 'rocksolid',
    title: 'Rock Solid',
    coverAsset: 'assets/images/rock-solid-vancouver-kenya-thailand-thriller.webp',
  );

  static const trustme = BookConfig(
    id: 'trustme',
    title: 'Trust Me',
    coverAsset: 'assets/images/trust-me-front-cover-paul-slatter.webp',
  );

  static const draculi = BookConfig(
    id: 'draculi',
    title: 'The Disciples of Coont Draculi',
    coverAsset: 'assets/images/disciples-of-coont-draculi-cover.webp',
  );
}
