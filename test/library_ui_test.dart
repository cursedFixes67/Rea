import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/platform/engine.dart';
import 'package:dream_reader/ui/shell.dart';

class LibraryDownloadEngine extends SourceEngine {
  @override
  bool get available => true;
  @override
  Future<dynamic> call(String method, [Json args = const {}]) async {
    expect(method, 'downloadList');
    return [
      {'mangaKey': '1::/alpha', 'status': 'SUCCEEDED'},
    ];
  }
}

void main() {
  testWidgets(
    'library remembers layout, clears search and filters downloaded titles',
    (tester) async {
      tester.view.physicalSize = const Size(432, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'libraryLayout': 'list',
        'librarySort': 'title',
        'libraryColumns': 4,
      });
      final preferences = await SharedPreferences.getInstance();
      final db = DreamDatabase(NativeDatabase.memory());
      final state = AppState(db, preferences, engine: LibraryDownloadEngine());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      });
      await tester.runAsync(() async {
        await db.addManga(
          const Manga(sourceId: '1', url: '/zeta', title: 'Zeta'),
        );
        await db.addManga(
          const Manga(sourceId: '1', url: '/alpha', title: 'Alpha'),
        );
        state.library = await db.watchLibrary().first;
      });
      Widget app() => MaterialApp(home: Scaffold(body: LibraryScreen(state)));
      await tester.pumpWidget(app());
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('Alpha')).dy,
        lessThan(tester.getTopLeft(find.text('Zeta')).dy),
      );
      expect(find.textContaining('1 offline'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pump();
      expect(find.text('No matching titles'), findsOneWidget);
      await tester.ensureVisible(find.text('Clear filters'));
      await tester.tap(find.text('Clear filters'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.tap(find.byTooltip('Library layout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compact grid'));
      await tester.pumpAndSettle();
      expect(preferences.getString('libraryLayout'), 'grid');
      expect(preferences.getInt('libraryColumns'), 4);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pump();
      expect(
        (tester.widget<GridView>(find.byType(GridView)).gridDelegate
                as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        4,
      );
      await tester.tap(find.byTooltip('Sort and filter library'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Available offline'));
      await tester.tap(find.text('Available offline'));
      await tester.pump();
      await tester.ensureVisible(find.text('View collection'));
      await tester.tap(find.text('View collection'));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Zeta'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
