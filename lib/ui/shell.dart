import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'components.dart';
import 'browse.dart';
import 'details.dart';
import 'downloads.dart';
import 'home.dart';

class WelcomeScreen extends StatefulWidget {
  final AppState state;
  const WelcomeScreen(this.state, {super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool repository = true, busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(32),
            children: [
              const DreamMark(size: 70),
              const SizedBox(height: 42),
              const Text(
                'A little escape.\nAn endless library.',
                style: TextStyle(
                  fontFamily: 'Newsreader',
                  fontSize: 48,
                  height: 1.08,
                  letterSpacing: -1.8,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Dream Reader',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Make room for the stories you love. Your library and reading history stay on your device.',
                style: TextStyle(height: 1.7, color: mutedColor(context)),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SwitchListTile(
                    value: repository,
                    onChanged: (v) => setState(() => repository = v),
                    title: const Text('Connect Keiyoushi'),
                    subtitle: const Text(
                      'Fetch the official community extension catalogue. Extensions are third-party code; installing each one requires your consent. You can disable or remove this repository in settings.',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await widget.state.finishOnboarding(repository);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('$error')));
                          }
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                child: Text(
                  busy ? 'Opening your library…' : 'Begin your next chapter',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No account required. No analytics.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor(context), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DreamShell extends StatefulWidget {
  final AppState state;
  const DreamShell(this.state, {super.key});
  @override
  State<DreamShell> createState() => _DreamShellState();
}

class _DreamShellState extends State<DreamShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        widget.state,
        onBrowse: () => setState(() => tab = 2),
        onDownloads: () => setState(() => tab = 4),
        onLibrary: () => setState(() => tab = 1),
      ),
      LibraryScreen(widget.state),
      BrowseScreen(widget.state),
      UpdatesScreen(widget.state),
      DownloadsScreen(widget.state),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            selectedIcon: Icon(Icons.nightlight_round),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
        ],
      ),
    );
  }
}

void openManga(BuildContext context, AppState state, Manga manga) =>
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MangaDetailsScreen(state, manga)),
    );

