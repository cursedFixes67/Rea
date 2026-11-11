import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../domain/models.dart';
import 'components.dart';
import 'shell.dart' show openManga;

class GlobalSearchScreen extends StatefulWidget {
  final AppState state;
  const GlobalSearchScreen(this.state, {super.key});
  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final query = TextEditingController();
  final results = <String, List<Manga>>{};
  final errors = <String, String>{};
  final selected = <String>{};
  late List<String> history;
  int generation = 0, pending = 0;
  @override
  void initState() {
    super.initState();
    history = widget.state.preferences.getStringList('searchHistory') ?? [];
    final stored = widget.state.preferences.getStringList('searchSources');
    selected.addAll(
      stored ??
          widget.state.sources
              .where((s) => s['language'] == 'en')
              .map((s) => '${s['id']}'),
    );
    if (selected.isEmpty && widget.state.sources.isNotEmpty) {
      selected.add('${widget.state.sources.first['id']}');
    }
  }

  @override
  void dispose() {
    generation++;
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final text = query.text.trim();
    if (text.isEmpty || selected.isEmpty) return;
    FocusScope.of(context).unfocus();
    final current = ++generation;
    final sources = widget.state.sources
        .where((s) => selected.contains('${s['id']}'))
        .toList();
    setState(() {
      results.clear();
      errors.clear();
      pending = sources.length;
      history = [text, ...history.where((h) => h != text)].take(30).toList();
    });
    await widget.state.preferences.setStringList('searchHistory', history);
    var next = 0;
    Future<void> worker() async {
      while (next < sources.length && mounted && generation == current) {
        final source = sources[next++], id = '${sources[next - 1]['id']}';
        try {
          final result = await widget.state.engine.browse(id, query: text);
          if (!mounted || generation != current) return;
          setState(
            () => results[id] = (result['items'] as List)
                .map((j) => Manga.fromJson(Map<String, dynamic>.from(j)))
                .toList(),
          );
        } catch (error) {
          if (!mounted || generation != current) return;
          setState(() => errors[id] = '${source['name']}: $error');
        } finally {
          if (mounted && generation == current) setState(() => pending--);
        }
      }
    }

    await Future.wait(
      List.generate(sources.length.clamp(0, 3), (_) => worker()),
    );
  }

  Future<void> chooseSources() async {
    final selection = Set<String>.from(selected);
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Search your sources',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final source in widget.state.sources)
                      CheckboxListTile(
                        title: Text('${source['name']}'),
                        subtitle: Text('${source['language']}'.toUpperCase()),
                        value: selection.contains('${source['id']}'),
                        onChanged: (v) => update(() {
                          if (v == true) {
                            selection.add('${source['id']}');
                          } else {
                            selection.remove('${source['id']}');
                          }
                        }),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Use ${selection.length} sources'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (accepted == true && mounted) {
      setState(() {
        selected.clear();
        selected.addAll(selection);
      });
      await widget.state.preferences.setStringList(
        'searchSources',
        selected.toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Find a new obsession'),
      actions: [
        IconButton(
          tooltip: 'Choose sources',
          onPressed: chooseSources,
          icon: const Icon(Icons.tune),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: query,
            autofocus: true,
            onSubmitted: (_) => search(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search across ${selected.length} sources',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: search,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ),
        if (pending > 0) const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (selected.isEmpty)
                EmptyState(
                  icon: Icons.travel_explore,
                  title: 'Choose where to look',
                  message: 'Select installed sources to search their current catalogues.',
                  action: 'Choose sources',
                  onAction: chooseSources,
                ),
              if (results.isEmpty &&
                  errors.isEmpty &&
                  pending == 0 &&
                  history.isNotEmpty) ...[
                Row(
                  children: [
                    const Expanded(child: SectionHeading('Recent searches')),
                    TextButton(
                      onPressed: () async {
                        await widget.state.preferences.remove('searchHistory');
                        setState(history.clear);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: history
                      .map(
                        (h) => ActionChip(
                          label: Text(h),
                          onPressed: () {
                            query.text = h;
                            search();
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              for (final source in widget.state.sources.where(
                (s) => results.containsKey('${s['id']}'),
              )) ...[
                SectionHeading('${source['name']} · ${source['language']}'),
                if (results['${source['id']}']!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No matching titles in this source.'),
                  )
                else
                  SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: results['${source['id']}']!.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, index) {
                        final manga = results['${source['id']}']![index];
                        return SizedBox(
                          width: 140,
                          child: MangaCard(
                            manga,
                            onTap: () =>
                                openManga(context, widget.state, manga),
                          ),
                        );
                      },
                    ),
                  ),
              ],
              for (final error in errors.values)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(error),
                  ),
                ),
              if (pending > 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Searching $pending sources…'),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
