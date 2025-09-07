// lib/reader/reader_swipe_clean.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../paywall/access.dart';
import '../paywall/paywall_screen.dart';

enum ReaderStart { cover, title, chapter1 }

class FrontMatterItem {
  final String assetPath;
  final bool scrollable;
  const FrontMatterItem(this.assetPath, {this.scrollable = false});
}

// =================== Top chrome ======================
class _TopChrome extends StatelessWidget {
  final VoidCallback onBack;
  final int currentChapter; // 1-based
  final int maxChapters;
  final ValueChanged<int> onSelectChapter;

  const _TopChrome({
    super.key,
    required this.onBack,
    required this.currentChapter,
    required this.maxChapters,
    required this.onSelectChapter,
  });

  @override
  Widget build(BuildContext context) {
    final int safeValue = currentChapter < 1
        ? 1
        : (currentChapter > maxChapters ? maxChapters : currentChapter);

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(.65), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
              tooltip: 'Back',
            ),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: safeValue,
                alignment: Alignment.centerRight,
                dropdownColor: Colors.black87,
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                items: List.generate(maxChapters, (i) {
                  final ch = i + 1;
                  return DropdownMenuItem<int>(value: ch, child: Text('Chapter $ch'));
                }),
                onChanged: (v) {
                  if (v != null) onSelectChapter(v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================= Page model ==============================
enum _PageType { cover, title, frontText, chapterTitle, chapterBody }

class ReaderSwipeClean extends StatefulWidget {
  const ReaderSwipeClean({
    super.key,
    this.assetPath,            // fallback: single manuscript file
    this.chaptersDir,          // preferred: folder with chXX_title.txt + chXX_<book>_body.txt
    required this.title,
    required this.coverAsset,
    required this.author,
    this.startAt = ReaderStart.cover,
    this.maxChapters,
    this.frontMatter = const [],
  });

  final String? assetPath;
  final String? chaptersDir;
  final String title;
  final String coverAsset;
  final String author;
  final ReaderStart startAt;
  final int? maxChapters;
  final List<FrontMatterItem> frontMatter;

  @override
  State<ReaderSwipeClean> createState() => _ReaderSwipeCleanState();
}

class _ReaderSwipeCleanState extends State<ReaderSwipeClean> {
  // ===== constants =====
  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 18,
    height: 1.5,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );
  static const double _CAP_FUDGE = 0.88;
  static const double _PAGE_PAD_TOP = 22;
  static const double _PAGE_PAD_BOTTOM = 44;
  static const double _SIDE_PAD = 20;
  static const double _CARD_MARGIN = 8;
  static const double _HEADROOM = 40;

  static const int _UI_HOLD_SECS = 10; // hold top banner for 10s

  // ===== state =====
  final PageController _pc = PageController();
  final List<_Entry> _pages = [];
  final List<int> _chapterStartIndex = [];
  int _current = 0;

  bool _showUi = false;
  Timer? _hideTimer;

  // paywall helpers
  late String _bookKey;
  bool _showingPaywall = false;
  int? _pendingIndexAfterUnlock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildAllPages());
  }

