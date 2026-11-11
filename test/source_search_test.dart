import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/data/repositories.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/platform/engine.dart';
import 'package:dream_reader/ui/browse.dart';
import 'package:dream_reader/ui/components.dart';

class DeferredSearchEngine extends SourceEngine {
  final requests = <({String query, int page, Completer<Json> result})>[];
  @override
  bool get available => false;
  @override
  Future<Json> browse(
    String id, {
    int page = 1,
    String query = '',
    String mode = 'popular',
    Json filters = const {},
  }) {
    final result = Completer<Json>();
    requests.add((query: query, page: page, result: result));
    return result.future;
  }
}

Json page(List<String> titles, {bool more = false}) => {
  'items': titles
      .map(
        (title) => Manga(sourceId: '1', url: '/$title', title: title).toJson(),
      )
      .toList(),
  'hasNext': more,
};

void main() {
  Future<AppState> state(WidgetTester tester, SourceEngine engine) async {
    SharedPreferences.setMockInitialValues({});
    final result = AppState(
      DreamDatabase(NativeDatabase.memory()),
      await SharedPreferences.getInstance(),
      engine: engine,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      result.dispose();
    });
    return result;
  }

  testWidgets(
    'search submitted while busy replaces stale results and deduplicates pages',
    (tester) async {
      final engine = DeferredSearchEngine();
      final app = await state(tester, engine);
      await tester.pumpWidget(
        MaterialApp(
          home: SourceScreen(app, const {
            'id': '1',
            'name': 'Synthetic source',
            'latest': true,
          }),
        ),
      );
      expect(engine.requests.length, 1);
      await tester.enterText(find.byType(TextField), 'first');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.enterText(find.byType(TextField), 'latest');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(
        engine.requests.length,
        1,
        reason: 'intermediate searches are coalesced',
      );
      engine.requests[0].result.complete(page(['Stale title']));
      await tester.pump();
      expect(engine.requests.length, 2);
      expect(engine.requests[1].query, 'latest');
      expect(engine.requests[1].page, 1);
      expect(find.text('Stale title'), findsNothing);
      engine.requests[1].result.complete(page(['Alpha'], more: true));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      await tester.ensureVisible(find.text('Discover more'));
      await tester.tap(find.text('Discover more'));
      await tester.pump();
      expect(engine.requests[2].page, 2);
      engine.requests[2].result.complete(page(['Alpha', 'Beta']));
      await tester.pumpAndSettle();
      expect(tester.widgetList<MangaCard>(find.byType(MangaCard)).length, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'catalogue clears search and recovers a removed language filter',
    (tester) async {
      final app = await state(tester, DeferredSearchEngine());
      app.catalogue = RepositoryService.parse(
        File('test/fixtures/keiyoushi-2026-11-11.pb').readAsBytesSync(),
        RepositoryService.defaultUrl,
      ).extensions;
      Widget screen() => MaterialApp(home: Scaffold(body: BrowseScreen(app)));
      await tester.pumpWidget(screen());
      await tester.tap(find.text('Catalogue'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'atsumaru');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear source search'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('EN'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('EN').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        'en',
      );
      app.catalogue = [];
      await tester.pumpWidget(screen());
      expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        'all',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
