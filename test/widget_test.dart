import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/main.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/platform/engine.dart';

class NoDeviceEngine extends SourceEngine {
  @override
  bool get available => false;
}

void main() {
  testWidgets('first launch discloses repository and allows disabling it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      DreamDatabase(NativeDatabase.memory()),
      await SharedPreferences.getInstance(),
      engine: NoDeviceEngine(),
    );
    await tester.pumpWidget(DreamReader(state: state));
    expect(find.text('Connect Keiyoushi'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
