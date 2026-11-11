import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/main.dart';
import 'package:dream_reader/platform/engine.dart';
import 'package:dream_reader/ui/components.dart';
import 'package:dream_reader/ui/details.dart';

class CoverEngine extends SourceEngine {
  @override
  bool get available => false;
  @override
  Future<Json> details(Manga manga) async => {
    'manga': manga.toJson(),
    'chapters': <Json>[],
  };
}

void main() {
  testWidgets(
    'cover transitions work with the same title in multiple shelves',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding': true});
      final db = DreamDatabase(NativeDatabase.memory());
      final state = AppState(
        db,
        await SharedPreferences.getInstance(),
        engine: CoverEngine(),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      });
      const manga = Manga(
        sourceId: '1',
        url: '/synthetic',
        title: 'Synthetic story',
      );
      await tester.runAsync(() async {
        await db.addManga(manga);
        state.library = await db.watchLibrary().first;
      });
      state.chapterStats = {
        manga.key: {'total': 1, 'completed': 0, 'recent': 1},
      };
      await tester.pumpWidget(DreamReader(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MangaCard).first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MangaDetailsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(MangaCard),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(MangaCard).first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MangaDetailsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Close Drift before Flutter tears down the hidden Updates stream.
      await tester.runAsync(db.close);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
