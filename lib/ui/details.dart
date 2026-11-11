import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../domain/models.dart';
import '../data/database.dart';
import 'components.dart';
import 'theme.dart';
import 'reader.dart';

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
  @override
  void initState() {
    super.initState();
    manga = widget.initial;
    _load();
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
  }

  Future<void> _download(Chapter chapter) async {
    setState(() => downloading = chapter.url);
    try {
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
                  if (loading) const LinearProgressIndicator(),
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
                leading: Icon(
                  record?.completed == true
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
                        tooltip: 'Download chapter',
                        onPressed: downloading == null
                            ? () => _download(c)
                            : null,
                        icon: const Icon(Icons.download_outlined, size: 20),
                      ),
                onTap: () => _read(c),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
