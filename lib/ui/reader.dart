import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../data/app_state.dart';
import '../data/database.dart';
import '../domain/models.dart';
import '../platform/engine.dart';
import 'components.dart';
import 'native_page_image.dart';
import 'local_reader_image.dart';

class ReaderScreen extends StatefulWidget {
  final AppState state;
  final Manga manga;
  final List<Chapter> chapters;
  final Chapter initial;
  const ReaderScreen(
    this.state,
    this.manga,
    this.chapters,
    this.initial, {
    super.key,
  });
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  late Chapter chapter;
  List<ReaderPage> pages = [];
  bool loading = true, controls = true;
  Object? error;
  int current = 0;
  late String mode;
  PageController? pager;
  final scroll = ScrollController();
  late final observer = ListObserverController(controller: scroll);
  Timer? saveTimer;
  final stopwatch = Stopwatch()..start();
  bool volume = true;
  bool autoNext = true;
  bool reverseTapZones = false;
  int loadGeneration = 0;
  final decodedPages = <int>{};
  final imageRetries = <int, int>{};
  bool get canComplete =>
      pages.isNotEmpty && decodedPages.contains(pages.length - 1);
  void _decoded(int index, int generation) {
    if (!mounted || generation != loadGeneration || !decodedPages.add(index)) {
      return;
    }
    _save();
  }

  String? prefetchedChapter;
  Future<List<ReaderPage>>? prefetchedPages;
  Json bookmarks = {};
  String get bookmarkKey => '${widget.manga.key}::${chapter.url}';
  int get savedPage =>
      doublePage ? (current + 1).clamp(0, pages.length - 1) : current;
  void _step(int direction) =>
      _jump(current + direction * (doublePage ? 2 : 1));
  double brightness = -1;
  bool get continuous => ['webtoon', 'vertical', 'longStrip'].contains(mode);
  bool get doublePage => mode == 'double';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    chapter = widget.initial;
    mode = widget.state.preferences.getString('readerMode') ?? 'webtoon';
    volume = widget.state.preferences.getBool('volumeKeys') ?? true;
    autoNext = widget.state.preferences.getBool('autoNextChapter') ?? true;
    reverseTapZones =
        widget.state.preferences.getBool('reverseTapZones') ?? false;
    try {
      bookmarks = Map<String, dynamic>.from(
        jsonDecode(widget.state.preferences.getString('bookmarks') ?? '{}'),
      )..removeWhere((key, value) => value is! int || value < 0);
    } catch (_) {
      bookmarks = {};
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SourceEngine.channel.setMethodCallHandler((call) async {
      if (call.method == 'volume') _step(call.arguments as int);
    });
    _nativeSettings();
    _load();
  }

  void _nativeSettings() {
    if (widget.state.engine.available) {
      widget.state.engine
          .call('readerSettings', {
            'volumeKeys': volume,
            'brightness': brightness,
            'keepAwake': true,
          })
          .catchError((_) => null);
    }
  }

