import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/platform/engine.dart';
import 'package:dream_reader/ui/details.dart';
import 'package:dream_reader/ui/downloads.dart';
import 'package:dream_reader/ui/shell.dart';
import 'package:dream_reader/ui/theme.dart';

const manga = Manga(
  sourceId: '1',
  url: '/synthetic',
  title: 'A remarkably long synthetic title for layout testing',
  author: 'Synthetic author',
  genre: 'Adventure, Fantasy',
  description: 'A synthetic description used only in automated tests.',
);
const chapter = Chapter(
  url: '/chapter',
  name: 'Chapter one: a long journey',
  number: 1,
);

class LayoutEngine extends SourceEngine {
  @override
  bool get available => true;
  @override
  Future<dynamic> call(String method, [Json args = const {}]) async {
    if (method == 'details') {
      return {
        'manga': manga.toJson(),
        'chapters': [chapter.toJson()],
      };
    }
    if (method == 'downloadList') {
      return [
        {
          'id': 'fixture',
          'mangaKey': manga.key,
          'chapterUrl': chapter.url,
          'title': manga.title,
          'chapter': chapter.name,
          'status': 'SUCCEEDED',
          'completed': 1,
          'total': 1,
          'bytes': 2048,
          'error': '',
        },
      ];
    }
    throw StateError(method);
  }
}

void main() {
  for (final screen in ['library', 'downloads', 'details']) {
    testWidgets('$screen populated controls fit 320px with 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final db = DreamDatabase(NativeDatabase.memory());
      final state = AppState(
        db,
        await SharedPreferences.getInstance(),
        engine: LayoutEngine(),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      });
      await tester.runAsync(() async {
        await db.addManga(manga);
        state.library = await db.watchLibrary().first;
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: dreamTheme(Appearance.dreamDark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: switch (screen) {
              'library' => LibraryScreen(state),
              'downloads' => DownloadsScreen(state),
              _ => MangaDetailsScreen(state, manga),
            },
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (screen == 'library') {
        await tester.ensureVisible(find.text(manga.title));
        await tester.pumpAndSettle();
        await tester.longPress(find.text(manga.title));
        await tester.pump();
        expect(find.text('1 selected'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } else if (screen == 'downloads') {
        await tester.tap(find.byTooltip('Select chapters'));
        await tester.pump();
        await tester.tap(find.text('Select visible'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      } else {
        await tester.scrollUntilVisible(
          find.byTooltip('Select chapters'),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Select chapters'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Select unread'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('1 selected'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