class LibraryScreen extends StatefulWidget {
  final AppState state;
  const LibraryScreen(this.state, {super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String query = '', category = 'All';
  String readingFilter = 'all', statusFilter = 'all', sort = 'added';
  bool list = false;
  int columns = 3;
  final selected = <String>{};
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final categories = {
      'All',
      ...state.library.map((r) => r.category),
    }.toList();
    final entries = state.library
        .where(
          (r) =>
              r.title.toLowerCase().contains(query.toLowerCase()) &&
              (category == 'All' || category == r.category) &&
              (readingFilter == 'all' ||
                  (readingFilter == 'unread' &&
                      ((state.chapterStats[r.key]?['total'] as int? ?? 0) >
                          (state.chapterStats[r.key]?['completed'] as int? ??
                              0))) ||
                  (readingFilter == 'started' &&
                      (state.chapterStats[r.key]?['recent'] as int? ?? 0) >
                          0) ||
                  (readingFilter == 'finished' &&
                      (state.chapterStats[r.key]?['total'] as int? ?? 0) > 0 &&
                      state.chapterStats[r.key]?['total'] ==
                          state.chapterStats[r.key]?['completed'])) &&
              (statusFilter == 'all' ||
                  Manga.fromJson(jsonDecode(r.payload)).status ==
                      int.parse(statusFilter)),
        )
        .toList();
    if (sort == 'recent') {
      entries.sort(
        (a, b) => (state.chapterStats[b.key]?['recent'] as int? ?? 0).compareTo(
          state.chapterStats[a.key]?['recent'] as int? ?? 0,
        ),
      );
    }
    if (sort == 'unread') {
      entries.sort((a, b) => _unread(b.key).compareTo(_unread(a.key)));
    }
    if (sort == 'title') {
      entries.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected.isEmpty
                      ? 'Your library'
                      : '${selected.length} selected',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
              ),
              if (selected.isNotEmpty) ...[
                PopupMenuButton<String>(
                  tooltip: 'Selection actions',
                  onSelected: _batch,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'read',
                      child: Text('Mark chapters read'),
                    ),
                    PopupMenuItem(
                      value: 'unread',
                      child: Text('Mark chapters unread'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from library'),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Move to category',
                  onPressed: _category,
                  icon: const Icon(Icons.folder_outlined),
                ),
                IconButton(
                  tooltip: 'Clear selection',
                  onPressed: () => setState(selected.clear),
                  icon: const Icon(Icons.close),
                ),
              ] else ...[
                IconButton(
                  tooltip: 'Sort and filter library',
                  onPressed: _filters,
                  icon: Icon(Icons.tune),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => setState(() {
                    list = v == 'list';
                    columns = v == 'compact' ? 4 : 3;
                  }),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'grid', child: Text('Cover grid')),
                    PopupMenuItem(
                      value: 'compact',
                      child: Text('Compact grid'),
                    ),
                    PopupMenuItem(value: 'list', child: Text('List')),
                  ],
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: TextField(
            onChanged: (s) => setState(() => query = s),
            decoration: const InputDecoration(
              hintText: 'Find a story in your library',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        SizedBox(
          height: 45,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(categories[i]),
              selected: category == categories[i],
              onSelected: (_) => setState(() => category = categories[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: entries.isEmpty
              ? const EmptyState(
                  icon: Icons.library_books_outlined,
                  title: 'Your library is empty',
                  message: 'Save titles from Browse to build your collection. Long-press a cover to organize titles into categories.',
                )
              : list
              ? ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final manga = Manga.fromJson(
                      jsonDecode(entries[i].payload),
                    );
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: CoverImage(manga.cover, width: 45, height: 65),
                      title: Text(manga.title),
                      subtitle: Text(
                        '${entries[i].category} · ${_unread(manga.key)} unread',
                      ),
                      onTap: () => _tap(manga),
                      onLongPress: () =>
                          setState(() => selected.add(manga.key)),
                      selected: selected.contains(manga.key),
                    );
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.sizeOf(context).width > 700
                        ? columns * 2
                        : columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 20,
                    childAspectRatio: .56,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final manga = Manga.fromJson(
                      jsonDecode(entries[i].payload),
                    );
                    return Stack(
                      children: [
                        MangaCard(
                          manga,
                          selected: selected.contains(manga.key),
                          onTap: () => _tap(manga),
                          onLongPress: () =>
                              setState(() => selected.add(manga.key)),
                        ),
                        if (_unread(manga.key) > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_unread(manga.key)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  int _unread(String key) =>
      (widget.state.chapterStats[key]?['total'] as int? ?? 0) -
      (widget.state.chapterStats[key]?['completed'] as int? ?? 0);

  Future<void> _batch(String action) async {
    if (action == 'remove') {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Remove ${selected.length} titles?'),
          content: const Text(
            'Reading history and downloaded chapters remain on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (yes != true) return;
      await widget.state.db.transaction(() async {
        for (final key in selected) {
          await widget.state.db.removeManga(key);
        }
      });
    } else {
      await widget.state.db.markRead(selected, action == 'read');
    }
    if (mounted) setState(selected.clear);
  }

  Future<void> _filters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading('Make this shelf yours'),
                  const Text('Sort by'),
                  Wrap(
                    spacing: 8,
                    children:
                        {
                              'added': 'Recently added',
                              'title': 'Title',
                              'recent': 'Last read',
                              'unread': 'Unread count',
                            }.entries
                            .map(
                              (e) => ChoiceChip(
                                label: Text(e.value),
                                selected: sort == e.key,
                                onSelected: (_) {
                                  setState(() => sort = e.key);
                                  update(() {});
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Smart collection'),
                  Wrap(
                    spacing: 8,
                    children:
                        {
                              'all': 'Every title',
                              'unread': 'Unread chapters',
                              'started': 'In progress',
                              'finished': 'Caught up',
                            }.entries
                            .map(
                              (e) => ChoiceChip(
                                label: Text(e.value),
                                selected: readingFilter == e.key,
                                onSelected: (_) {
                                  setState(() => readingFilter = e.key);
                                  update(() {});
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Publication status'),
                  Wrap(
                    spacing: 8,
                    children:
                        {
                              'all': 'Any',
                              '1': 'Ongoing',
                              '2': 'Completed',
                              '6': 'Hiatus',
                              '5': 'Cancelled',
                            }.entries
                            .map(
                              (e) => ChoiceChip(
                                label: Text(e.value),
                                selected: statusFilter == e.key,
                                onSelected: (_) {
                                  setState(() => statusFilter = e.key);
                                  update(() {});
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('View collection'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _tap(Manga manga) {
    if (selected.isEmpty) {
      openManga(context, widget.state, manga);
    } else {
      setState(
        () => selected.contains(manga.key)
            ? selected.remove(manga.key)
            : selected.add(manga.key),
      );
    }
  }

  Future<void> _category() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to a category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Move'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    for (final key in selected) {
      await (widget.state.db.update(
        widget.state.db.libraryEntries,
      )..where((r) => r.key.equals(key))).write(
        widget.state.library
            .firstWhere((r) => r.key == key)
            .copyWith(category: value),
      );
    }
    if (mounted) setState(selected.clear);
  }
}

class UpdatesScreen extends StatefulWidget {
  final AppState state;
  const UpdatesScreen(this.state, {super.key});
  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool busy = false;
  int done = 0;
  final errors = <String>[];
  Future<void> _refresh() async {
    setState(() {
      busy = true;
      done = 0;
      errors.clear();
    });
    for (final manga in widget.state.mangaLibrary) {
      try {
        final result = await widget.state.engine.details(manga);
        final chapters = (result['chapters'] as List)
            .map((c) => Chapter.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        await widget.state.db.saveChapters(manga.key, chapters);
      } catch (error) {
        errors.add('${manga.title}: $error');
      }
      if (!mounted) return;
      setState(() => done++);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 16, 10),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'New chapters',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Update library',
              onPressed: busy || widget.state.library.isEmpty ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      if (busy)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: done / widget.state.library.length.clamp(1, 100000),
              ),
              const SizedBox(height: 8),
              Text('Checking $done / ${widget.state.library.length} titles'),
            ],
          ),
        ),
      if (errors.isNotEmpty)
        ExpansionTile(
          title: Text('${errors.length} titles could not update'),
          children: errors
              .map(
                (e) => ListTile(
                  title: Text(e, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
        ),
      Expanded(
        child: widget.state.library.isEmpty
            ? const EmptyState(
                icon: Icons.bolt_outlined,
                title: 'Stay in the story',
                message: 'Add titles to your library, then check here for unread chapters.',
              )
            : FutureBuilder(
                future: widget.state.db
                    .select(widget.state.db.chapterEntries)
                    .get(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = snapshot.data!
                      .where(
                        (r) =>
                            !r.completed &&
                            widget.state.library.any(
                              (m) => m.key == r.mangaKey,
                            ),
                      )
                      .toList();
                  if (rows.isEmpty) {
                    return EmptyState(
                      icon: Icons.done_all,
                      title: 'All caught up',
                      message: 'Check your sources for more chapters.',
                      action: 'Check for updates',
                      onAction: busy ? null : _refresh,
                    );
                  }
                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final row = rows[i];
                      final entry = widget.state.library.firstWhere(
                        (m) => m.key == row.mangaKey,
                      );
                      final manga = Manga.fromJson(jsonDecode(entry.payload));
                      final chapter = Chapter.fromJson(jsonDecode(row.payload));
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 7,
                        ),
                        leading: CoverImage(manga.cover, width: 44, height: 60),
                        title: Text(
                          manga.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(chapter.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => openManga(context, widget.state, manga),
                      );
                    },
                  );
                },
              ),
      ),
    ],
  );
}
