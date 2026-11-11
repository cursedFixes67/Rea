import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/platform/engine.dart';
import 'package:dream_reader/ui/downloads.dart';
import 'package:dream_reader/ui/reader.dart';

class DownloadFixtureEngine extends SourceEngine {
  final String? imagePath;
  final int pageCount;
  int lists = 0, online = 0;
  DownloadFixtureEngine({this.imagePath, this.pageCount = 1});
  @override
  bool get available => true;
  @override
  Future<dynamic> call(String method, [Json args = const {}]) async {
    switch (method) {
      case 'downloadList':
        lists++;
        return imagePath == null
            ? []
            : [
                {
                  'id': 'test-download',
                  'mangaKey': '1::/manga',
                  'chapterUrl': '/chapter',
                  'title': 'Synthetic title',
                  'chapter': 'Chapter one',
                  'status': 'SUCCEEDED',
                  'completed': 1,
                  'total': 1,
                  'bytes': 128,
                  'error': '',
                },
              ];
      case 'downloadPages':
        return List.generate(
          pageCount,
          (_) => {'url': imagePath!, 'headers': <String, String>{}},
        );
      case 'readerImageInfo':
        return {'tiled': false};
      case 'readerSettings':
        return null;
      default:
        online++;
        throw StateError('Unexpected online call: $method');
    }
  }
}

void main() {
  testWidgets('download polling pauses for hidden tabs and covered routes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final engine = DownloadFixtureEngine();
    final state = AppState(
      DreamDatabase(NativeDatabase.memory()),
      await SharedPreferences.getInstance(),
      engine: engine,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      state.dispose();
    });
    final navigator = GlobalKey<NavigatorState>();
    Widget app(bool active) => MaterialApp(
      navigatorKey: navigator,
      home: Scaffold(body: DownloadsScreen(state, active: active)),
    );
    await tester.pumpWidget(app(false));
    await tester.pump(const Duration(seconds: 4));
    expect(engine.lists, 0);
    await tester.pumpWidget(app(true));
    await tester.pump();
    expect(engine.lists, 1);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Another screen')),
      ),
    );
    await tester.pumpAndSettle();
    final before = engine.lists;
    await tester.pump(const Duration(seconds: 4));
    expect(engine.lists, before);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    expect(engine.lists, greaterThan(before));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final readable in [true, false]) {
    testWidgets(
      'offline reader ${readable ? 'completes decoded page' : 'does not complete a failed image'}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final image = File(
          readable
              ? 'test/fixtures/reader-test-page.png'
              : 'test/fixtures/missing-page.png',
        ).absolute.path;
        final engine = DownloadFixtureEngine(imagePath: image);
        final db = DreamDatabase(NativeDatabase.memory());
        final state = AppState(
          db,
          await SharedPreferences.getInstance(),
          engine: engine,
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          });
          state.dispose();
        });
        await tester.runAsync(
          () => db.saveChapters('1::/manga', [
            const Chapter(url: '/chapter', name: 'Chapter one'),
          ]),
        );
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: DownloadsScreen(state))),
        );
        await tester.pump();
        await tester.tap(find.text('Read offline'));
        // Image file I/O is real asynchronous work; advancing only the fake
        // animation clock cannot settle the image's loading indicator.
        for (var attempt = 0; attempt < 100; attempt++) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          });
          final decoded = tester
              .widgetList<RawImage>(find.byType(RawImage))
              .any((image) => image.image != null);
          if ((readable && decoded) ||
              (!readable &&
                  find.text('Page 1 failed to load').evaluate().isNotEmpty)) {
            break;
          }
        }
        expect(find.byType(ReaderScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        final progress = await tester.runAsync(() => db.chapters('1::/manga'));
        if (readable) {
          expect(
            tester
                .widgetList<RawImage>(find.byType(RawImage))
                .any((image) => image.image != null),
            isTrue,
          );
        } else {
          expect(find.text('Page 1 failed to load'), findsOneWidget);
        }
        expect(progress!.single.completed, readable);
        expect(
          engine.online,
          0,
          reason: 'complete downloaded chapter should need no source request',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
      },
    );
  }
  testWidgets('double-page resume preserves the saved spread', (tester) async {
    SharedPreferences.setMockInitialValues({'readerMode': 'double'});
    final engine = DownloadFixtureEngine(
      imagePath: File('test/fixtures/reader-test-page.png').absolute.path,
      pageCount: 4,
    );
    final db = DreamDatabase(NativeDatabase.memory());
    final state = AppState(
      db,
      await SharedPreferences.getInstance(),
      engine: engine,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      state.dispose();
    });
    const chapter = Chapter(url: '/chapter', name: 'Chapter one');
    await tester.runAsync(() async {
      await db.saveChapters('1::/manga', [chapter]);
      await db.progress('1::/manga', chapter.url, 1, 4);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderScreen(
          state,
          const Manga(sourceId: '1', url: '/manga', title: 'Synthetic title'),
          const [chapter],
          chapter,
        ),
      ),
    );
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      if (find.byType(PageView).evaluate().isNotEmpty) break;
    }
    expect(find.byType(PageView), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    final progress = await tester.runAsync(() => db.chapters('1::/manga'));
    expect(
      progress!.single.page,
      1,
      reason: 'opening pages 1–2 must not advance into pages 3–4',
    );
    expect(progress.single.completed, isFalse);
  });
}
