import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';

void main() {
  test(
    'cached library metadata refreshes and counts exclude removed titles',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = DreamDatabase(NativeDatabase.memory());
      final state = AppState(db, await SharedPreferences.getInstance());
      addTearDown(state.dispose);
      const first = Manga(sourceId: '1', url: '/1', title: 'Original title');
      const second = Manga(sourceId: '1', url: '/2', title: 'Removed title');
      await db.addManga(first);
      await db.addManga(second);
      state.library = await db.watchLibrary().first;
      state.chapterStats = {
        first.key: {'total': 8, 'completed': 3},
        second.key: {'total': 100, 'completed': 10},
      };
      final before = state.mangaLibrary;
      expect(state.unreadChapterCount, 95);
      expect(state.hasManga(first), isTrue);
      expect(identical(before, state.mangaLibrary), isTrue);
      await db.addManga(
        Manga.fromJson({...first.toJson(), 'title': 'Updated title'}),
      );
      await db.removeManga(second.key);
      state.library = await db.watchLibrary().first;
      expect(state.mangaLibrary.single.title, 'Updated title');
      expect(state.unreadChapterCount, 5);
      expect(state.hasManga(second), isFalse);
      expect(
        before.length,
        2,
        reason: 'existing view snapshots remain consistent',
      );
    },
  );
  test(
    'updates exclude completed and removed-library chapters and react to reads',
    () async {
      final db = DreamDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      const manga = Manga(
        sourceId: '1',
        url: '/title',
        title: 'Synthetic title',
      );
      await db.addManga(manga);
      await db.saveChapters(manga.key, [
        const Chapter(url: '/1', name: 'One'),
        const Chapter(url: '/2', name: 'Two'),
      ]);
      await db.saveChapters('orphan', [
        const Chapter(url: '/hidden', name: 'Not in library'),
      ]);
      var rows = await db.watchUnreadChapters().first;
      expect(rows.map((r) => r.chapter.url), ['/2', '/1']);
      expect(
        Manga.fromJson(jsonDecode(rows.first.manga.payload)).title,
        manga.title,
      );
      await db.progress(manga.key, '/2', 0, 1);
      rows = await db.watchUnreadChapters().first;
      expect(rows.single.chapter.url, '/1');
      await db.removeManga(manga.key);
      expect(await db.watchUnreadChapters().first, isEmpty);
      expect(
        (await db.chapters(manga.key)).length,
        2,
        reason: 'removing a library entry preserves reading history',
      );
    },
  );
}