  @override
  void dispose() {
    _pc.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: _UI_HOLD_SECS), () {
      if (mounted) setState(() => _showUi = false);
    });
  }

  bool _isStarLine(String s) =>
      RegExp(r'^\s*(\*{3,}|(\*\s*){3,})\s*$').hasMatch(s);

  int _estimateCharsPerPage(BuildContext context) {
    final mq = MediaQuery.of(context);
    final usableW = mq.size.width - (_SIDE_PAD * 2) - (_CARD_MARGIN * 2);
    final usableH = mq.size.height
        - (mq.padding.top + mq.padding.bottom)
        - (_PAGE_PAD_TOP + _PAGE_PAD_BOTTOM)
        - (_CARD_MARGIN * 2)
        - _HEADROOM;
    final fontSize = _bodyStyle.fontSize ?? 18;
    final lineHeightPx = fontSize * (_bodyStyle.height ?? 1.5);
    final charsPerLine = (usableW / (fontSize * 0.55)).floor().clamp(28, 60);
    final linesPerPage = (usableH / lineHeightPx).floor().clamp(12, 28);
    final cap = (charsPerLine * linesPerPage).toInt();
    return (cap * _CAP_FUDGE).floor().clamp(300, 1100);
  }

  List<String> _paragraphsFromRaw(String raw) {
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final paras = <String>[];
    final sb = StringBuffer();
    bool has = false;

    void flush() {
      if (has) {
        paras.add(sb.toString().trimRight());
        sb.clear();
        has = false;
      }
    }

    for (final line in lines) {
      final t = line.trimRight();
      if (t.trim().isEmpty) {
        flush();
        continue;
      }
      if (_isStarLine(t)) {
        flush();
        paras.add('****');
        continue;
      }
      final chunk = t.trim();
      if (!has) {
        sb.write(chunk);
        has = true;
      } else {
        sb.write(' ');
        sb.write(chunk);
      }
    }
    flush();
    return paras;
  }

  List<String> _paginateByParagraphs(String raw, int capacity) {
    final paras = _paragraphsFromRaw(raw);
    final pages = <String>[];
    final page = StringBuffer();
    int cur = 0;

    void pushPage() {
      final s = page.toString().trimRight();
      if (s.isNotEmpty) pages.add(s);
      page.clear();
      cur = 0;
    }

    for (final p in paras) {
      final piece = (p == '****') ? '\n\n****\n\n' : (page.isEmpty ? p : '\n\n$p');
      final addLen = piece.length;

      if (cur + addLen > capacity && page.isNotEmpty) {
        pushPage();
      }

      if (p != '****' && p.length > capacity) {
        final words = RegExp(r'\S+|\s+').allMatches(p).map((m) => m.group(0)!).toList();
        final sb = StringBuffer();
        for (final w in words) {
          final nextLen = sb.length + w.length;
          if (nextLen > capacity && sb.toString().trim().isNotEmpty) {
            if (page.isNotEmpty) pushPage();
            pages.add(sb.toString().trimRight());
            sb.clear();
          }
          sb.write(w);
        }
        if (sb.isNotEmpty) {
          if (page.isNotEmpty) pushPage();
          pages.add(sb.toString().trimRight());
        }
        continue;
      }

      page.write(piece);
      cur += addLen;
    }
    pushPage();

    for (int i = 1; i < pages.length; i++) {
      final a = pages[i - 1], b = pages[i];
      if ((a.length + b.length) < (capacity * 0.55)) {
        pages[i - 1] = '$a\n\n$b';
        pages.removeAt(i);
        i--;
      }
    }
    return pages;
  }

  // == Build pages ==
  Future<void> _buildAllPages() async {
    _pages.clear();
    _chapterStartIndex.clear();

    // derive a bookKey (burn/rocksolid/trustme/draculi/loser)
    _bookKey = 'book';
    if (widget.chaptersDir != null) {
      final segs = widget.chaptersDir!.split('/').where((s) => s.isNotEmpty).toList();
      _bookKey = segs.isNotEmpty ? segs.last : _bookKey;
    }

    // Base pages
    _pages.add(_Entry.cover());
    _pages.add(_Entry.title());

    // Front matter
    for (final fm in widget.frontMatter) {
      try {
        final text = await rootBundle.loadString(fm.assetPath);
        _pages.add(_Entry.frontText(text, scrollable: fm.scrollable));
      } catch (_) {
        // skip missing FM
      }
    }

    // Build chapters
    final capacity = _estimateCharsPerPage(context);
    if (widget.chaptersDir != null) {
      await _buildChaptersFromFolder(widget.chaptersDir!, capacity);
    } else if (widget.assetPath != null) {
      await _buildChaptersFromMonolithic(widget.assetPath!, capacity);
    }

    // Jump to start
    final startIndex = switch (widget.startAt) {
      ReaderStart.cover    => 0,
      ReaderStart.title    => 1,
      ReaderStart.chapter1 => _chapterStartIndex.isNotEmpty ? _chapterStartIndex.first : 0,
    };

    setState(() => _current = startIndex);
    if (_pc.hasClients) {
      _pc.jumpToPage(startIndex);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pc.hasClients) _pc.jumpToPage(startIndex);
      });
    }
  }

  Future<void> _buildChaptersFromFolder(String base, int capacity) async {
    final total = widget.maxChapters ?? 39;

    // infer key from folder name
    final segs = base.split('/').where((s) => s.isNotEmpty).toList();
    final key = segs.isEmpty ? 'burn' : segs.last;

    for (int n = 1; n <= total; n++) {
      final pad = n.toString().padLeft(2, '0');
      final titlePath = '$base/ch${pad}_title.txt';
      final bodyPath  = '$base/ch${pad}_${key}_body.txt';

      // Title (safe)
      String titleText = 'Chapter $n';
      try {
        final t = (await rootBundle.loadString(titlePath)).trim();
        if (t.isNotEmpty) titleText = t;
      } catch (_) {}

      // Body (required; skip if missing)
      String bodyText;
      try {
        bodyText = (await rootBundle.loadString(bodyPath)).trim();
        if (bodyText.isEmpty) continue;
      } catch (_) {
        continue;
      }

      _chapterStartIndex.add(_pages.length);
      _pages.add(_Entry.chapterTitle(titleText));

      final slices = _paginateByParagraphs(bodyText, capacity);
      for (final s in slices) {
        _pages.add(_Entry.chapterBody(s));
      }
    }
  }

  Future<void> _buildChaptersFromMonolithic(String manuscriptPath, int capacity) async {
    String manuscript;
    try {
      manuscript = await rootBundle.loadString(manuscriptPath);
    } catch (_) {
      return;
    }

    final re = RegExp(r'(?=^\s*Chapter\s+\d+\b)', multiLine: true);
    final chunks = manuscript
        .replaceAll('\r\n', '\n')
        .split(re)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    int count = chunks.length;
    if (widget.maxChapters != null) {
      count = math.min(count, widget.maxChapters!);
    }

    for (int i = 0; i < count; i++) {
      final chunk = chunks[i];
      final headMatch = RegExp(r'^\s*Chapter\s+\d+[^\n]*', multiLine: true).firstMatch(chunk);
      final titleLine = (headMatch?.group(0) ?? 'Chapter ${i + 1}').trim();
      final body = chunk.substring(headMatch?.end ?? 0).trimLeft();

      _chapterStartIndex.add(_pages.length);
      _pages.add(_Entry.chapterTitle(titleLine));

      final slices = _paginateByParagraphs(body, capacity);
      for (final s in slices) {
        _pages.add(_Entry.chapterBody(s));
      }
    }
  }

  void _jumpToChapter(int chapter) {
    if (chapter < 1 || chapter > _chapterStartIndex.length) return;
    final idx = _chapterStartIndex[chapter - 1];
    _pc.animateToPage(idx, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  int? _currentChapterForIndex(int index) {
    for (int c = 0; c < _chapterStartIndex.length; c++) {
      final start = _chapterStartIndex[c];
      final nextStart = c + 1 < _chapterStartIndex.length ? _chapterStartIndex[c + 1] : _pages.length;
      if (index >= start && index < nextStart) return c + 1;
    }
    return null;
  }

  int _currentChapterOr1() {
    final cc = _currentChapterForIndex(_current);
    if (cc == null || _chapterStartIndex.isEmpty) return 1;
    return cc.clamp(1, _chapterStartIndex.length);
  }

  Future<void> _maybeShowPaywallForChapter(int chapter, {int? intendedIndex}) async {
    if (_showingPaywall) return;
    if (AccessManager.instance.canAccessChapter(_bookKey, chapter)) return;

    _showingPaywall = true;

    // compute last free page (end of chapter [gateAtChapter])
    final gate = AccessManager.gateAtChapter;
    final nextStart = gate < _chapterStartIndex.length ? _chapterStartIndex[gate] : _pages.length;
    final lastFreePage = (nextStart - 1).clamp(0, _pages.length - 1);
    _pendingIndexAfterUnlock = intendedIndex;

    if (_pc.hasClients) {
      _pc.jumpToPage(lastFreePage);
    }

    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PaywallScreen(bookKey: _bookKey)),
    );

    _showingPaywall = false;

    if (unlocked == true && _pendingIndexAfterUnlock != null && _pc.hasClients) {
      _pc.jumpToPage(_pendingIndexAfterUnlock!.clamp(0, _pages.length - 1));
    }
    _pendingIndexAfterUnlock = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _showUi = !_showUi);
                if (_showUi) _scheduleHide();
              },
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pc,
                    onPageChanged: (i) async {
                      setState(() => _current = i);

                      final ch = _currentChapterForIndex(i);
                      if (ch != null) {
                        // save progress
                        final relPage = i - _chapterStartIndex[ch - 1];
                        unawaited(AccessManager.instance
                            .saveProgress(_bookKey, chapter: ch, page: relPage));

                        // gate check
                        await _maybeShowPaywallForChapter(ch, intendedIndex: i);
                      }
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final e = _pages[index];
                      return _PageCard(
                        entry: e,
                        title: widget.title,
                        author: widget.author,
                        coverAsset: widget.coverAsset,
                      );
                    },
                  ),

                  if (_chapterStartIndex.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _TopChrome(
                        onBack: () => Navigator.of(context).maybePop(),
                        currentChapter: _currentChapterOr1(),
                        maxChapters: _chapterStartIndex.length,
                        onSelectChapter: (v) async {
                          // gate on dropdown selection as well
                          if (!AccessManager.instance.canAccessChapter(_bookKey, v)) {
                            await _maybeShowPaywallForChapter(v);
                          } else {
                            _jumpToChapter(v);
                          }
                          _scheduleHide();
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Entry {
  final _PageType type;
  final String? text;
  final bool scrollable;

  _Entry._(this.type, {this.text, this.scrollable = false});

  factory _Entry.cover() => _Entry._(_PageType.cover);
  factory _Entry.title() => _Entry._(_PageType.title);
  factory _Entry.frontText(String t, {bool scrollable = false}) =>
      _Entry._(_PageType.frontText, text: t, scrollable: scrollable);
  factory _Entry.chapterTitle(String t) => _Entry._(_PageType.chapterTitle, text: t);
  factory _Entry.chapterBody(String t) => _Entry._(_PageType.chapterBody, text: t, scrollable: false);
}

// ======================= Helpers / blocks ==========================
class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.entry,
    required this.title,
    required this.author,
    required this.coverAsset,
  });

  final _Entry entry;
  final String title;
  final String author;
  final String coverAsset;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, c) {
          final pr = MediaQuery.of(context).devicePixelRatio;
          final snappedH = (c.maxHeight * pr).floor() / pr;

          return SizedBox(
            height: snappedH,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(blurRadius: 16, color: Color(0x14000000), offset: Offset(0, 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ColoredBox(
                  color: Colors.white,
                  child: _buildPage(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    switch (entry.type) {
      case _PageType.cover:
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(coverAsset, width: 320, fit: BoxFit.contain),
          ),
        );

      case _PageType.title:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: .5),
              ),
              const SizedBox(height: 10),
              const Text('A NOVEL BY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(author, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        );

      case _PageType.frontText:
        final text = entry.text ?? '';
        final content = _CenteredBlock(text: text);
        return entry.scrollable ? SingleChildScrollView(child: content) : content;

      case _PageType.chapterTitle:
        return Center(
          child: Text(
            entry.text ?? 'Chapter',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
        );

      case _PageType.chapterBody:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            _ReaderSwipeCleanState._SIDE_PAD,
            _ReaderSwipeCleanState._PAGE_PAD_TOP,
            _ReaderSwipeCleanState._SIDE_PAD,
            _ReaderSwipeCleanState._PAGE_PAD_BOTTOM,
          ),
          child: _SceneAwareBody(
            text: entry.text ?? '',
            baseStyle: _ReaderSwipeCleanState._bodyStyle,
          ),
        );
    }
  }
}

