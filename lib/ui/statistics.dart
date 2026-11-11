import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/database.dart';
import 'components.dart';

class ReadingStatisticsScreen extends StatefulWidget {
  final AppState state;
  const ReadingStatisticsScreen(this.state, {super.key});
  @override
  State<ReadingStatisticsScreen> createState() =>
      _ReadingStatisticsScreenState();
}

class _ReadingStatisticsScreenState extends State<ReadingStatisticsScreen> {
  late final Future<List<ReadingSession>> sessions = widget.state.db
      .select(widget.state.db.readingSessions)
      .get();
  DateTime day(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your reading rhythm')),
    body: FutureBuilder<List<ReadingSession>>(
      future: sessions,
      builder: (_, snapshot) {
        if (snapshot.hasError) return ErrorNotice(snapshot.error!);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final activity = <DateTime, int>{};
        var total = 0;
        for (final session in snapshot.data!) {
          if (session.seconds <= 0) continue;
          final date = day(session.createdAt);
          activity[date] = (activity[date] ?? 0) + session.seconds;
          total += session.seconds;
        }
        final today = day(DateTime.now());
        var cursor = activity.containsKey(today)
            ? today
            : today.subtract(const Duration(days: 1));
        var streak = 0;
        while (activity.containsKey(cursor)) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
        final completed = widget.state.chapterStats.values.fold<int>(
          0,
          (sum, row) => sum + (row['completed'] as int),
        );
        final month = activity.entries
            .where(
              (e) => e.key.year == today.year && e.key.month == today.month,
            )
            .fold<int>(0, (sum, entry) => sum + entry.value);
        final genres = <String, int>{};
        for (final manga in widget.state.mangaLibrary) {
          final count =
              widget.state.chapterStats[manga.key]?['completed'] as int? ?? 0;
          if (count == 0) continue;
          for (final genre
              in manga.genre
                  .split(',')
                  .map((g) => g.trim())
                  .where((g) => g.isNotEmpty)) {
            genres[genre] = (genres[genre] ?? 0) + count;
          }
        }
        final favorites = genres.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Every page counts.',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontFamily: 'Newsreader'),
            ),
            const SizedBox(height: 12),
            Text(
              'A quiet record of the worlds you’ve visited. All statistics stay on this device.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metric(
                  '${total ~/ 3600}h ${total % 3600 ~/ 60}m',
                  'Time with stories',
                  Icons.schedule,
                ),
                metric('$completed', 'Chapters completed', Icons.task_alt),
                metric(
                  '$streak days',
                  'Current streak',
                  Icons.local_fire_department_outlined,
                ),
                metric(
                  '${month ~/ 60} min',
                  'This month',
                  Icons.calendar_month,
                ),
              ],
            ),
            const SectionHeading('The last 12 weeks'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 12,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                      itemCount: 84,
                      itemBuilder: (_, index) {
                        final date = today.subtract(Duration(days: 83 - index));
                        final minutes = (activity[date] ?? 0) ~/ 60;
                        final label =
                            '${date.month}/${date.day}: $minutes minutes';
                        return Tooltip(
                          message: label,
                          child: Semantics(
                            label: label,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: minutes == 0
                                    ? Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                    : Theme.of(context).colorScheme.primary
                                          .withValues(
                                            alpha: (.25 + minutes / 60).clamp(
                                              .25,
                                              1,
                                            ),
                                          ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Each square is a day. Deeper color means more reading.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeading('Worlds you return to'),
            if (favorites.isEmpty)
              const Text(
                'Your most-read genres appear after you finish chapters.',
              )
            else
              ...favorites
                  .take(6)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text('${entry.value} chapters'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: entry.value / favorites.first.value,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            Text(
              '${widget.state.library.length} saved titles · ${activity.length} reading days',
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    ),
  );
  Widget metric(String value, String label, IconData icon) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 60) / 2,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}
