import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../domain/models.dart';
import 'components.dart';
import 'failure_dialog.dart';
import 'theme.dart';
import 'source_filters.dart';
import 'global_search.dart';
import 'shell.dart' show openManga;
import 'settings.dart' show RepositoriesScreen;

class BrowseScreen extends StatefulWidget {
  final AppState state;
  const BrowseScreen(this.state, {super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  int section = 0;
  String query = '', language = 'all';
  bool mature = false;
  String? installing;
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final extensions = state.catalogue
        .where(
          (e) =>
              e.matchesSearch(query) &&
              (language == 'all' ||
                  e.sources.any((s) => s.language == language)) &&
              (mature || !e.adultOnly),
        )
        .toList();
    final sources = state.sources
        .where(
          (s) =>
              '${s['name']}'.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
    final languages = {
      'all',
      ...state.catalogue.expand((e) => e.sources.map((s) => s.language)),
    }.toList()..sort();
    return NestedScrollView(
      headerSliverBuilder: (context, scrolled) => [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Explore sources',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Search all sources',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GlobalSearchScreen(state),
                        ),
                      ),
                      icon: const Icon(Icons.travel_explore),
                    ),
                    IconButton(
                      tooltip: 'Manage repositories',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RepositoriesScreen(state),
                        ),
                      ),
                      icon: const Icon(Icons.dns_outlined),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: MediaQuery.textScalerOf(context).scale(1) > 1.3
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final entry in {
                            0: 'Installed',
                            1: 'Catalogue',
                          }.entries)
                            ChoiceChip(
                              label: Text(entry.value),
                              selected: section == entry.key,
                              onSelected: (_) =>
                                  setState(() => section = entry.key),
                            ),
                          _refreshButton(),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(
                                  value: 0,
                                  label: Text('Installed'),
                                ),
                                ButtonSegment(
                                  value: 1,
                                  label: Text('Catalogue'),
                                ),
                              ],
                              selected: {section},
                              onSelectionChanged: (v) =>
                                  setState(() => section = v.first),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _refreshButton(),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: TextField(
                  onChanged: (s) => setState(() => query = s),
                  decoration: InputDecoration(
                    hintText: section == 0
                        ? 'Search installed sources'
                        : 'Search the live catalogue',
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              if (state.syncing) const LinearProgressIndicator(),
              if (state.syncError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '${state.syncError}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (section == 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<String>(
                        isExpanded:
                            MediaQuery.textScalerOf(context).scale(1) > 1.3,
                        itemHeight: null,
                        value: language,
                        items: languages
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text(
                                  l == 'all'
                                      ? 'All languages'
                                      : l.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => language = v!),
                      ),
                      FilterChip(
                        label: const Text('Adult sources'),
                        selected: mature,
                        onSelected: (v) => setState(() => mature = v),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      body: section == 0
          ? sources.isEmpty
                ? ListView(
                    children: [
                      EmptyState(
                        icon: Icons.travel_explore,
                        title: query.trim().isEmpty
                            ? 'Choose your sources'
                            : 'Not installed yet',
                        message: query.trim().isEmpty
                            ? 'Install a source from the catalogue to start browsing its titles.'
                            : extensions.isNotEmpty
                            ? '${extensions.length} matching extensions are available in your catalogue.'
                            : 'No installed source matches “${query.trim()}”. Search the catalogue or refresh your repositories.',
                        action: query.trim().isEmpty
                            ? 'Browse catalogue'
                            : 'Search catalogue',
                        onAction: () {
                          setState(() => section = 1);
                          if (state.catalogue.isEmpty) {
                            state.syncRepositories();
                          }
                        },
                      ),
                      ...state.sourceErrors.map(
                        (e) => ListTile(
                          leading: const Icon(Icons.error_outline),
                          title: Text('${e['packageName'] ?? 'Engine'}'),
                          subtitle: Text('${e['message']}'),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: sources.length,
                    itemBuilder: (_, i) {
                      final source = sources[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 9,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary
                              .withValues(alpha: .1),
                          child: Icon(
                            Icons.public,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          '${source['name']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${source['language']}'.toUpperCase()),
                        trailing: source['preferences'] == true
                            ? IconButton(
                                tooltip: 'Source preferences',
                                icon: const Icon(Icons.tune),
                                onPressed: () => state.engine.call(
                                  'preferences',
                                  {'sourceId': source['id']},
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SourceScreen(state, source),
                          ),
                        ),
                      );
                    },
                  )
          : extensions.isEmpty
          ? EmptyState(
              icon: Icons.extension_outlined,
              title: state.syncing
                  ? 'Gathering your sources'
                  : 'No matching extensions',
              message: state.repositoryList.isEmpty
                  ? 'Add a repository to discover community sources.'
                  : 'Refresh the catalogue or adjust your language and content filters.',
              action: 'Manage repositories',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RepositoriesScreen(state)),
              ),
            )
          : ListView.builder(
              itemCount: extensions.length,
              itemBuilder: (_, i) {
                final extension = extensions[i];
                final current = state.installed[extension.packageName];
                final installed = current != null;
                final outdated =
                    installed && (current['code'] as int) < extension.code;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  leading: CoverImage(extension.iconUrl, width: 44, height: 44),
                  title: Text(
                    extension.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${extension.sources.length > 2 ? '${extension.sources.length} languages' : extension.language.toUpperCase()} · v${extension.version}${extension.contentLabel.isEmpty ? '' : ' · ${extension.contentLabel}'}',
                    style: TextStyle(fontSize: 10, color: mutedColor(context)),
                  ),
                  trailing: installing == extension.packageName
                      ? const SizedBox.square(
                          dimension: 23,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: installing != null
                              ? null
                              : installed && !outdated
                              ? () => _remove(extension)
                              : () => _install(extension),
                          child: Text(
                            outdated
                                ? 'Update'
                                : installed
                                ? 'Remove'
                                : 'Install',
                          ),
                        ),
                );
              },
            ),
    );
  }

  Widget _refreshButton() => IconButton(
    tooltip: 'Refresh',
    onPressed: widget.state.syncing
        ? null
        : () async {
            try {
              await widget.state.syncRepositories();
              if (widget.state.engine.available) {
                await widget.state.refreshSources();
              }
            } catch (error) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$error')));
              }
            }
          },
    icon: const Icon(Icons.refresh),
  );

  Future<void> _install(ExtensionEntry entry) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install ${entry.name}?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Extensions execute third-party code with Dream Reader’s network and app-storage access. A separate process provides crash separation, not a security sandbox.',
              ),
              if (entry.contentLabel.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${entry.contentLabel}: this source may include adult titles. Use its source preferences to control available content.',
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Repository: ${entry.repository}\n\nSigner SHA-256:\n${entry.signer}',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 12),
              const Text(
                'The APK signature and package identity will be verified before loading.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Trust & install'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => installing = entry.packageName);
    try {
      await widget.state.install(entry);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${entry.name} installed')));
      }
    } catch (error) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) =>
              FailureDialog(title: 'Extension could not install', error: error),
        );
      }
    } finally {
      if (mounted) setState(() => installing = null);
    }
  }

  Future<void> _remove(ExtensionEntry entry) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${entry.name}?'),
        content: const Text(
          'Library entries remain saved. Reading online requires reinstalling this source.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await widget.state.engine.uninstall(entry.packageName);
      await widget.state.refreshSources();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class SourceScreen extends StatefulWidget {
  final AppState state;
  final Json source;
  const SourceScreen(this.state, this.source, {super.key});
  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  final search = TextEditingController();
  final items = <Manga>[];
  Json filters = {};
  int page = 1;
  bool loading = false, hasNext = true;
  String mode = 'popular';
  Object? error;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
      if (reset) {
        page = 1;
        items.clear();
        hasNext = true;
      }
    });
    try {
      final result = await widget.state.engine.browse(
        '${widget.source['id']}',
        page: page,
        query: search.text.trim(),
        mode: mode,
        filters: filters,
      );
      if (!mounted) return;
      setState(() {
        items.addAll(
          (result['items'] as List).map(
            (m) => Manga.fromJson(Map<String, dynamic>.from(m)),
          ),
        );
        hasNext = result['hasNext'] == true;
        page++;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _filters() async {
    try {
      final response = await widget.state.engine.call('filters', {
        'sourceId': '${widget.source['id']}',
      });
      if (!mounted) return;
      final schema = (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (schema.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This source does not provide search filters.'),
          ),
        );
        return;
      }
      final selected = await showModalBottomSheet<Json>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: SourceFiltersSheet(schema, filters),
        ),
      );
      if (selected != null && mounted) {
        filters = selected;
        await _load(reset: true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.source['name']}'),
      actions: [
        IconButton(
          tooltip: 'Open source website',
          onPressed: () async {
            try {
              await widget.state.engine.call('openWebsite', {
                'sourceId': '${widget.source['id']}',
              });
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$error')));
              }
            }
          },
          icon: const Icon(Icons.public),
        ),
        IconButton(
          tooltip: 'Source filters',
          onPressed: loading ? null : _filters,
          icon: Badge(
            isLabelVisible: filters.isNotEmpty,
            child: const Icon(Icons.tune),
          ),
        ),
        if (widget.source['latest'] == true)
          PopupMenuButton<String>(
            onSelected: (v) {
              mode = v;
              _load(reset: true);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'popular', child: Text('Popular')),
              PopupMenuItem(value: 'latest', child: Text('Latest updates')),
            ],
          ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: search,
            onSubmitted: (_) => _load(reset: true),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search ${widget.source['name']}',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        Expanded(
          child: error != null && items.isEmpty
              ? ErrorNotice(error!, retry: () => _load(reset: true))
              : items.isEmpty && !loading
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'No stories found',
                  message: 'Try a different title or search term.',
                )
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.sizeOf(context).width > 700
                              ? 6
                              : 3,
                          childAspectRatio: .55,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 22,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => MangaCard(
                          items[i],
                          onTap: () =>
                              openManga(context, widget.state, items[i]),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            if (error != null) Text('$error'),
                            if (hasNext && items.isNotEmpty)
                              OutlinedButton(
                                onPressed: loading ? null : _load,
                                child: const Text('Discover more'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    ),
  );
}
