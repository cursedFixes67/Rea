import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../data/app_state.dart';
import '../data/backup.dart';
import '../data/mihon_backup.dart';
import '../data/repositories.dart';
import 'theme.dart';
import 'statistics.dart';
import 'backup_schedule.dart';
import 'components.dart';
import 'tracking.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen(this.state, {super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;
  Future<void> _operation(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your reading space')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Row(
          children: [
            DreamMark(size: 44),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dream Reader',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                Text(
                  'A home for your next chapter',
                  style: TextStyle(color: dreamMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SectionHeading('Set the mood'),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: Appearance.values
              .map(
                (a) => ChoiceChip(
                  label: Text(a.label),
                  selected: widget.state.appearance == a,
                  onSelected: (_) async {
                    await widget.state.setAppearance(a);
                    if (mounted) setState(() {});
                  },
                ),
              )
              .toList(),
        ),
        if (widget.state.appearance == Appearance.custom)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Wrap(
              spacing: 12,
              children:
                  [
                        dreamMint,
                        const Color(0xFFFFC48C),
                        const Color(0xFFCBB5FD),
                        const Color(0xFF8ED0F4),
                        const Color(0xFFF4A8BD),
                      ]
                      .map(
                        (color) => IconButton.filled(
                          tooltip:
                              'Choose accent ${color.toARGB32().toRadixString(16)}',
                          style: IconButton.styleFrom(backgroundColor: color),
                          onPressed: () async {
                            await widget.state.setAccent(color);
                            if (mounted) setState(() {});
                          },
                          icon: Icon(
                            widget.state.accent == color
                                ? Icons.check
                                : Icons.circle,
                            color: Colors.black54,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        const SectionHeading('Your collection'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.dns_outlined),
          title: const Text('Extension repositories'),
          subtitle: Text('${widget.state.repositoryList.length} connected'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RepositoriesScreen(widget.state)),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Download on Wi-Fi only'),
          subtitle: const Text('Applies to new chapter downloads'),
          value: widget.state.preferences.getBool('wifiOnly') ?? true,
          onChanged: (v) async {
            await widget.state.preferences.setBool('wifiOnly', v);
            if (mounted) setState(() {});
          },
        ),
        if (widget.state.engine.available)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sync),
            title: const Text('Tracking connections'),
            subtitle: const Text('AniList and MyAnimeList'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrackingConnectionsScreen(widget.state),
              ),
            ),
          ),
        const SectionHeading('Keep your stories safe'),
        if (widget.state.engine.available)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat),
            title: const Text('Automatic backups'),
            subtitle: const Text('Daily or weekly · your chosen folder'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BackupScheduleScreen(widget.state),
              ),
            ),
          ),
        if (busy) const LinearProgressIndicator(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.save_alt),
          title: const Text('Export backup'),
          subtitle: const Text('Library, progress, categories and settings'),
          onTap: busy ? null : () => _operation(_export),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore),
          title: const Text('Restore a backup'),
          subtitle: const Text(
            'Preview and merge; existing entries are preserved',
          ),
          onTap: busy ? null : () => _operation(_restore),
        ),
        const SectionHeading('Reading rhythm'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insights),
          title: const Text('Reading statistics'),
          subtitle: const Text('Streaks, activity and favorite genres'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReadingStatisticsScreen(widget.state),
            ),
          ),
        ),
        FutureBuilder(
          future: widget.state.db.select(widget.state.db.readingSessions).get(),
          builder: (_, snapshot) {
            final seconds =
                snapshot.data?.fold<int>(
                  0,
                  (total, row) => total + row.seconds,
                ) ??
                0;
            final days =
                snapshot.data
                    ?.map(
                      (r) =>
                          '${r.createdAt.year}-${r.createdAt.month}-${r.createdAt.day}',
                    )
                    .toSet()
                    .length ??
                0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${seconds ~/ 60}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'minutes read',
                          style: TextStyle(fontSize: 11, color: dreamMuted),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '$days',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'reading days',
                          style: TextStyle(fontSize: 11, color: dreamMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SectionHeading('Made for your privacy'),
        const Text(
          'Your library and reading history are stored locally. Dream Reader does not collect analytics. Repositories and source websites receive requests when you browse, synchronize or read. Installed extensions share the app’s network and app-storage access.',
          style: TextStyle(color: dreamMuted, height: 1.7, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: const Text('Open-source licenses'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Dream Reader',
            applicationVersion: '1.0.0',
          ),
        ),
      ],
    ),
  );
  Future<void> _export() async {
    final payload = await widget.state.db.backup();
    if (widget.state.engine.available) {
      payload['downloads'] = await widget.state.engine.call('downloadList');
    }
    payload['settings'] = {
      for (final key in widget.state.preferences.getKeys())
        key: widget.state.preferences.get(key),
    };
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save Dream Reader backup',
      fileName:
          'DreamReader-${DateTime.now().toIso8601String().substring(0, 10)}.dreambackup',
      bytes: await compute(BackupCodec.encode, payload),
    );
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup exported with SHA-256 integrity check'),
        ),
      );
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.pickFile(type: FileType.any);
    if (picked == null) return;
    final length = await picked.length();
    if (length != null && length > 64 * 1024 * 1024) {
      throw const FormatException('Backup exceeds 64 MiB');
    }
    final bytes = await picked.readAsBytes();
    final payload = bytes.length >= 2 && bytes[0] == 31 && bytes[1] == 139
        ? await compute(MihonBackupImporter.decode, bytes)
        : await compute(BackupCodec.decode, bytes);
    if (!mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore preview'),
        content: Text(
          '${payload['importNotes'] ?? ''}\n\n${(payload['library'] as List).length} library entries\n${(payload['chapters'] as List).length} chapter records\n${(payload['repositories'] as List).length} repositories\n\nExisting library and chapter records are preserved. New entries are merged. Extension APKs must be installed again. Downloaded image files are not included; download those chapters again. Existing settings are preserved. Imported repositories are disabled until you review and enable them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Merge backup'),
          ),
        ],
      ),
    );
    if (proceed != true) return;
    await widget.state.db.restore(payload);
    if (payload['downloads'] is List) {
      await widget.state.preferences.setString(
        'restoredDownloadInventory',
        jsonEncode(payload['downloads']),
      );
    }
    final settings = payload['settings'];
    if (settings is Map) {
      for (final entry in settings.entries) {
        final key = '${entry.key}', value = entry.value;
        if (key == 'bookmarks' && value is String) {
          final imported = jsonDecode(value) as Map<String, dynamic>;
          final existing = jsonDecode(
            widget.state.preferences.getString(key) ?? '{}',
          ) as Map<String, dynamic>;
          await widget.state.preferences.setString(
            key,
            jsonEncode({...imported, ...existing}),
          );
          continue;
        }
        if (widget.state.preferences.containsKey(key) || key == 'onboarding') {
          continue;
        }
        if (value is String) {
          await widget.state.preferences.setString(key, value);
        } else if (value is bool) {
          await widget.state.preferences.setBool(key, value);
        } else if (value is int) {
          await widget.state.preferences.setInt(key, value);
        } else if (value is double) {
          await widget.state.preferences.setDouble(key, value);
        } else if (value is List && value.every((v) => v is String)) {
          await widget.state.preferences.setStringList(
            key,
            value.cast<String>(),
          );
        }
      }
    }
    await widget.state.loadRepositories();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup merged successfully')),
      );
    }
  }
}

