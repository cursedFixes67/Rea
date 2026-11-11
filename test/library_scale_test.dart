import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';

void main() {
  test('aggregates and retrieves a 3000-title, 30000-chapter library', () async {
    final db = DreamDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.batch((batch) {
      for (var title = 0; title < 3000; title++) {
        final manga = Manga(
          sourceId: '1',
          url: '/$title',
          title: 'Synthetic title $title',
        );
        batch.insert(
          db.libraryEntries,
          LibraryEntriesCompanion.insert(
            key: manga.key,
            sourceId: manga.sourceId,
            title: manga.title,
            payload: jsonEncode(manga.toJson()),
          ),
        );
        for (var chapter = 0; chapter < 10; chapter++) {
          batch.insert(
            db.chapterEntries,
            ChapterEntriesCompanion.insert(
              mangaKey: manga.key,
              url: '/$title/$chapter',
              payload: '{}',
              completed: Value(chapter < 5),
            ),
          );
        }
      }
    });
    final watch = Stopwatch()..start();
    final rows = await db.watchLibrary().first;
    final stats = await db.watchChapterStats().first;
    watch.stop();
    expect(rows.length, 3000);
    expect(stats.length, 3000);
    expect(
      stats.values.every((s) => s['total'] == 10 && s['completed'] == 5),
      isTrue,
    );
    expect((await db.chapters('1::/2999')).length, 10);
    // Record measurements without claiming that host timings predict device FPS.
    // ignore: avoid_print
    print(
      'Host SQLite library + aggregate query: ${watch.elapsedMilliseconds} ms',
    );
  });
}