class _CenteredBlock extends StatelessWidget {
  const _CenteredBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _SceneAwareBody extends StatelessWidget {
  const _SceneAwareBody({required this.text, required this.baseStyle});

  final String text;
  final TextStyle baseStyle;

  bool _isBlank(String s) => s.trim().isEmpty;
  bool _isStarLine(String s) =>
      RegExp(r'^\s*(\*{3,}|(\*\s*){3,})\s*$').hasMatch(s);

  static const _thb = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  static const _strut = StrutStyle(
    forceStrutHeight: true,
    height: 1.5,
    leading: 0.2,
  );

  @override
  Widget build(BuildContext context) {
    final lines = text.replaceAll('\r\n', '\n').split('\n');

    final children = <Widget>[];
    final para = StringBuffer();
    bool has = false;

    void flushPara() {
      if (!has) return;
      final str = para.toString().trimRight();
      if (str.isNotEmpty) {
        children.add(
          Text(
            str,
            textAlign: TextAlign.left,
            style: baseStyle,
            textHeightBehavior: _thb,
            strutStyle: _strut,
            softWrap: true,
          ),
        );
        children.add(const SizedBox(height: 6));
      }
      para.clear();
      has = false;
    }

    for (final raw in lines) {
      if (_isBlank(raw)) {
        flushPara();
        continue;
      }

      if (_isStarLine(raw)) {
        flushPara();
        children.add(
          const Center(
            child: Text(
              '****',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
              textHeightBehavior: _thb,
              strutStyle: _strut,
              softWrap: false,
            ),
          ),
        );
        children.add(const SizedBox(height: 14));
        continue;
      }

      final chunk = raw.trimRight();
      if (!has) {
        para.write(chunk.trimLeft());
        has = true;
      } else {
        para.write(' ');
        para.write(chunk.trimLeft());
      }
    }

    flushPara();

    if (children.isNotEmpty && children.last is SizedBox) {
      children.removeLast();
    }

    children.add(const SizedBox(height: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
