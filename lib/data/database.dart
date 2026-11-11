import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/models.dart';
part 'database.g.dart';

class LibraryEntries extends Table {
  TextColumn get key => text()();
  TextColumn get sourceId => text()();
  TextColumn get title => text()();
  TextColumn get payload => text()();
  TextColumn get category =>
      text().withDefault(const Constant('Uncategorized'))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {key};
}

class ChapterEntries extends Table {
  TextColumn get mangaKey => text()();
  TextColumn get url => text()();
  TextColumn get payload => text()();
  IntColumn get page => integer().withDefault(const Constant(0))();
  IntColumn get totalPages => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastRead => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {mangaKey, url};
}

class RepositoryEntries extends Table {
  TextColumn get url => text()();
  TextColumn get name => text()();
  TextColumn get signer => text()();
  TextColumn get catalogue => text().withDefault(const Constant('[]'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {url};
}

class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mangaKey => text()();
  IntColumn get seconds => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [LibraryEntries, ChapterEntries, RepositoryEntries, ReadingSessions],
)
class DreamDatabase extends _$DreamDatabase {
  DreamDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'dream_reader',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.dart.js'),
              ),
            ),
      );
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX library_title ON library_entries(title COLLATE NOCASE)',
      );
      await customStatement(
        'CREATE INDEX chapters_recent ON chapter_entries(last_read DESC)',
      );
    },
  );
  Future<void> addManga(Manga manga) =>
      into(libraryEntries).insertOnConflictUpdate(
        LibraryEntriesCompanion.insert(
          key: manga.key,
          sourceId: manga.sourceId,
          title: manga.title,
          payload: jsonEncode(manga.toJson()),
        ),
      );
  Future<void> removeManga(String key) =>
      (delete(libraryEntries)..where((t) => t.key.equals(key))).go();
  Stream<List<LibraryEntry>> watchLibrary() => (select(
    libraryEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.addedAt)])).watch();
  Future<void> saveChapters(String mangaKey, List<Chapter> chapters) async {
    await batch((b) {
      for (final chapter in chapters) {
        b.insert(
          chapterEntries,
          ChapterEntriesCompanion.insert(
            mangaKey: mangaKey,
            url: chapter.url,
            payload: jsonEncode(chapter.toJson()),
          ),
          onConflict: DoUpdate(
            (old) => ChapterEntriesCompanion(
              payload: Value(jsonEncode(chapter.toJson())),
            ),
          ),
        );
      }
    });
  }

  Future<void> progress(String key, String url, int page, int total) =>
      (update(
        chapterEntries,
      )..where((t) => t.mangaKey.equals(key) & t.url.equals(url))).write(
        ChapterEntriesCompanion.custom(
          page: Variable(page),
          totalPages: Variable(total),
          completed:
              chapterEntries.completed |
              Variable(total > 0 && page >= total - 1),
          lastRead: Variable(DateTime.now()),
        ),
      );
  Future<List<ChapterEntry>> chapters(String key) =>
      (select(chapterEntries)..where((t) => t.mangaKey.equals(key))).get();
  Stream<Map<String, Json>> watchChapterStats() =>
      customSelect(
        'SELECT manga_key, COUNT(*) AS total, SUM(completed) AS completed, MAX(last_read) AS recent FROM chapter_entries GROUP BY manga_key',
        readsFrom: {chapterEntries},
      ).watch().map(
        (rows) => {
          for (final row in rows)
            row.read<String>('manga_key'): {
              'total': row.read<int>('total'),
              'completed': row.read<int>('completed'),
              'recent': row.readNullable<int>('recent') ?? 0,
            },
        },
      );

  Future<void> markRead(Iterable<String> keys, bool completed) async {
    await transaction(() async {
      for (final key in keys) {
        await (update(chapterEntries)..where((t) => t.mangaKey.equals(key)))
            .write(ChapterEntriesCompanion(completed: Value(completed)));
      }
    });
  }

  Future<Map<String, dynamic>> backup() async => {
    'version': 1,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'library': (await select(
      libraryEntries,
    ).get()).map((r) => r.toJson()).toList(),
    'chapters': (await select(
      chapterEntries,
    ).get()).map((r) => r.toJson()).toList(),
    'repositories': (await select(
      repositoryEntries,
    ).get()).map((r) => r.toJson()).toList(),
    'sessions': (await select(
      readingSessions,
    ).get()).map((r) => r.toJson()).toList(),
  };
  Future<void> restore(Map<String, dynamic> data) async {
    if (data['version'] != 1) {
      throw const FormatException('Unsupported backup version');
    }
    // Validate every row before the transaction; preserve existing local records.
    final library = (data['library'] as List)
        .map((e) => LibraryEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final chapters = (data['chapters'] as List)
        .map((e) => ChapterEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final repositories = (data['repositories'] as List)
        .map((e) => RepositoryEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final sessions = ((data['sessions'] as List?) ?? [])
        .map((e) => ReadingSession.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (sessions.any((s) => s.seconds < 0)) {
      throw const FormatException('Backup contains invalid reading time');
    }
    for (final row in library) {
      final manga = Manga.fromJson(
        jsonDecode(row.payload) as Map<String, dynamic>,
      );
      if (manga.key != row.key ||
          manga.sourceId != row.sourceId ||
          manga.title.isEmpty) {
        throw const FormatException(
          'Backup contains an inconsistent library identity',
        );
      }
    }
    for (final row in chapters) {
      final chapter = Chapter.fromJson(
        jsonDecode(row.payload) as Map<String, dynamic>,
      );
      if (chapter.url != row.url ||
          row.page < 0 ||
          row.totalPages < 0 ||
          (row.totalPages > 0 && row.page >= row.totalPages)) {
        throw const FormatException('Backup contains invalid chapter progress');
      }
    }
    await transaction(() async {
      final existingSessions = (await select(readingSessions).get())
          .map(
            (s) =>
                '${s.mangaKey}|${s.createdAt.millisecondsSinceEpoch}|${s.seconds}',
          )
          .toSet();
      await batch((b) {
        b.insertAll(libraryEntries, library, mode: InsertMode.insertOrIgnore);
        b.insertAll(chapterEntries, chapters, mode: InsertMode.insertOrIgnore);
        b.insertAll(
          repositoryEntries,
          repositories.map((r) => r.copyWith(enabled: false)).toList(),
          mode: InsertMode.insertOrIgnore,
        );
        for (final session in sessions) {
          final identity =
              '${session.mangaKey}|${session.createdAt.millisecondsSinceEpoch}|${session.seconds}';
          if (existingSessions.add(identity)) {
            b.insert(
              readingSessions,
              ReadingSessionsCompanion.insert(
                mangaKey: session.mangaKey,
                seconds: session.seconds,
                createdAt: Value(session.createdAt),
              ),
            );
          }
        }
      });
    });
  }
}
