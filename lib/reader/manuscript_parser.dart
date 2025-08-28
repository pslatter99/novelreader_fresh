// lib/reader/manuscript_parser.dart
import 'dart:convert';

class Manuscript {
  final List<FrontMatter> front;
  final List<Chapter> chapters;
  Manuscript({required this.front, required this.chapters});
}

class FrontMatter {
  final String title;
  final String body;
  FrontMatter({required this.title, required this.body});
}

class Chapter {
  final String title;
  final String body;
  Chapter({required this.title, required this.body});
}

class ManuscriptParser {
  // PROLOGUE / EPILOGUE / CHAPTER <num|roman|words> [— or - optional subtitle...]
  static final RegExp _headingRe = RegExp(
    r'^(?:PROLOGUE|EPILOGUE|CHAPTER\s+(?:\d+|[IVXLCDM]+|[A-Z][A-Z\- ]+))(?:\s*[—–-].*)?$',
    caseSensitive: false,
    multiLine: true,
  );

  static Manuscript parse(String raw) {
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    // Split out a front section if we see a chapter-prologue heading later
    final firstMatch = _headingRe.firstMatch(text);
    final frontText = (firstMatch == null) ? text : text.substring(0, firstMatch.start).trim();
    final chaptersText = (firstMatch == null) ? '' : text.substring(firstMatch.start).trim();

    // ---- Front matter pages (optional) ----
    final front = <FrontMatter>[];
    if (frontText.isNotEmpty) {
      final blocks = frontText
          .split(RegExp(r'^\s*===PAGE===\s*$', multiLine: true))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      for (final b in blocks) {
        front.add(FrontMatter(title: _frontTitleFor(b), body: _frontBodyFor(b)));
      }
    }

    // ---- Chapters ----
    var chapters = <Chapter>[];
    if (chaptersText.isNotEmpty) {
      final matches = _headingRe.allMatches(chaptersText).toList();
      for (int i = 0; i < matches.length; i++) {
        final m = matches[i];
        final start = m.end;
        final end = (i + 1 < matches.length) ? matches[i + 1].start : chaptersText.length;
        final title = chaptersText.substring(m.start, m.end).trim().toUpperCase();
        final body = chaptersText.substring(start, end).trim();
        if (body.isNotEmpty) chapters.add(Chapter(title: title, body: body));
      }

      // ✅ If the first chapter we found is not CHAPTER 1 but CHAPTER 1 exists later
      // (common when a TABLE OF CONTENTS appears first), rotate the list so it
      // starts at CHAPTER 1. Keep PROLOGUE first if present.
      final idxCh1 = chapters.indexWhere((c) =>
          RegExp(r'^CHAPTER\s+(1|ONE|I)\b', caseSensitive: false).hasMatch(c.title));
      final prologueFirst = chapters.isNotEmpty &&
          RegExp(r'^PROLOGUE\b', caseSensitive: false).hasMatch(chapters.first.title);

      if (!prologueFirst && idxCh1 > 0) {
        chapters = [...chapters.sublist(idxCh1), ...chapters.sublist(0, idxCh1)];
      }
    }

    // Fallback: single-chapter book
    if (chapters.isEmpty && text.isNotEmpty) {
      chapters.add(Chapter(title: 'FULL TEXT', body: text));
    }

    return Manuscript(front: front, chapters: chapters);
  }

  static String _frontTitleFor(String block) {
    final lines = block.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (lines.isNotEmpty && lines.first.length <= 40 && _likelyHeading(lines.first)) {
      return lines.first.toUpperCase();
    }
    final up = block.toUpperCase();
    if (up.contains('COPYRIGHT')) return 'COPYRIGHT';
    if (up.contains('DEDICATION')) return 'DEDICATION';
    if (up.contains('ALSO BY')) return 'ALSO BY';
    if (up.contains('ACKNOWLEDG')) return 'ACKNOWLEDGMENTS';
    if (up.contains('TITLE')) return 'TITLE';
    return 'FRONT MATTER';
  }

  static String _frontBodyFor(String block) {
    final lines = block.split('\n');
    if (lines.isEmpty) return block.trim();
    final first = lines.first.trim();
    if (first.length <= 40 && _likelyHeading(first)) {
      return lines.skip(1).join('\n').trim();
    }
    return block.trim();
  }

  static bool _likelyHeading(String s) =>
      RegExp(r'^[A-Z0-9 \-–—:]+$').hasMatch(s.toUpperCase());
}
