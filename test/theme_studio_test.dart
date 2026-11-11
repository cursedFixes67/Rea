import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/ui/theme.dart';
import 'package:dream_reader/ui/theme_studio.dart';
import 'package:dream_reader/ui/failure_dialog.dart';

void main() {
  test('custom seeds produce readable text and button colors', () {
    for (final seed in [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      const Color(0xff160018),
    ]) {
      final theme = dreamTheme(Appearance.custom, seed: seed);
      final colors = theme.colorScheme;
      for (final pair in [
        [colors.primary, colors.surface],
        [colors.primary, colors.onPrimary],
      ]) {
        final a = pair.first.computeLuminance(),
            b = pair.last.computeLuminance();
        final ratio = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: '$seed');
      }
    }
    expect(
      dreamTheme(Appearance.dreamDark, seed: Colors.red).colorScheme.primary,
      dreamMint,
    );
  });
  testWidgets('studio validates and persists custom appearance', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final state = AppState(DreamDatabase(NativeDatabase.memory()), preferences);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(home: ThemeStudioScreen(state)));
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.ensureVisible(find.text('Apply appearance'));
    await tester.tap(find.text('Apply appearance'));
    await tester.pump();
    expect(preferences.containsKey('accent'), isFalse);
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '010203');
    await tester.ensureVisible(find.text('Relaxed'));
    await tester.tap(find.text('Relaxed'));
    await tester.ensureVisible(find.text('Apply appearance'));
    await tester.tap(find.text('Apply appearance'));
    await tester.pumpAndSettle();
    expect(preferences.getInt('accent'), 0xff010203);
    expect(preferences.getInt('interfaceDensity'), 1);
    expect(preferences.getString('interfaceFont'), 'Manrope');
    expect(state.appearance, Appearance.custom);
    expect(tester.takeException(), isNull);
  });
  testWidgets('extension errors keep details behind an explicit disclosure', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FailureDialog(
            title: 'Extension could not install',
            error: PlatformException(
              code: 'SOURCE_ERROR',
              message:
                  'TypeReference constructed without actual type information',
            ),
          ),
        ),
      ),
    );
    expect(
      find.textContaining('Install the latest app update'),
      findsOneWidget,
    );
    expect(find.textContaining('SOURCE_ERROR:'), findsNothing);
    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SOURCE_ERROR:'), findsOneWidget);
    expect(find.text('Copy details'), findsOneWidget);
  });
}
