import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/platform/engine.dart';
import 'package:dream_reader/ui/downloads.dart';

class QueueEngine extends SourceEngine {
  final deleted = <String>[];
  final jobs = List.generate(
    3,
    (i) => <String, dynamic>{
      'id': '$i',
      'title': 'Synthetic title $i',
      'chapter': 'Chapter $i',
      'status': i == 2 ? 'ENQUEUED' : 'SUCCEEDED',
      'completed': i == 2 ? 0 : 1,
      'total': 1,
      'bytes': 1024,
      'error': '',
    },
  );
  @override
  bool get available => true;
  @override
  Future<dynamic> call(String method, [Json args = const {}]) async {
    if (method == 'downloadList') return jobs;
    if (method == 'downloadControl') {
      expect(args['action'], 'delete');
      deleted.add(args['id'] as String);
      jobs.removeWhere((job) => job['id'] == args['id']);
      return {'ok': true};
    }
    throw StateError(method);
  }
}

void main() {
  testWidgets(
    'filtered batch deletion requires confirmation and preserves other jobs',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final engine = QueueEngine();
      final state = AppState(
        DreamDatabase(NativeDatabase.memory()),
        await SharedPreferences.getInstance(),
        engine: engine,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DownloadsScreen(state))),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ready offline'));
      await tester.pump();
      expect(find.text('Synthetic title 2'), findsNothing);
      await tester.tap(find.byTooltip('Select chapters'));
      await tester.pump();
      await tester.tap(find.text('Select visible'));
      await tester.pump();
      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(engine.deleted, isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(engine.deleted, isEmpty);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete chapters'));
      await tester.pumpAndSettle();
      expect(engine.deleted, ['0', '1']);
      expect(engine.jobs.single['id'], '2');
      expect(find.text('No chapters in this view'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
