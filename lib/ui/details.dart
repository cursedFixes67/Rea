import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../domain/models.dart';
import '../data/database.dart';
import 'components.dart';
import 'theme.dart';
import 'reader.dart';
import 'tracking.dart';

class MangaDetailsScreen extends StatefulWidget {
  final AppState state;
  final Manga initial;
  const MangaDetailsScreen(this.state, this.initial, {super.key});
  @override
  State<MangaDetailsScreen> createState() => _MangaDetailsScreenState();
}

class _MangaDetailsScreenState extends State<MangaDetailsScreen> {
  late Manga manga;
  List<Chapter> chapters = [];
  List<ChapterEntry> progress = [];
  bool loading = true, reverse = false, unreadOnly = false;
  Object? error;
  String? downloading;
  final Set<String> selected = {};
  final Set<String> downloaded = {};
  bool batchDownloading = false;
  bool cancelBatch = false;
  int batchDone = 0;
  Future<void> _loadDownloads() async {
    if (!widget.state.engine.available) return;
    try {
      final jobs = await widget.state.engine.call('downloadList') as List;
      if (!mounted) return;
      setState(() {
        downloaded.clear();
        downloaded.addAll(
          jobs
              .where(
                (j) => j['mangaKey'] == manga.key && j['status'] == 'SUCCEEDED',
              )
              .map((j) => '${j['chapterUrl']}'),
        );
      });
    } catch (_) {
      /* Source refresh errors are shown independently. */
    }
  }

