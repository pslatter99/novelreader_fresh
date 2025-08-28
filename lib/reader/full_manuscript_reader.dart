// lib/reader/full_manuscript_reader.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'manuscript_parser.dart';
import 'paginator.dart';

class FullManuscriptReader extends StatefulWidget {
  final String assetPath;
  final String title;
  final String? coverAsset;   // cover page first
  final String? author;       // for title page
  final int? lockedAfterChapter;
  final int initialChapterIndex;

  const FullManuscriptReader({
    super.key,
    required this.assetPath,
    required this.title,
    this.coverAsset,
    this.author,
    this.lockedAfterChapter,
    this.initialChapterIndex = 0,
  });

  @override
  State<FullManuscriptReader> createState() => _FullManuscriptReaderState();
}

class _FullManuscriptReaderState extends State<FullManuscriptReader> {
  Manuscript? _ms;
  bool _loading = true;

  final List<_PageEntry> _pages = [];
  final Map<int, int> _chapterStartPage = {};
  final List<String> _chapterTitles = [];

  late final PageController _controller;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(widget.assetPath);
      final ms = ManuscriptParser.parse(raw);
      setState(() {
        _ms = ms;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _ms = Manuscript(front: [], chapters: [
          Chapter(title: 'ERROR', body: 'Failed to load ${widget.assetPath}\n$e')
        ]);
        _loading = false;
      });
    }
  }

  void _paginate(Size avail) {
    if (_ms == null) return;

    if (_lastSize != null) {
      final dw = (_lastSize!.width - avail.width).abs();
      final dh = (_lastSize!.height - avail.height).abs();
      if (dw < 1 && dh < 1) return;
    }
    _lastSize = avail;

    const bodyStyle = TextStyle(fontSize: 18, height: 1.4);
    const frontStyle = TextStyle(fontSize: 18, height: 1.35);

    _pages.clear();
    _chapterStartPage.clear();
    _chapterTitles.clear();

    // 0) Cover
    if ((widget.coverAsset ?? '').isNotEmpty) {
      _pages.add(_PageEntry.cover(widget.coverAsset!));
    }

    // 1) Title page
    final author = (widget.author ?? '').trim();
    _pages.add(_PageEntry.title(
      widget.title.toUpperCase(),
      author.isEmpty ? '' : 'A NOVEL BY\n\n$author',
    ));

    // 2) Front-matter: paginate into multiple centered pages (no overflow)
    for (final fm in _ms!.front) {
      final chunks = Paginator.paginate(
        text: fm.body,
        style: frontStyle,
        pageSize: avail,
        textDirection: TextDirection.ltr,
      );
      if (chunks.isEmpty) {
        _pages.add(_PageEntry.front(fm.title, ''));
      } else {
        for (int i = 0; i < chunks.length; i++) {
          final t = i == 0 ? fm.title : ''; // title only on first page of that block
          _pages.add(_PageEntry.front(t, chunks[i]));
        }
      }
    }

    // 3) Chapters: keep “CHAPTER …” only and cap at 39
    final chapterList = _ms!.chapters
        .where((c) => c.title.toUpperCase().startsWith('CHAPTER '))
        .take(39)
        .toList();

    for (int i = 0; i < chapterList.length; i++) {
      final ch = chapterList[i];
      _chapterTitles.add(ch.title);
      _chapterStartPage[i] = _pages.length;

      _pages.add(_PageEntry.chapterTitle(ch.title));

      final bodyPages = Paginator.paginate(
        text: ch.body,
        style: bodyStyle,
        pageSize: avail,
        textDirection: Directionality.of(context),
      );

      final locked = (widget.lockedAfterChapter != null && (i + 1) > widget.lockedAfterChapter!);
      if (locked) {
        _pages.add(_PageEntry.locked(
          ch.title,
          'This chapter is locked. Subscribe or purchase to continue.',
        ));
        continue;
      }
      for (final p in bodyPages) {
        _pages.add(_PageEntry.body(ch.title, p));
      }
    }

    // Jump to requested chapter start
    final jumpChapter = widget.initialChapterIndex.clamp(0, (_chapterTitles.length - 1));
    final startPage = _chapterStartPage[jumpChapter] ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.jumpToPage(startPage);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.orange,
        actions: [
          // Dropdown is available from the start (includes a “Back” item)
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              hint: const Icon(Icons.menu_book, color: Colors.black),
              onChanged: (i) {
                if (i == null) return;
                if (i == -1) {
                  Navigator.of(context).maybePop();
                  return;
                }
                final pg = _chapterStartPage[i] ?? 0;
                _controller.animateToPage(
                  pg,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              },
              items: [
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text('◀︎ Back', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                for (int i = 0; i < _chapterTitles.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(_chapterTitles[i],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (_, constraints) {
                final avail = Size(
                  constraints.maxWidth - 36,
                  constraints.maxHeight - 48,
                );
                _paginate(avail);
                return PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _PageViewCard(entry: _pages[i]),
                );
              },
            ),
    );
  }
}

// ---- Page rendering ----------------------------------------------------------

class _PageViewCard extends StatelessWidget {
  final _PageEntry entry;
  const _PageViewCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: entry.type == _PageType.chapterTitle ? 22 : 18,
      fontWeight: entry.type == _PageType.chapterTitle ? FontWeight.w900 : FontWeight.w800,
    );

    Widget child;
    switch (entry.type) {
      case _PageType.cover:
        child = Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Image.asset(entry.content, fit: BoxFit.contain),
          ),
        );
        break;
      case _PageType.title:
        child = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              if (entry.content.isNotEmpty)
                Text(entry.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
        );
        break;
      case _PageType.front:
        child = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.title.isNotEmpty)
                Text(entry.title, textAlign: TextAlign.center, style: titleStyle),
              if (entry.title.isNotEmpty) const SizedBox(height: 14),
              Text(entry.content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, height: 1.35)),
            ],
          ),
        );
        break;
      case _PageType.chapterTitle:
        child = Center(
          child: Text(entry.title, textAlign: TextAlign.center, style: titleStyle),
        );
        break;
      case _PageType.body:
        child = SelectableText(
          entry.content,
          textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 18, height: 1.4),
        );
        break;
      case _PageType.locked:
        child = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.title, textAlign: TextAlign.center, style: titleStyle),
              const SizedBox(height: 14),
              Text(entry.content, textAlign: TextAlign.center),
            ],
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(padding: const EdgeInsets.fromLTRB(14, 18, 14, 18), child: child),
      ),
    );
  }
}

enum _PageType { cover, title, front, chapterTitle, body, locked }

class _PageEntry {
  final _PageType type;
  final String title;
  final String content;
  _PageEntry._(this.type, this.title, this.content);

  factory _PageEntry.cover(String asset) => _PageEntry._(_PageType.cover, '', asset);
  factory _PageEntry.title(String title, String subtitle) =>
      _PageEntry._(_PageType.title, title, subtitle);
  factory _PageEntry.front(String title, String body) =>
      _PageEntry._(_PageType.front, title, body);
  factory _PageEntry.chapterTitle(String title) =>
      _PageEntry._(_PageType.chapterTitle, title, '');
  factory _PageEntry.body(String title, String page) =>
      _PageEntry._(_PageType.body, title, page);
  factory _PageEntry.locked(String title, String msg) =>
      _PageEntry._(_PageType.locked, title, msg);
}
