import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/platform/engine.dart';

class DelayedSourceEngine extends SourceEngine {
  final reply = Completer<dynamic>();
  int calls = 0;
  @override
  bool get available => true;
  @override
  Future<dynamic> call(String method, [Json args = const {}]) {
    expect(method, 'sources');
    calls++;
    return reply.future;
  }
}

void main() {
  test('local initialization does not wait for extension startup and refreshes coalesce', () async {
    SharedPreferences.setMockInitialValues({});
    final engine = DelayedSourceEngine();
    final state = AppState(
      DreamDatabase(NativeDatabase.memory()),
      await SharedPreferences.getInstance(),
      engine: engine,
    );
    addTearDown(state.dispose);
    await state.initialize().timeout(const Duration(seconds: 2));
    expect(state.sourcesLoading, isTrue);
    expect(engine.reply.isCompleted, isFalse);
    final refresh = state.refreshSources();
    expect(engine.calls, 1);
    engine.reply.complete({
      'sources': [
        {'id': '1', 'name': 'Synthetic source'},
      ],
      'errors': [],
      'installed': {},
    });
    await refresh;
    expect(state.sourcesLoading, isFalse);
    expect(state.sources.single['id'], '1');
  });
  test('startup failure is reported without becoming an unhandled background error', () async {
    SharedPreferences.setMockInitialValues({});
    final engine = DelayedSourceEngine();
    final state = AppState(
      DreamDatabase(NativeDatabase.memory()),
      await SharedPreferences.getInstance(),
      engine: engine,
    );
    addTearDown(state.dispose);
    await state.initialize();
    engine.reply.completeError(StateError('Synthetic source failure'));
    await Future<void>.delayed(Duration.zero);
    expect(state.sourcesLoading, isFalse);
    expect(
      state.sourceErrors.single['message'],
      contains('Synthetic source failure'),
    );
  });
  test('late startup reply does not notify disposed app state', () async {
    SharedPreferences.setMockInitialValues({});
    final engine = DelayedSourceEngine();
    final state = AppState(
      DreamDatabase(NativeDatabase.memory()),
      await SharedPreferences.getInstance(),
      engine: engine,
    );
    await state.initialize();
    state.dispose();
    engine.reply.complete({'sources': [], 'errors': [], 'installed': {}});
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
}
