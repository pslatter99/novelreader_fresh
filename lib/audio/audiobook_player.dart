// lib/audio/audiobook_player.dart
import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../reader/book_configs.dart';

class AudiobookPlayerScreen extends StatefulWidget {
  final BookConfig book;

  /// Asset paths for each chapter in order.
  /// Prefer relative paths like: 'audio/draculi/draculi_CHAPTER_1.mp3'
  final List<String> chapterAudioPaths;

  /// Optional paywall gate. Return true to allow playback, false to block.
  final Future<bool> Function(BookConfig book)? canPlay;

  const AudiobookPlayerScreen({
    super.key,
    required this.book,
    required this.chapterAudioPaths,
    this.canPlay,
  });

  @override
  State<AudiobookPlayerScreen> createState() => _AudiobookPlayerScreenState();
}

class _AudiobookPlayerScreenState extends State<AudiobookPlayerScreen> {
  late final AudioPlayer _player;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _index = 0;
  bool _isLoading = true;
  bool _isPlaying = false;

  // throttle saving position
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  StreamSubscription<Duration>? _durSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  String get _prefsKeyPrefix => 'ab_${widget.book.key}'; // e.g., ab_draculi

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _durSub = _player.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });

    _posSub = _player.onPositionChanged.listen((p) {
      setState(() => _position = p);
      if (DateTime.now().difference(_lastSave).inSeconds >= 3) {
        _persist();
        _lastSave = DateTime.now();
      }
    });

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });

    _completeSub = _player.onPlayerComplete.listen((_) async {
      if (_index + 1 < widget.chapterAudioPaths.length) {
        await _setChapter(_index + 1, seek: Duration.zero, autoplay: true);
      } else {
        await _player.stop();
        await _persist();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Optional paywall check
    if (widget.canPlay != null) {
      final allowed = await widget.canPlay!(widget.book);
      if (!mounted) return;
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio is locked.')),
        );
        Navigator.of(context).pop();
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('$_prefsKeyPrefix.index') ?? 0;
    final savedMs = prefs.getInt('$_prefsKeyPrefix.posMs') ?? 0;

    final safeIndex =
        savedIndex.clamp(0, widget.chapterAudioPaths.length - 1);
    await _setChapter(
      safeIndex,
      seek: Duration(milliseconds: savedMs),
      autoplay: false,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefsKeyPrefix.index', _index);
    await prefs.setInt('$_prefsKeyPrefix.posMs', _position.inMilliseconds);
  }

  Future<void> _setChapter(
    int idx, {
    Duration? seek,
    bool autoplay = false,
  }) async {
    setState(() {
      _isLoading = true;
      _index = idx;
    });

    await _player.stop();
    final path = widget.chapterAudioPaths[_index];

    try {
      // Accept both 'assets/...' and relative 'audio/...'
      final rel = path.startsWith('assets/') ? path.substring(7) : path;
      await _player.setSource(AssetSource(rel));

      if (seek != null && seek > Duration.zero) {
        await _player.seek(seek);
      }
      if (autoplay) {
        await _player.resume();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio file not found: $path')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _persist();
    _durSub?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String? _coverAssetFromBook() {
    try {
      final dynamic b = widget.book;
      final v = (b as dynamic).coverAsset;
      if (v is String && v.trim().isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const deepRed = Color(0xFFB71C1C);
    final chCount = widget.chapterAudioPaths.length;
    final title = '${widget.book.title} — Audiobook';
    final cover = _coverAssetFromBook();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // inside build() -> LayoutBuilder(builder: ...)
final coverH = constraints.maxHeight * 0.50; // was 0.66
final topH   = constraints.maxHeight - coverH;

          return Column(
            children: [
              // TOP: chips + compact controls (crammed in)
              SizedBox(
                height: topH,
                child: Column(
                  children: [
                    Material(
                      elevation: 1,
                      child: SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          itemCount: chCount,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final isSel = i == _index;
                            return ChoiceChip(
                              label: Text(
                                'Ch ${i + 1}',
                                style: TextStyle(
                                  fontWeight: isSel
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: deepRed.withOpacity(.14),
                              backgroundColor: Colors.black12,
                              side: BorderSide(
                                  color: isSel ? deepRed : Colors.black26),
                              labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              onSelected: (v) => _setChapter(
                                  i, seek: Duration.zero, autoplay: _isPlaying),
                            );
                          },
                        ),
                      ),
                    ),

                    // compact transport area
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Chapter ${_index + 1} of $chCount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Slider
                              Slider(
                                min: 0,
                                max: (_duration.inMilliseconds > 0)
                                    ? _duration.inMilliseconds.toDouble()
                                    : 1,
                                value: _position.inMilliseconds
                                    .clamp(
                                        0,
                                        (_duration.inMilliseconds > 0
                                            ? _duration.inMilliseconds
                                            : 1))
                                    .toDouble(),
                                onChanged: (v) => setState(() =>
                                    _position =
                                        Duration(milliseconds: v.toInt())),
                                onChangeEnd: (v) => _player
                                    .seek(Duration(milliseconds: v.toInt())),
                              ),

                              // times
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Elapsed',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  Text('Total',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmt(_position),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _fmt(_duration),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'Previous chapter',
                                    icon: const Icon(Icons.skip_previous),
                                    iconSize: 36,
                                    color: deepRed,
                                    onPressed: _index > 0
                                        ? () => _setChapter(_index - 1,
                                            seek: Duration.zero,
                                            autoplay: _isPlaying)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: deepRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .3,
                                      ),
                                      elevation: 2,
                                    ),
                                    icon: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 28,
                                    ),
                                    label: Text(_isPlaying ? 'PAUSE' : 'PLAY'),
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            if (_isPlaying) {
                                              await _player.pause();
                                              await _persist();
                                            } else {
                                              await _player.resume();
                                            }
                                          },
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    tooltip: 'Next chapter',
                                    icon: const Icon(Icons.skip_next),
                                    iconSize: 36,
                                    color: deepRed,
                                    onPressed: _index + 1 < chCount
                                        ? () => _setChapter(_index + 1,
                                            seek: Duration.zero,
                                            autoplay: _isPlaying)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // BOTTOM: cover fills ~2/3 of screen
              if (cover != null && cover.isNotEmpty)
                SizedBox(
                  height: coverH - 1,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Image.asset(
                          cover,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
