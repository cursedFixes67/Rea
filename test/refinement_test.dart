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
import 'package:dream_reader/ui/theme.dart';
import 'package:dream_reader/ui/home.dart';
import 'package:dream_reader/ui/settings.dart';

class OfflineEngine extends SourceEngine {
  @override
  bool get available => false;
}

void main() {
  test('secondary text meets normal-text contrast in every appearance', () {
    for (final preset in Appearance.values) {
      final theme = dreamTheme(preset);
      final foreground = theme.colorScheme.onSurfaceVariant.computeLuminance();
      for (final background in [
        theme.scaffoldBackgroundColor,
        theme.cardTheme.color!,
      ]) {
        final luminance = background.computeLuminance();
        final contrast = (foreground > luminance)
            ? (foreground + .05) / (luminance + .05)
            : (luminance + .05) / (foreground + .05);
        expect(contrast, greaterThanOrEqualTo(4.5), reason: preset.label);
      }
    }
  });
  test(
    'failed final image saves its position without completing a chapter',
    () async {
      final db = DreamDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.saveChapters('s::m', [const Chapter(url: '/1', name: 'One')]);
      await db.progress('s::m', '/1', 9, 10, allowComplete: false);
      var row = (await db.chapters('s::m')).single;
      expect(row.page, 9);
      expect(row.completed, isFalse);
      await db.progress('s::m', '/1', 9, 10, allowComplete: true);
      await db.progress('s::m', '/1', 0, 10, allowComplete: false);
      row = (await db.chapters('s::m')).single;
      expect(
        row.completed,
        isTrue,
        reason: 'rereading must preserve completion',
      );
    },
  );
  testWidgets(
    'Atsumaru and Kagane are discoverable without enabling adult-only sources',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = DreamDatabase(NativeDatabase.memory());
      final state = AppState(
        db,
        await SharedPreferences.getInstance(),
        engine: OfflineEngine(),
      );
      addTearDown(state.dispose);
      state.catalogue = RepositoryService.parse(
        File('test/fixtures/keiyoushi-2026-11-11.pb').readAsBytesSync(),
        RepositoryService.defaultUrl,
      ).extensions;
      await tester.pumpWidget(
        MaterialApp(
          theme: dreamTheme(Appearance.dreamDark),
          home: Scaffold(body: BrowseScreen(state)),
        ),
      );
      await tester.enterText(find.byType(TextField), '  ATSUMARU  ');
      await tester.pump();
      expect(
        find.text('1 matching extensions are available in your catalogue.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Search catalogue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search catalogue'));
      await tester.pump();
      expect(find.text('Atsumaru'), findsOneWidget);
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).selected,
        isFalse,
      );
      await tester.enterText(find.byType(TextField), 'kagane');
      await tester.pump();
      expect(find.text('Kagane'), findsOneWidget);
      expect(find.textContaining('Mixed content'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('empty state remains scrollable with large text in landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.library_books,
            title: 'Your library',
            message: 'Save a title to start reading.',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
  for (final screen in ['home', 'settings', 'browse']) {
    testWidgets('$screen supports a narrow screen and large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final state = AppState(
        DreamDatabase(NativeDatabase.memory()),
        await SharedPreferences.getInstance(),
        engine: OfflineEngine(),
      );
      addTearDown(state.dispose);
      final child = switch (screen) {
        'home' => HomeScreen(
          state,
          onBrowse: () {},
          onDownloads: () {},
          onLibrary: () {},
        ),
        'settings' => SettingsScreen(state),
        _ => BrowseScreen(state),
      };
      await tester.pumpWidget(
        MaterialApp(
          theme: dreamTheme(Appearance.pureLight),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(body: child),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (screen == 'browse') {
        await tester.ensureVisible(find.text('Catalogue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Catalogue'));
      } else {
        await tester.drag(
          find.byType(screen == 'home' ? CustomScrollView : ListView).first,
          const Offset(0, -1000),
        );
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
