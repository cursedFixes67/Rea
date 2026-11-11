import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../domain/models.dart';
import 'components.dart';
import 'theme.dart';
import 'reader.dart';

class DownloadsScreen extends StatefulWidget {
  final AppState state;
  final bool active;
  const DownloadsScreen(this.state, {super.key, this.active = true});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with WidgetsBindingObserver {
  List<Json> jobs = [];
  Timer? timer;
  Object? error;
  bool polling = false;
  final pending = <String>{};
  final selected = <String>{};
  bool selecting = false, batchBusy = false;
  String filter = 'all';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _schedulePoll();
    });
  }

  bool foreground = true;
  void _schedulePoll() {
    timer?.cancel();
    if (!widget.active || !foreground || !widget.state.engine.available) return;
    _load();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void didUpdateWidget(DownloadsScreen old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _schedulePoll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _schedulePoll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted ||
        !widget.active ||
        !foreground ||
        ModalRoute.of(context)?.isCurrent == false ||
        !widget.state.engine.available ||
        polling) {
      return;
    }
    polling = true;
    try {
      final result = await widget.state.engine.call('downloadList');
      if (mounted) {
        setState(() {
          jobs = (result as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          error = null;
          selected.retainAll(jobs.map((j) => '${j['id']}'));
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      polling = false;
    }
  }

  Future<void> _readOffline(Json job) async {
    final id = '${job['id']}';
    if (pending.contains(id)) return;
    setState(() => pending.add(id));
    try {
      final key = '${job['mangaKey']}';
      final split = key.indexOf('::');
      if (split < 1) {
        throw StateError(
          'This download has no title identity. Download the chapter again from its source.',
        );
      }
      final manga =
          widget.state.mangaByKey[key] ??
          Manga(
            sourceId: key.substring(0, split),
            url: key.substring(split + 2),
            title: '${job['title']}',
          );
      var records = await widget.state.db.chapters(key);
      var chapters = records
          .map((r) => Chapter.fromJson(jsonDecode(r.payload)))
          .toList();
      final chapter =
          chapters.where((c) => c.url == job['chapterUrl']).firstOrNull ??
          Chapter(url: '${job['chapterUrl']}', name: '${job['chapter']}');
      if (!chapters.any((c) => c.url == chapter.url)) {
        await widget.state.db.saveChapters(key, [chapter]);
        chapters.add(chapter);
      }
      chapters.sort((a, b) => a.number.compareTo(b.number));
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReaderScreen(widget.state, manga, chapters, chapter),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => pending.remove(id));
    }
  }

  Future<void> _control(Json job, String action) async {
    final id = '${job['id']}';
    if (pending.contains(id)) return;
    if (action == 'delete') {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete downloaded chapter?'),
          content: Text('${job['title']} · ${job['chapter']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (yes != true) return;
    }
    if (!mounted || pending.contains(id)) return;
    setState(() => pending.add(id));
    try {
      await widget.state.engine.call('downloadControl', {
        'id': job['id'],
        'action': action,
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => pending.remove(id));
    }
  }

  Future<void> _deleteSelected() async {
    final ids = Set<String>.from(selected);
    if (ids.isEmpty || batchBusy) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${ids.length} downloaded chapters?'),
        content: const Text(
          'Downloaded images will be removed. Your library and reading progress will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete chapters'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() {
      batchBusy = true;
      pending.addAll(ids);
    });
    var failed = 0;
    for (final id in ids) {
      try {
        await widget.state.engine.call('downloadControl', {
          'id': id,
          'action': 'delete',
        });
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() {
      batchBusy = false;
      pending.removeAll(ids);
      selected.clear();
      selecting = false;
    });
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? '${ids.length} chapters deleted'
                : '${ids.length - failed} deleted; $failed could not be deleted. Try again.',
          ),
        ),
      );
    }
  }

  String _space(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }

  @override
  Widget build(BuildContext context) {
    final ready = jobs.where((j) => j['status'] == 'SUCCEEDED').length;
    final bytes = jobs.fold<int>(
      0,
      (sum, j) => sum + (j['bytes'] as num? ?? 0).toInt(),
    );
    final visible = jobs
        .where(
          (j) => switch (filter) {
            'ready' => j['status'] == 'SUCCEEDED',
            'active' => [
              'RUNNING',
              'ENQUEUED',
              'BLOCKED',
            ].contains(j['status']),
            _ => true,
          },
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Downloads',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
              ),
              if (jobs.isNotEmpty)
                IconButton(
                  tooltip: selecting ? 'Finish selecting' : 'Select chapters',
                  onPressed: batchBusy
                      ? null
                      : () => setState(() {
                          selecting = !selecting;
                          selected.clear();
                        }),
                  icon: Icon(selecting ? Icons.close : Icons.checklist),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Text(
            '$ready chapters ready offline · ${_space(bytes)} used',
            style: TextStyle(color: mutedColor(context), fontSize: 12),
          ),
        ),
        if (jobs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
            child: selecting
                ? Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${selected.length} selected'),
                      TextButton(
                        onPressed: batchBusy
                            ? null
                            : () => setState(
                                () => selected.addAll(
                                  visible.map((j) => '${j['id']}'),
                                ),
                              ),
                        child: const Text('Select visible'),
                      ),
                      TextButton.icon(
                        onPressed: selected.isEmpty || batchBusy
                            ? null
                            : _deleteSelected,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        {
                              'all': 'All',
                              'active': 'Active',
                              'ready': 'Ready offline',
                            }.entries
                            .map(
                              (entry) => ChoiceChip(
                                label: Text(entry.value),
                                selected: filter == entry.key,
                                onSelected: (_) =>
                                    setState(() => filter = entry.key),
                              ),
                            )
                            .toList(),
                  ),
          ),
        if (batchBusy) const LinearProgressIndicator(),
        Expanded(
          child: error != null
              ? ErrorNotice(error!, retry: _load)
              : jobs.isEmpty
              ? const EmptyState(
                  icon: Icons.cloud_download_outlined,
                  title: 'Read without a connection',
                  message: 'Download chapters from a title’s page and read them anywhere. Downloads continue in the background and resume completed pages after interruptions.',
                )
              : visible.isEmpty
              ? const EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'No chapters in this view',
                  message: 'Choose All to see your complete download queue.',
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final job = visible[i];
                    final running = [
                      'RUNNING',
                      'ENQUEUED',
                      'BLOCKED',
                    ].contains(job['status']);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${job['title']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (selecting)
                                  Checkbox(
                                    semanticLabel: 'Select ${job['chapter']}',
                                    value: selected.contains('${job['id']}'),
                                    onChanged: batchBusy
                                        ? null
                                        : (value) => setState(() {
                                            if (value == true) {
                                              selected.add('${job['id']}');
                                            } else {
                                              selected.remove('${job['id']}');
                                            }
                                          }),
                                  )
                                else if (pending.contains('${job['id']}'))
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                else
                                  PopupMenuButton<String>(
                                    onSelected: (action) =>
                                        _control(job, action),
                                    itemBuilder: (_) => [
                                      if (![
                                        'SUCCEEDED',
                                        'CORRUPT',
                                      ].contains(job['status']))
                                        PopupMenuItem(
                                          value: running ? 'pause' : 'resume',
                                          child: Text(
                                            running
                                                ? 'Pause'
                                                : 'Resume / retry',
                                          ),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            Text(
                              '${job['chapter']}',
                              style: TextStyle(
                                color: mutedColor(context),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            LinearProgressIndicator(
                              value:
                                  (job['completed'] as num) /
                                  (job['total'] as num).clamp(1, 100000),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${job['completed']} / ${job['total']} pages · ${_status('${job['status']}')}',
                              style: TextStyle(
                                color: mutedColor(context),
                                fontSize: 10,
                              ),
                            ),
                            if (job['status'] == 'SUCCEEDED')
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: pending.contains('${job['id']}')
                                      ? null
                                      : () => _readOffline(job),
                                  icon: const Icon(
                                    Icons.auto_stories_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Read offline'),
                                ),
                              ),
                            if ('${job['error']}'.isNotEmpty)
                              Text(
                                '${job['error']}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _status(String value) => switch (value) {
    'SUCCEEDED' => 'Ready offline',
    'RUNNING' => 'Downloading',
    'ENQUEUED' => 'Queued / waiting for network',
    'CANCELLED' => 'Paused',
    'FAILED' => 'Failed — tap menu to retry',
    'CORRUPT' => 'Download again from its source',
    _ => value.toLowerCase(),
  };
}