class RepositoriesScreen extends StatefulWidget {
  final AppState state;
  const RepositoriesScreen(this.state, {super.key});
  @override
  State<RepositoriesScreen> createState() => _RepositoriesScreenState();
}

class _RepositoriesScreenState extends State<RepositoriesScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state,
    builder: (_, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Repositories'),
        actions: [
          IconButton(
            tooltip: 'Add repository',
            onPressed: busy ? null : _add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Choose who you trust',
            style: TextStyle(fontFamily: 'Newsreader', fontSize: 30),
          ),
          const SizedBox(height: 12),
          const Text(
            'Repositories publish third-party executable extensions. Only add repositories whose maintainers and signing keys you trust.',
            style: TextStyle(color: dreamMuted, fontSize: 13, height: 1.7),
          ),
          if (busy || widget.state.syncing) const LinearProgressIndicator(),
          const SizedBox(height: 24),
          ...widget.state.repositoryList.map(
            (repo) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        repo.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      value: repo.enabled,
                      onChanged: (v) async {
                        await (widget.state.db.update(
                          widget.state.db.repositoryEntries,
                        )..where((r) => r.url.equals(repo.url))).write(
                          repo.copyWith(enabled: v),
                        );
                        await widget.state.loadRepositories();
                      },
                    ),
                    Text(
                      repo.url,
                      style: const TextStyle(color: dreamMuted, fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      'SHA-256: ${repo.signer}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            repo.syncedAt == null
                                ? 'Not synchronized yet'
                                : 'Synced ${repo.syncedAt!.toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(
                              color: dreamMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove repository',
                          onPressed: () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Remove ${repo.name}?'),
                                content: const Text(
                                  'Installed extensions and your library remain on this device.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (yes == true) {
                              await (widget.state.db.delete(
                                widget.state.db.repositoryEntries,
                              )..where((r) => r.url.equals(repo.url))).go();
                              await widget.state.loadRepositories();
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.state.syncError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('${widget.state.syncError}'),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.state.syncing
                ? null
                : widget.state.syncRepositories,
            icon: const Icon(Icons.sync),
            label: const Text('Synchronize repositories'),
          ),
        ],
      ),
    ),
  );
  Future<void> _add() async {
    final controller = TextEditingController(
      text: RepositoryService.defaultUrl,
    );
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add extension repository'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'HTTPS index.pb or repo.json URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Inspect'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty) return;
    setState(() => busy = true);
    try {
      final snapshot = await widget.state.inspectRepository(url);
      if (!mounted) return;
      final trust = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Trust ${snapshot.name}?'),
          content: SelectableText(
            '${snapshot.extensions.length} extensions\n\nSigner SHA-256:\n${snapshot.signer}\n\nVerify this fingerprint with the repository maintainer. Extensions can access app storage and the network.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Trust repository'),
            ),
          ],
        ),
      );
      if (trust == true) await widget.state.addRepository(url, snapshot);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
