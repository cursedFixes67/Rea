import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/tracking.dart';
import '../domain/models.dart';
import 'components.dart';

class TrackingConnectionsScreen extends StatefulWidget {
  final AppState state;
  const TrackingConnectionsScreen(this.state, {super.key});
  @override
  State<TrackingConnectionsScreen> createState() =>
      _TrackingConnectionsScreenState();
}

class _TrackingConnectionsScreenState extends State<TrackingConnectionsScreen> {
  final connected = <Tracker, bool>{};
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      for (final tracker in Tracker.values) {
        connected[tracker] = await widget.state.tracking.connected(tracker);
      }
    } catch (_) {
      error = 'Secure credential storage is unavailable. Please unlock your device and retry.';
    }
    if (mounted) setState(() {});
  }

  Future<void> _configure(Tracker tracker) async {
    final controller = TextEditingController(
      text: widget.state.tracking.clientId(tracker),
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tracker.label} application'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use a public/native OAuth application registered for Dream Reader. No client secret is needed.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Public client ID',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Register this exact redirect URL:'),
              const SelectableText(TrackingService.redirect),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      await widget.state.tracking.disconnect(tracker);
      await widget.state.preferences.setString(
        'tracking.client.${tracker.name}',
        value,
      );
      await _load();
    }
  }

  Future<void> _connect(Tracker tracker) async {
    if (widget.state.tracking.clientId(tracker).isEmpty) {
      await _configure(tracker);
      if (!mounted || widget.state.tracking.clientId(tracker).isEmpty) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (connected[tracker] == true) {
        await widget.state.tracking.disconnect(tracker);
      } else {
        await widget.state.tracking.connect(tracker);
      }
      await _load();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tracking connections')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Your reading, together',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Link a title from its details page, then choose when to send your chapter progress. Disconnecting removes this device’s token; revoke app access on the service to invalidate it everywhere.',
        ),
        const SizedBox(height: 20),
        for (final tracker in Tracker.values)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tracker.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    connected[tracker] == true
                        ? 'Connected · credentials stored securely'
                        : widget.state.tracking.clientId(tracker).isEmpty
                        ? 'Requires a registered public client ID'
                        : 'Ready to connect',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: busy ? null : () => _connect(tracker),
                          child: Text(
                            connected[tracker] == true
                                ? 'Disconnect'
                                : 'Connect',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Application settings',
                        onPressed: busy ? null : () => _configure(tracker),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Tokens are excluded from backups. AniList authorization can access most of your AniList account data; review the service’s consent screen before approving.',
        ),
      ],
    ),
  );
}

class MangaTrackingScreen extends StatefulWidget {
  final AppState state;
  final Manga manga;
  const MangaTrackingScreen(this.state, this.manga, {super.key});
  @override
  State<MangaTrackingScreen> createState() => _MangaTrackingScreenState();
}

class _MangaTrackingScreenState extends State<MangaTrackingScreen> {
  Tracker tracker = Tracker.anilist;
  late final query = TextEditingController(text: widget.manga.title);
  List<Json> results = [];
  bool busy = false;
  String? error;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sync() => _run(() async {
    final rows = await widget.state.db.chapters(widget.manga.key);
    final complete = rows.where((r) => r.completed).toList();
    final numbers = complete
        .map((r) => Chapter.fromJson(jsonDecode(r.payload)).number)
        .where((n) => n >= 0);
    final latest = numbers.isEmpty
        ? complete.length
        : numbers.reduce(max).floor();
    final controller = TextEditingController(text: '$latest');
    if (!mounted) {
      controller.dispose();
      return;
    }
    final progress = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send progress to ${tracker.label}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Check the chapter number when sources use different numbering. Higher progress already on the service is preserved.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Last completed chapter',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final number = int.tryParse(controller.text);
              if (number != null && number >= 0 && number <= 1000000) {
                Navigator.pop(context, number);
              }
            },
            child: const Text('Send progress'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (progress == null || !mounted) return;
    final sent = await widget.state.tracking.sync(
      widget.manga.key,
      tracker,
      progress,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tracker.label} updated to chapter $sent')),
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final linked = widget.state.tracking.links(widget.manga.key)[tracker.name];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track your story'),
        actions: [
          IconButton(
            tooltip: 'Tracking connections',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrackingConnectionsScreen(widget.state),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.manga.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          SegmentedButton<Tracker>(
            segments: [
              for (final t in Tracker.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {tracker},
            onSelectionChanged: busy
                ? null
                : (value) => setState(() {
                    tracker = value.single;
                    results = [];
                    error = null;
                  }),
          ),
          const SizedBox(height: 20),
          if (linked != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linked · ${linked['title']}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: busy ? null : _sync,
                      icon: const Icon(Icons.sync),
                      label: const Text('Send reading progress'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _run(
                              () => widget.state.tracking.link(
                                widget.manga.key,
                                tracker,
                                null,
                              ),
                            ),
                      child: const Text('Unlink on this device'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: query,
            decoration: InputDecoration(
              labelText: 'Find the matching title',
              suffixIcon: IconButton(
                tooltip: 'Search tracker',
                onPressed: busy
                    ? null
                    : () => _run(() async {
                        results = await widget.state.tracking.search(
                          tracker,
                          query.text,
                        );
                      }),
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: busy
                ? null
                : (_) => _run(() async {
                    results = await widget.state.tracking.search(
                      tracker,
                      query.text,
                    );
                  }),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          for (final result in results)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: CoverImage('${result['cover']}', width: 44, height: 64),
              title: Text('${result['title']}'),
              subtitle: Text('${result['chapters'] ?? 'Unknown'} chapters'),
              trailing: TextButton(
                onPressed: busy
                    ? null
                    : () => _run(
                        () => widget.state.tracking.link(
                          widget.manga.key,
                          tracker,
                          result,
                        ),
                      ),
                child: const Text('Link'),
              ),
            ),
        ],
      ),
    );
  }
}
