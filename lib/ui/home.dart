import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../domain/models.dart';
import 'browse.dart';
import 'components.dart';
import 'settings.dart';
import 'shell.dart' show openManga;
import 'statistics.dart';
import 'theme.dart';
import 'reading_room.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onBrowse, onDownloads, onLibrary;
  const HomeScreen(
    this.state, {
    super.key,
    required this.onBrowse,
    required this.onDownloads,
    required this.onLibrary,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const labels = {
    'continue': 'Continue reading',
    'recent': 'Recently added',
    'history': 'Recently read',
    'popular': 'Popular discoveries',
    'recommend': 'From your library',
    'sources': 'Your sources',
    'stats': 'Reading activity',
  };
  late List<String> order;
  late Set<String> hidden;
  String? popularSource;
  Future<Json>? popular;
  @override
  void initState() {
    super.initState();
    order =
        widget.state.preferences
            .getStringList('homeOrder')
            ?.where(labels.containsKey)
            .toList() ??
        labels.keys.toList();
    for (final key in labels.keys) {
      if (!order.contains(key)) order.add(key);
    }
    hidden = (widget.state.preferences.getStringList('homeHidden') ?? [])
        .toSet();
    _discover();
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    _discover();
  }

  void _discover() {
    if (hidden.contains('popular')) return;
    final source =
        widget.state.sources.where((s) => s['language'] == 'en').firstOrNull ??
        widget.state.sources.firstOrNull;
    final id = source?['id'] as String?;
    if (id == null) {
      popularSource = null;
      popular = null;
      return;
    }
    if (id != popularSource) {
      popularSource = id;
      popular = widget.state.engine.browse(id);
    }
  }

  Future<void> customize() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Customize home',
                  style: TextStyle(fontSize: 22, fontFamily: 'Newsreader'),
                ),
              ),
              const Text(
                'Drag to reorder. Toggle the sections you want to see.',
                style: TextStyle(fontSize: 12),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: order.length,
                  onReorderItem: (from, to) {
                    setState(() => order.insert(to, order.removeAt(from)));
                    update(() {});
                  },
                  itemBuilder: (_, index) {
                    final key = order[index];
                    return SwitchListTile(
                      key: ValueKey(key),
                      title: Text(labels[key]!),
                      secondary: const Icon(Icons.drag_handle),
                      value: !hidden.contains(key),
                      onChanged: (v) {
                        setState(() {
                          if (v) {
                            hidden.remove(key);
                          } else {
                            hidden.add(key);
                          }
                        });
                        _discover();
                        update(() {});
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await widget.state.preferences.setStringList('homeOrder', order);
    await widget.state.preferences.setStringList('homeHidden', hidden.toList());
  }

  List<Manga> get recent => widget.state.mangaLibrary;
  List<Manga> get history {
    final items = recent
        .where(
          (m) => (widget.state.chapterStats[m.key]?['recent'] as int? ?? 0) > 0,
        )
        .toList();
    items.sort(
      (a, b) => (widget.state.chapterStats[b.key]!['recent'] as int).compareTo(
        widget.state.chapterStats[a.key]!['recent'] as int,
      ),
    );
    return items;
  }

  Widget shelf(String title, List<Manga> items, {String? subtitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeading(title),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            subtitle,
            style: TextStyle(color: mutedColor(context), fontSize: 12),
          ),
        ),
      SizedBox(
        height: 252,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length.clamp(0, 16),
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, index) => SizedBox(
            width: 144,
            child: MangaCard(
              items[index],
              heroTag: 'home:$title:$index:${items[index].key}',
              onTap: () => openManga(
                context,
                widget.state,
                items[index],
                coverHeroTag: 'home:$title:$index:${items[index].key}',
              ),
            ),
          ),
        ),
      ),
    ],
  );
  Widget section(String key) {
    final state = widget.state;
    switch (key) {
      case 'continue':
        final items = history;
        if (items.isEmpty) return const SizedBox.shrink();
        final manga = items.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading('Pick up where you left off'),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => openManga(context, state, manga),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CoverImage(manga.cover, width: 72, height: 104),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              manga.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${state.chapterStats[manga.key]?['completed'] ?? 0} chapters finished',
                              style: TextStyle(
                                color: mutedColor(context),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Continue the journey',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_outline),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 'recent':
        return recent.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 28),
                child: Text(
                  'Install a source in Browse, then save a title to your library. Your recent additions will appear here.',
                  style: TextStyle(
                    color: mutedColor(context),
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              )
            : shelf('Recently added', recent);
      case 'history':
        return history.length < 2
            ? const SizedBox.shrink()
            : shelf('Worlds you’ve visited', history);
      case 'popular':
        if (popular == null) return const SizedBox.shrink();
        return FutureBuilder<Json>(
          future: popular,
          builder: (_, snapshot) {
            final name =
                state.sources
                    .where((s) => s['id'] == popularSource)
                    .firstOrNull?['name'] ??
                'your source';
            if (snapshot.hasError) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: Text('Discoveries from $name unavailable'),
                  subtitle: const Text('Tap to retry this source'),
                  onTap: () => setState(
                    () => popular = state.engine.browse(popularSource!),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: LinearProgressIndicator(),
              );
            }
            final items = (snapshot.data!['items'] as List)
                .map((m) => Manga.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            return items.isEmpty
                ? const SizedBox.shrink()
                : shelf(
                    'Beyond your bookshelf',
                    items,
                    subtitle: 'Popular on $name · live from your source',
                  );
          },
        );
      case 'recommend':
        final genres = <String, int>{};
        for (final manga in history) {
          for (final genre
              in manga.genre
                  .split(',')
                  .map((g) => g.trim())
                  .where((g) => g.isNotEmpty)) {
            genres[genre] = (genres[genre] ?? 0) + 1;
          }
        }
        int score(Manga manga) => manga.genre
            .split(',')
            .fold(0, (sum, genre) => sum + (genres[genre.trim()] ?? 0));
        final suggestions =
            recent
                .where(
                  (m) =>
                      (state.chapterStats[m.key]?['recent'] as int? ?? 0) ==
                          0 &&
                      score(m) > 0,
                )
                .toList()
              ..sort((a, b) => score(b).compareTo(score(a)));
        return suggestions.isEmpty
            ? const SizedBox.shrink()
            : shelf(
                'From your library',
                suggestions,
                subtitle: 'Unread titles with genres you’ve been enjoying.',
              );
      case 'sources':
        if (state.sources.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              'Your sources',
              trailing: TextButton(
                onPressed: widget.onBrowse,
                child: const Text('View all'),
              ),
            ),
            SizedBox(
              height:
                  88 +
                  38 *
                      (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(
                        0,
                        3,
                      ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.sources.length.clamp(0, 12),
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final source = state.sources[index];
                  return SizedBox(
                    width: 180,
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SourceScreen(state, source),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.public,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${source['name']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${source['language']}'.toUpperCase(),
                                      style: TextStyle(
                                        color: mutedColor(context),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case 'stats':
        return Column(
          children: [
            const SectionHeading('At a glance'),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final width = stacked
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: QuickAccessTile(
                        icon: Icons.insights_outlined,
                        title: 'Statistics',
                        subtitle: '${state.library.length} titles in library',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReadingStatisticsScreen(state),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: QuickAccessTile(
                        icon: Icons.download_outlined,
                        title: 'Downloads',
                        subtitle: 'Read offline',
                        onTap: widget.onDownloads,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        sliver: SliverList.list(
          children: [
            Row(
              children: [
                const DreamMark(size: 30),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'dream reader',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Customize home',
                  onPressed: customize,
                  icon: const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: 'Settings & appearance',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(widget.state),
                    ),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ReadingRoom(
              titles: widget.state.library.length,
              unread: widget.state.unreadChapterCount,
              onBrowse: widget.onBrowse,
              onLibrary: widget.onLibrary,
            ),
            ...order.where((key) => !hidden.contains(key)).map(section),
          ],
        ),
      ),
    ],
  );
}
