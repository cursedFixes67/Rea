import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/data/backup.dart';
import 'package:dream_reader/domain/models.dart';

void main() {
  test(
    'backup round trip preserves progress and never replaces existing records',
    () async {
      final source = DreamDatabase(NativeDatabase.memory());
      final target = DreamDatabase(NativeDatabase.memory());
      addTearDown(source.close);
      addTearDown(target.close);
      const manga = Manga(
        sourceId: '9223372036854775806',
        url: '/manga/test',
        title: 'Test manga',
      );
      const chapter = Chapter(url: '/chapter/1', name: 'Chapter 1');
      await source.addManga(manga);
      await source.saveChapters(manga.key, [chapter]);
      await source.progress(manga.key, chapter.url, 3, 10);
      await source
          .into(source.readingSessions)
          .insert(
            ReadingSessionsCompanion.insert(mangaKey: manga.key, seconds: 180),
          );
      final decoded = BackupCodec.decode(
        BackupCodec.encode(await source.backup()),
      );
      await target.restore(decoded);
      expect((await target.chapters(manga.key)).single.page, 3);
      await target.progress(manga.key, chapter.url, 7, 10);
      await target.restore(decoded);
      expect((await target.chapters(manga.key)).single.page, 7);
      expect(
        (await target.select(target.readingSessions).get()).single.seconds,
        180,
      );
      expect((await target.select(target.libraryEntries).get()).length, 1);
    },
  );
  test(
    'chapter refresh preserves progress while updating source metadata',
    () async {
      final database = DreamDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.saveChapters('source::manga', [
        const Chapter(url: '/1', name: 'Old name'),
      ]);
      await database.progress('source::manga', '/1', 4, 10);
      await database.saveChapters('source::manga', [
        const Chapter(
          url: '/1',
          name: 'Corrected name',
          memo: {'token': 'synthetic'},
        ),
      ]);
      final row = (await database.chapters('source::manga')).single;
      expect(row.page, 4);
      expect(Chapter.fromJson(jsonDecode(row.payload)).name, 'Corrected name');
      expect(
        Chapter.fromJson(jsonDecode(row.payload)).memo['token'],
        'synthetic',
      );
    },
  );
  test('invalid backup rows cannot partially mutate the library', () async {
    final database = DreamDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.addManga(
      const Manga(sourceId: '1', url: '/valid', title: 'Original'),
    );
    final backup = await database.backup();
    (backup['library'] as List).add({
      ...Map<String, dynamic>.from((backup['library'] as List).first),
      'key': '1::tampered',
    });
    await expectLater(database.restore(backup), throwsFormatException);
    expect((await database.select(database.libraryEntries).get()).length, 1);
  });
  test(
    'rereading preserves completed state until explicitly marked unread',
    () async {
      final database = DreamDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.saveChapters('s::m', [
        const Chapter(url: '/1', name: 'One'),
      ]);
      await database.progress('s::m', '/1', 9, 10);
      await database.progress('s::m', '/1', 0, 10);
      expect((await database.chapters('s::m')).single.completed, isTrue);
      await database.markRead(['s::m'], false);
      expect((await database.chapters('s::m')).single.completed, isFalse);
    },
  );
  test('tampered backup is rejected before database import', () {
    final backup = BackupCodec.encode({
      'version': 1,
      'library': [],
      'chapters': [],
      'repositories': [],
    });
    final envelope = jsonDecode(utf8.decode(backup)) as Map<String, dynamic>;
    envelope['payload'] = '${envelope['payload']} ';
    expect(
      () => BackupCodec.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
      ),
      throwsFormatException,
    );
  });
}
