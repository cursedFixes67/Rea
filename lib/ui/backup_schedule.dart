import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../data/app_state.dart';
import '../domain/models.dart';
import 'components.dart';

class BackupScheduleScreen extends StatefulWidget {
  final AppState state;
  const BackupScheduleScreen(this.state, {super.key});
  @override
  State<BackupScheduleScreen> createState() => _BackupScheduleScreenState();
}

class _BackupScheduleScreenState extends State<BackupScheduleScreen> {
  Json? status;
  Object? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await widget.state.engine.call('backupStatus');
      if (mounted) {
        setState(() {
          status = Map<String, dynamic>.from(result);
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> action(Future<void> Function() body) async {
    setState(() => busy = true);
    try {
      await body();
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> configure(int hours) async {
    final directory = await getApplicationDocumentsDirectory();
    await widget.state.engine.call('backupConfigure', {
      'hours': hours,
      'databasePath': path.join(directory.path, 'dream_reader.sqlite'),
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Automatic backups'),
      actions: [
        IconButton(
          tooltip: 'Refresh backup status',
          onPressed: busy ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: error != null
        ? ErrorNotice(error!, retry: load)
        : status == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'A little peace of mind.',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(fontFamily: 'Newsreader'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Android creates integrity-checked backups in a folder you choose, even when Dream Reader is closed. The system may defer a backup while the battery is low. Backups include your library, progress, categories, reading statistics, settings and download inventory. Image files and account credentials are excluded.',
              ),
              const SizedBox(height: 24),
              if (busy) const LinearProgressIndicator(),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(
                  (status!['folder'] as String).isEmpty
                      ? 'Choose backup folder'
                      : 'Change backup folder',
                ),
                subtitle: Text(
                  (status!['folder'] as String).isEmpty
                      ? 'Android will ask you to grant folder access'
                      : 'Folder access granted',
                ),
                onTap: busy
                    ? null
                    : () => action(() async {
                        await widget.state.engine.call('backupChooseDirectory');
                        await configure(status!['hours'] as int);
                      }),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: status!['hours'] as int,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Off')),
                  DropdownMenuItem(value: 24, child: Text('Every day')),
                  DropdownMenuItem(value: 168, child: Text('Every week')),
                ],
                onChanged: busy
                    ? null
                    : (value) => action(() => configure(value!)),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: busy || (status!['folder'] as String).isEmpty
                    ? null
                    : () => action(() async {
                        await configure(status!['hours'] as int);
                        await widget.state.engine.call('backupNow');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Backup queued. Refresh to see when it finishes.',
                              ),
                            ),
                          );
                        }
                      }),
                icon: const Icon(Icons.save_alt),
                label: const Text('Back up now'),
              ),
              const SizedBox(height: 24),
              if ((status!['lastSuccess'] as int) > 0)
                Text(
                  'Last successful backup: ${DateTime.fromMillisecondsSinceEpoch(status!['lastSuccess'] as int).toLocal()}',
                ),
              if ((status!['error'] as String).isNotEmpty)
                Text(
                  'Last backup failed: ${status!['error']}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              const Text(
                'Backups remain in your chosen folder until you remove them. Review the folder occasionally to manage storage.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
  );
}