  Future<void> _load() async {
    final generation = ++loadGeneration;
    final requestedChapter = chapter;
    saveTimer?.cancel();
    setState(() {
      loading = true;
      pages = [];
      decodedPages.clear();
      imageRetries.clear();
      error = null;
    });
    try {
      final records = await widget.state.db.chapters(widget.manga.key);
      if (!mounted || generation != loadGeneration) return;
      final resumePage =
          records
              .where((r) => r.url == requestedChapter.url)
              .firstOrNull
              ?.page ??
          0;
      List<ReaderPage>? local;
      if (widget.state.engine.available) {
        try {
          final result = await widget.state.engine.call('downloadPages', {
            'key': '${widget.manga.key}::${requestedChapter.url}',
          });
          if (result is List && result.isNotEmpty) {
            local = result
                .map((p) => ReaderPage.fromJson(Map<String, dynamic>.from(p)))
                .toList();
          }
        } catch (_) {
          /* Online source remains available when no download exists. */
        }
      }
      final prefetched = prefetchedChapter == requestedChapter.url
          ? prefetchedPages
          : null;
      var loadedPages =
          local ??
          await (prefetched ??
              widget.state.engine.pages(widget.manga, requestedChapter));
      if (loadedPages.isEmpty && prefetched != null) {
        loadedPages = await widget.state.engine.pages(
          widget.manga,
          requestedChapter,
        );
      }
      if (!mounted || generation != loadGeneration) return;
      pages = loadedPages;
      prefetchedChapter = null;
      prefetchedPages = null;
      if (pages.isEmpty) {
        throw StateError('The source returned no pages for this chapter.');
      }
      current = resumePage.clamp(0, pages.length - 1);
      if (doublePage) current = (current ~/ 2) * 2;
      pager?.dispose();
      pager = PageController(initialPage: doublePage ? current ~/ 2 : current);
      if (mounted) {
        setState(() => loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (continuous && mounted && scroll.hasClients) {
            observer.jumpTo(index: current);
          }
        });
        _save();
        _preload();
      }
    } catch (e) {
      if (mounted && generation == loadGeneration) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  void _save({bool immediate = false}) {
    if (pages.isEmpty) return;
    saveTimer?.cancel();
    final url = chapter.url, position = savedPage, total = pages.length;
    final allowComplete = canComplete;
    void persist() {
      widget.state.db.progress(
        widget.manga.key,
        url,
        position,
        total,
        allowComplete: allowComplete,
      );
    }

    if (immediate) {
      persist();
    } else {
      saveTimer = Timer(const Duration(milliseconds: 500), persist);
    }
  }

  void _changed(int page) {
    if (page == current || !mounted) return;
    setState(() => current = page.clamp(0, pages.length - 1));
    _save();
    _preload();
  }

  Future<List<ReaderPage>> _prefetchChapter(Chapter next) async {
    if (widget.state.engine.available) {
      final local = await widget.state.engine.call('downloadPages', {
        'key': '${widget.manga.key}::${next.url}',
      });
      if (local is List && local.isNotEmpty) {
        return local
            .map((p) => ReaderPage.fromJson(Map<String, dynamic>.from(p)))
            .toList();
      }
    }
    return widget.state.engine.pages(widget.manga, next);
  }

  void _preload() {
    final chapterIndex = widget.chapters.indexWhere(
      (c) => c.url == chapter.url,
    );
    if (current >= pages.length - 3 &&
        prefetchedPages == null &&
        chapterIndex >= 0 &&
        chapterIndex + 1 < widget.chapters.length) {
      final next = widget.chapters[chapterIndex + 1];
      prefetchedChapter = next.url;
      final generation = loadGeneration;
      prefetchedPages = _prefetchChapter(next).catchError((Object error) {
        if (generation == loadGeneration && prefetchedChapter == next.url) {
          prefetchedChapter = null;
          prefetchedPages = null;
        }
        return <ReaderPage>[];
      });
    }
    for (var i = current + 1; i <= current + 2 && i < pages.length; i++) {
      if (widget.state.engine.available && pages[i].sourceId.isNotEmpty) {
        widget.state.engine
            .call('image', {
              'sourceId': pages[i].sourceId,
              'page': pages[i].toJson(),
            })
            .catchError((_) => null);
      } else if (!pages[i].url.startsWith('/')) {
        precacheImage(
          CachedNetworkImageProvider(
            pages[i].url,
            headers: pages[i].headers,
            maxWidth: 1600,
            maxHeight: 8192,
          ),
          context,
        ).catchError((_) {});
      }
    }
  }

  void _jump(int index) {
    if (pages.isEmpty || loading) return;
    if (index >= pages.length) {
      if (autoNext) _next();
      return;
    }
    index = index.clamp(0, pages.length - 1);
    if (continuous) {
      observer.animateTo(
        index: index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      pager?.animateToPage(
        doublePage ? index ~/ 2 : index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _next() async {
    if (loading) return;
    saveTimer?.cancel();
    final index = widget.chapters.indexWhere((c) => c.url == chapter.url);
    if (index < 0 || index + 1 >= widget.chapters.length) return;
    await widget.state.db.progress(
      widget.manga.key,
      chapter.url,
      pages.length - 1,
      pages.length,
      allowComplete: canComplete,
    );
    chapter = widget.chapters[index + 1];
    await _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      stopwatch.start();
    } else {
      stopwatch.stop();
      _save(immediate: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopwatch.stop();
    saveTimer?.cancel();
    if (pages.isNotEmpty) {
      widget.state.db.progress(
        widget.manga.key,
        chapter.url,
        savedPage,
        pages.length,
        allowComplete: canComplete,
      );
    }
    widget.state.db
        .into(widget.state.db.readingSessions)
        .insert(
          ReadingSessionsCompanion.insert(
            mangaKey: widget.manga.key,
            seconds: stopwatch.elapsed.inSeconds,
          ),
        );
    pager?.dispose();
    scroll.dispose();
    SourceEngine.channel.setMethodCallHandler(null);
    if (widget.state.engine.available) {
      widget.state.engine
          .call('readerSettings', {
            'volumeKeys': false,
            'brightness': -1.0,
            'keepAwake': false,
          })
          .catchError((_) => null);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Widget _image(int index, {bool fit = false}) {
    final page = pages[index];
    final generation = loadGeneration;
    Widget decodedFrame(
      BuildContext context,
      Widget child,
      int? frame,
      bool sync,
    ) {
      if (frame == null) {
        return const SizedBox(
          height: 260,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      _decoded(index, generation);
      return child;
    }

    if (widget.state.engine.available && page.sourceId.isNotEmpty) {
      return NativePageImage(
        page,
        widget.state.engine,
        key: ValueKey('${page.sourceId}:${page.url}'),
        fit: fit,
        onDecoded: () => _decoded(index, generation),
      );
    }
    final failure = Container(
      height: 260,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, color: Colors.white54),
          Text(
            'Page ${index + 1} failed to load',
            style: const TextStyle(color: Colors.white54),
          ),
          TextButton(
            onPressed: () async {
              if (page.url.startsWith('/')) {
                await FileImage(File(page.url)).evict();
              } else {
                await CachedNetworkImage.evictFromCache(page.url);
              }
              if (mounted) {
                setState(
                  () => imageRetries[index] = (imageRetries[index] ?? 0) + 1,
                );
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    if (page.url.startsWith('/')) {
      return LocalReaderImage(
        key: ValueKey('${page.url}:${imageRetries[index] ?? 0}'),
        path: page.url,
        engine: widget.state.engine,
        fit: fit,
        onDecoded: () => _decoded(index, generation),
        errorBuilder: (_) => failure,
      );
    }

    return Image(
      image: ResizeImage(
        CachedNetworkImageProvider(page.url, headers: page.headers),
        width: 1800,
        height: 8192,
        policy: ResizeImagePolicy.fit,
      ),
      fit: fit ? BoxFit.contain : BoxFit.fitWidth,
      width: double.infinity,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      frameBuilder: decodedFrame,
      errorBuilder: (_, _, _) => failure,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? SafeArea(
            child: Column(
              children: [
                AppBar(title: Text(chapter.name)),
                Expanded(child: ErrorNotice(error!, retry: _load)),
              ],
            ),
          )
        : Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTapUp: (tap) {
                    final fraction =
                        tap.localPosition.dx / MediaQuery.sizeOf(context).width;
                    if (fraction < .23 && !continuous) {
                      _step(
                        (mode == 'rtl' ? 1 : -1) * (reverseTapZones ? -1 : 1),
                      );
                    } else if (fraction > .77 && !continuous) {
                      _step(
                        (mode == 'rtl' ? -1 : 1) * (reverseTapZones ? -1 : 1),
                      );
                    } else {
                      setState(() => controls = !controls);
                    }
                  },
                  child: continuous
                      ? ListViewObserver(
                          controller: observer,
                          onObserve: (model) {
                            final index = model.firstChild?.index;
                            if (index != null) _changed(index);
                          },
                          child: ListView.builder(
                            scrollCacheExtent: ScrollCacheExtent.pixels(600),
                            controller: scroll,
                            itemCount: pages.length + 1,
                            itemBuilder: (_, index) => index == pages.length
                                ? Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: FilledButton(
                                      onPressed:
                                          widget.chapters.last.url ==
                                              chapter.url
                                          ? null
                                          : () => _next(),
                                      child: Text(
                                        widget.chapters.last.url == chapter.url
                                            ? 'You’re all caught up'
                                            : 'Next chapter',
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: EdgeInsets.only(
                                      bottom: mode == 'vertical' ? 16 : 0,
                                    ),
                                    child: _image(index),
                                  ),
                          ),
                        )
                      : PageView.builder(
                          controller: pager,
                          reverse: mode == 'rtl',
                          itemCount: doublePage
                              ? (pages.length / 2).ceil()
                              : pages.length,
                          onPageChanged: (page) =>
                              _changed(doublePage ? page * 2 : page),
                          itemBuilder: (_, index) => InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: doublePage
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: _image(index * 2, fit: true),
                                      ),
                                      if (index * 2 + 1 < pages.length)
                                        Expanded(
                                          child: _image(
                                            index * 2 + 1,
                                            fit: true,
                                          ),
                                        ),
                                    ],
                                  )
                                : Center(child: _image(index, fit: true)),
                          ),
                        ),
                ),
              ),
              if (controls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: .85),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          BackButton(color: Colors.white),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.manga.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  chapter.name,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: bookmarks.containsKey(bookmarkKey)
                                ? 'Remove bookmark'
                                : 'Bookmark this page',
                            onPressed: () async {
                              setState(() {
                                if (bookmarks.containsKey(bookmarkKey)) {
                                  bookmarks.remove(bookmarkKey);
                                } else {
                                  bookmarks[bookmarkKey] = current;
                                }
                              });
                              await widget.state.preferences.setString(
                                'bookmarks',
                                jsonEncode(bookmarks),
                              );
                            },
                            icon: Icon(
                              bookmarks.containsKey(bookmarkKey)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Reader settings',
                            onPressed: _settings,
                            icon: const Icon(Icons.tune, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (controls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: .85),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Previous page',
                                onPressed: current == 0
                                    ? null
                                    : () => _step(-1),
                                icon: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: current.toDouble(),
                                  min: 0,
                                  max: (pages.length - 1)
                                      .clamp(1, 100000)
                                      .toDouble(),
                                  onChanged: (value) => _jump(value.round()),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Next page',
                                onPressed: () => _step(1),
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${current + 1} / ${pages.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );
  void _settings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reader settings',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children:
                      {
                            'webtoon': 'Webtoon',
                            'vertical': 'Vertical',
                            'ltr': 'Left to right',
                            'rtl': 'Right to left',
                            'double': 'Double page',
                            'longStrip': 'Long strip',
                          }.entries
                          .map(
                            (entry) => ChoiceChip(
                              label: Text(entry.value),
                              selected: mode == entry.key,
                              onSelected: (_) async {
                                await widget.state.preferences.setString(
                                  'readerMode',
                                  entry.key,
                                );
                                setState(() {
                                  mode = entry.key;
                                  if (doublePage) current = (current ~/ 2) * 2;
                                  pager?.dispose();
                                  pager = PageController(
                                    initialPage: doublePage
                                        ? current ~/ 2
                                        : current,
                                  );
                                });
                                setSheetState(() {});
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted &&
                                      continuous &&
                                      scroll.hasClients) {
                                    observer.jumpTo(index: current);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 12),
                if (bookmarks.containsKey(bookmarkKey))
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _jump(bookmarks[bookmarkKey] as int);
                    },
                    icon: const Icon(Icons.bookmark),
                    label: Text(
                      'Go to bookmark · page ${(bookmarks[bookmarkKey] as int) + 1}',
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Advance to next chapter'),
                  value: autoNext,
                  onChanged: (v) {
                    setSheetState(() => autoNext = v);
                    widget.state.preferences.setBool('autoNextChapter', v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reverse left and right tap zones'),
                  value: reverseTapZones,
                  onChanged: (v) {
                    setSheetState(() => reverseTapZones = v);
                    widget.state.preferences.setBool('reverseTapZones', v);
                  },
                ),
                const Text('Brightness'),
                Slider(
                  value: brightness < 0 ? .5 : brightness,
                  onChanged: (v) {
                    setSheetState(() => brightness = v);
                    _nativeSettings();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Volume buttons turn pages'),
                  value: volume,
                  onChanged: (v) {
                    setSheetState(() => volume = v);
                    widget.state.preferences.setBool('volumeKeys', v);
                    _nativeSettings();
                  },
                ),
                Wrap(
                  children: [
                    TextButton.icon(
                      onPressed: () => SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]),
                      icon: const Icon(Icons.stay_current_portrait),
                      label: const Text('Portrait'),
                    ),
                    TextButton.icon(
                      onPressed: () => SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]),
                      icon: const Icon(Icons.stay_current_landscape),
                      label: const Text('Landscape'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
