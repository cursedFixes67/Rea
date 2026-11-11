import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../domain/models.dart';
import 'components.dart';
import 'theme.dart';

class DownloadsScreen extends StatefulWidget {
  final AppState state;
  const DownloadsScreen(this.state, {super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Json> jobs = [];
  Timer? timer;
  Object? error;
  bool polling = false;
  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.state.engine.available || polling) return;
    polling = true;
    try {
      final result = await widget.state.engine.call('downloadList');
      if (mounted) {
        setState(() {
          jobs = (result as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      polling = false;
    }
  }

  Future<void> _control(Json job, String action) async {
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
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 10),
        child: Text(
          'Take stories with you',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          '${jobs.where((j) => j['status'] == 'SUCCEEDED').length} chapters ready offline',
          style: const TextStyle(color: dreamMuted, fontSize: 12),
        ),
      ),
      Expanded(
        child: error != null
            ? ErrorNotice(error!, retry: _load)
            : jobs.isEmpty
            ? const EmptyState(
                icon: Icons.cloud_download_outlined,
                title: 'Stories to go',
                message: 'Download chapters from a title’s page and read them anywhere. Downloads continue in the background and resume completed pages after interruptions.',
              )
            : ListView.builder(
                itemCount: jobs.length,
                itemBuilder: (_, i) {
                  final job = jobs[i];
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
                              PopupMenuButton<String>(
                                onSelected: (action) => _control(job, action),
                                itemBuilder: (_) => [
                                  if (job['status'] != 'SUCCEEDED')
                                    PopupMenuItem(
                                      value: running ? 'pause' : 'resume',
                                      child: Text(
                                        running ? 'Pause' : 'Resume / retry',
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
                            style: const TextStyle(
                              color: dreamMuted,
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
                            style: const TextStyle(
                              color: dreamMuted,
                              fontSize: 10,
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
  String _status(String value) => switch (value) {
    'SUCCEEDED' => 'Ready offline',
    'RUNNING' => 'Downloading',
    'ENQUEUED' => 'Queued / waiting for network',
    'CANCELLED' => 'Paused',
    'FAILED' => 'Failed — tap menu to retry',
    _ => value.toLowerCase(),
  };
}
