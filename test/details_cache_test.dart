import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/platform/engine.dart';
import 'package:dream_reader/ui/details.dart';

class SlowDetailsEngine extends SourceEngine {
  final pending = Completer<Json>();
  @override
  bool get available => false;
  @override
  Future<Json> details(Manga manga) => pending.future;
}

void main() {
  testWidgets('cached chapters remain usable during a slow or failed refresh', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final db = DreamDatabase(NativeDatabase.memory());
    final engine = SlowDetailsEngine();
    final state = AppState(
      db,
      await SharedPreferences.getInstance(),
      engine: engine,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });
    const manga = Manga(sourceId: 's', url: 'cached', title: 'Cached title');
    await tester.runAsync(
      () => db.saveChapters(manga.key, [
        const Chapter(url: '1', name: 'Saved chapter'),
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(home: MangaDetailsScreen(state, manga)),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(engine.pending.isCompleted, isFalse);
    expect(find.text('Saved chapter'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start reading'),
          )
          .onPressed,
      isNotNull,
    );
    engine.pending.completeError(
      StateError('Source is temporarily unavailable'),
    );
    await tester.pump();
    expect(find.text('Saved chapter'), findsOneWidget);
    expect(find.textContaining('Could not refresh source'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