  Future<void> _downloadSelected() async {
    final queue = chapters.where((c) => selected.contains(c.url)).toList();
    setState(() {
      batchDownloading = true;
      cancelBatch = false;
      batchDone = 0;
    });
    final failures = <String>[];
    for (final chapter in queue) {
      if (!mounted || cancelBatch) break;
      try {
        await _enqueue(chapter);
      } catch (e) {
        failures.add('${chapter.name}: $e');
      }
      if (mounted) setState(() => batchDone++);
    }
    if (!mounted) return;
    setState(() {
      batchDownloading = false;
      selected.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failures.isEmpty
              ? '$batchDone chapters added to downloads'
              : '${batchDone - failures.length} queued; ${failures.length} failed. ${failures.first}',
        ),
      ),
    );
  }

  Future<void> _enqueue(Chapter chapter) async {
    final pages = await widget.state.engine.pages(manga, chapter);
    await widget.state.engine.call('downloadEnqueue', {
      'key': '${manga.key}::${chapter.url}',
      'mangaKey': manga.key,
      'chapterUrl': chapter.url,
      'title': manga.title,
      'chapterName': chapter.name,
      'wifiOnly': widget.state.preferences.getBool('wifiOnly') ?? true,
      'pages': pages.map((p) => p.toJson()).toList(),
    });
  }

  @override
  void initState() {
    super.initState();
    manga = widget.initial;
    _load();
    _loadDownloads();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      progress = await widget.state.db.chapters(manga.key);
      if (progress.isNotEmpty) {
        chapters = progress
            .map((e) => Chapter.fromJson(jsonDecode(e.payload)))
            .toList();
      }
      final result = await widget.state.engine.details(manga);
      manga = Manga.fromJson(Map<String, dynamic>.from(result['manga']));
      chapters = (result['chapters'] as List)
          .map((c) => Chapter.fromJson(Map<String, dynamic>.from(c)))
          .toList();
      await widget.state.db.saveChapters(manga.key, chapters);
      if (widget.state.hasManga(manga)) await widget.state.db.addManga(manga);
      progress = await widget.state.db.chapters(manga.key);
    } catch (e) {
      error = e;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _read(Chapter chapter) async {
    final ordered = [...chapters]..sort((a, b) => a.number.compareTo(b.number));
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(widget.state, manga, ordered, chapter),
      ),
    );
    progress = await widget.state.db.chapters(manga.key);
    if (mounted) setState(() {});
    await _loadDownloads();
  }

  Future<void> _download(Chapter chapter) async {
    setState(() => downloading = chapter.url);
    try {
      await _enqueue(chapter);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${chapter.name} added to downloads')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => downloading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = chapters
        .where(
          (c) =>
              !unreadOnly ||
              !progress.any((p) => p.url == c.url && p.completed),
        )
        .toList();
    if (reverse) {
      visible.sort((a, b) => a.number.compareTo(b.number));
    }
    final ordered = [...chapters]..sort((a, b) => a.number.compareTo(b.number));
    final next =
        ordered
            .where((c) => !progress.any((p) => p.url == c.url && p.completed))
            .firstOrNull ??
        ordered.firstOrNull;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              manga.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (widget.state.engine.available)
                IconButton(
                  tooltip: 'Track this title',
                  icon: const Icon(Icons.sync),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MangaTrackingScreen(widget.state, manga),
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Refresh details',
                onPressed: loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: manga.key,
                        child: CoverImage(manga.cover, width: 124, height: 180),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              manga.title,
                              style: const TextStyle(
                                fontFamily: 'Newsreader',
                                fontSize: 28,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (manga.author.isNotEmpty)
                              Text(
                                manga.author,
                                style: const TextStyle(
                                  color: dreamMuted,
                                  fontSize: 12,
                                ),
                              ),
                            if (manga.artist.isNotEmpty &&
                                manga.artist != manga.author)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Art · ${manga.artist}',
                                  style: const TextStyle(
                                    color: dreamMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              switch (manga.status) {
                                1 => 'Ongoing',
                                2 => 'Completed',
                                3 => 'Licensed',
                                4 => 'Publishing finished',
                                5 => 'Cancelled',
                                6 => 'On hiatus',
                                _ => 'Status unknown',
                              },
                              style: TextStyle(
                                color: widget.state.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${chapters.length} chapters',
                              style: const TextStyle(
                                color: dreamMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: next == null ? null : () => _read(next),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            progress.any((p) => p.lastRead != null)
                                ? 'Continue reading'
                                : 'Start reading',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        tooltip: widget.state.hasManga(manga)
                            ? 'Remove from library'
                            : 'Add to library',
                        onPressed: () async {
                          await widget.state.toggleLibrary(manga);
                          if (mounted) setState(() {});
                        },
                        icon: Icon(
                          widget.state.hasManga(manga)
                              ? Icons.bookmark
                              : Icons.bookmark_add_outlined,
                        ),
                      ),
                    ],
                  ),
                  if (manga.genre.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: manga.genre
                            .split(',')
                            .map(
                              (g) => Chip(
                                label: Text(
                                  g.trim(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (manga.description.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'About this story',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            manga.description,
                            style: const TextStyle(
                              color: dreamMuted,
                              height: 1.7,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Could not refresh source: $error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  SectionHeading(
                    'Chapters',
                    trailing: Row(
                      children: [
                        PopupMenuButton<String>(
                          tooltip: 'Select chapters',
                          enabled: !batchDownloading && chapters.isNotEmpty,
                          onSelected: (choice) => setState(() {
                            selected.clear();
                            selected.addAll(
                              visible
                                  .where(
                                    (c) =>
                                        choice == 'all' ||
                                        !progress.any(
                                          (p) => p.url == c.url && p.completed,
                                        ),
                                  )
                                  .map((c) => c.url),
                            );
                          }),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'unread',
                              child: Text('Select unread'),
                            ),
                            PopupMenuItem(
                              value: 'all',
                              child: Text('Select visible chapters'),
                            ),
                          ],
                          icon: const Icon(Icons.checklist),
                        ),
                        IconButton(
                          tooltip: 'Unread chapters only',
                          onPressed: () =>
                              setState(() => unreadOnly = !unreadOnly),
                          icon: Icon(
                            unreadOnly
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Reverse chapter order',
                          onPressed: () => setState(() => reverse = !reverse),
                          icon: const Icon(Icons.swap_vert),
                        ),
                      ],
                    ),
                  ),
                  if (selected.isNotEmpty || batchDownloading)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                batchDownloading
                                    ? 'Preparing $batchDone / ${selected.length}'
                                    : '${selected.length} selected',
                              ),
                            ),
                            if (!batchDownloading)
                              IconButton(
                                tooltip: 'Clear selection',
                                onPressed: () => setState(selected.clear),
                                icon: const Icon(Icons.close),
                              ),
                            FilledButton.icon(
                              onPressed: batchDownloading
                                  ? () => setState(() => cancelBatch = true)
                                  : _downloadSelected,
                              icon: Icon(
                                batchDownloading ? Icons.stop : Icons.download,
                              ),
                              label: Text(
                                batchDownloading ? 'Stop' : 'Download',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (loading || batchDownloading)
                    const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
          if (!loading && chapters.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No chapters available',
                message:
                    'This source has not returned any chapters for the title.',
              ),
            ),
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (_, i) {
              final c = visible[i];
              final record = progress.where((p) => p.url == c.url).firstOrNull;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                selected: selected.contains(c.url),
                onLongPress: batchDownloading
                    ? null
                    : () => setState(() {
                        if (!selected.add(c.url)) selected.remove(c.url);
                      }),
                leading: selected.isNotEmpty
                    ? Checkbox(
                        value: selected.contains(c.url),
                        onChanged: batchDownloading
                            ? null
                            : (value) => setState(() {
                                if (value == true) {
                                  selected.add(c.url);
                                } else {
                                  selected.remove(c.url);
                                }
                              }),
                      )
                    : Icon(
                        downloaded.contains(c.url)
                            ? Icons.offline_pin_outlined
                            : record?.completed == true
                            ? Icons.check_circle_outline
                            : Icons.menu_book_outlined,
                        color: record?.completed == true
                            ? dreamMuted
                            : widget.state.accent,
                        size: 20,
                      ),
                title: Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: record?.completed == true ? dreamMuted : null,
                  ),
                ),
                subtitle: record?.lastRead != null
                    ? Text(
                        record!.completed ? 'Read' : 'Page ${record.page + 1}',
                        style: const TextStyle(fontSize: 10),
                      )
                    : null,
                trailing: downloading == c.url
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: downloaded.contains(c.url)
                            ? 'Downloaded'
                            : 'Download chapter',
                        onPressed:
                            downloading == null &&
                                !batchDownloading &&
                                !downloaded.contains(c.url)
                            ? () => _download(c)
                            : null,
                        icon: const Icon(Icons.download_outlined, size: 20),
                      ),
                onTap: selected.isEmpty
                    ? () => _read(c)
                    : batchDownloading
                    ? null
                    : () => setState(() {
                        if (!selected.add(c.url)) selected.remove(c.url);
                      }),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
