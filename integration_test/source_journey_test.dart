import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/main.dart';
import 'package:dream_reader/data/app_state.dart';
import 'package:dream_reader/data/database.dart';
import 'package:dream_reader/data/backup.dart';
import 'package:dream_reader/data/repositories.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/ui/reader.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'live repository, verified extension, chapters, reader, download and backup',
    (tester) async {
      final preferences = await SharedPreferences.getInstance();
      final database = DreamDatabase();
      final state = AppState(database, preferences);
      await state.initialize();
      await tester.pumpWidget(DreamReader(state: state));
      // Local startup intentionally renders before third-party discovery.
      await tester.runAsync(state.refreshSources);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await state.finishOnboarding(true);
        expect(state.syncError, isNull);
        expect(state.catalogue.length, greaterThan(100));
        final entry = state.catalogue.firstWhere(
          (e) => e.packageName == 'eu.kanade.tachiyomi.extension.all.mangadex',
        );
        expect(entry.signer, RepositoryService.defaultFingerprint);
        await expectLater(
          state.engine.call('install', {
            'extension': entry.toJson(),
            'consent': false,
          }),
          throwsA(isA<PlatformException>()),
        );
        final wrongSigner = entry.toJson()..['signer'] = '00' * 32;
        await expectLater(
          state.engine.call('install', {
            'extension': wrongSigner,
            'consent': true,
          }),
          throwsA(isA<PlatformException>()),
        );
        await state.install(entry);
        expect(state.sourceErrors, isEmpty);
        final source = state.sources.firstWhere(
          (s) => s['language'] == 'en' && s['packageName'] == entry.packageName,
        );
        final result = await state.engine.browse(
          '${source['id']}',
          query: 'Yotsuba',
        );
        expect(result['items'], isNotEmpty);
        final manga = Manga.fromJson(
          Map<String, dynamic>.from((result['items'] as List).first),
        );
        final details = await state.engine.details(manga);
        final full = Manga.fromJson(
          Map<String, dynamic>.from(details['manga']),
        );
        final chapters = (details['chapters'] as List)
            .map((c) => Chapter.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        expect(chapters, isNotEmpty);
        await database.addManga(full);
        await database.saveChapters(full.key, chapters);
        final chapter = chapters.last;
        final pages = await state.engine.pages(full, chapter);
        expect(pages, isNotEmpty);
        final response = await Dio().get<List<int>>(
          pages.first.url,
          options: Options(
            headers: pages.first.headers,
            responseType: ResponseType.bytes,
          ),
        );
        expect(response.data!.length, greaterThan(100));
        final image = await decodeImageFromList(
          Uint8List.fromList(response.data!),
        );
        expect(image.width, greaterThan(0));
        image.dispose();
        await database.progress(full.key, chapter.url, 0, pages.length);
        final download = await state.engine.call('downloadEnqueue', {
          'key': '${full.key}::${chapter.url}',
          'title': full.title,
          'chapterName': chapter.name,
          'wifiOnly': false,
          'pages': pages.map((p) => p.toJson()).toList(),
        });
        final deadline = DateTime.now().add(const Duration(minutes: 3));
        bool complete = false;
        while (DateTime.now().isBefore(deadline)) {
          final jobs = await state.engine.call('downloadList') as List;
          final job = jobs.cast<Map>().firstWhere(
            (j) => j['id'] == download['id'],
          );
          if (job['status'] == 'FAILED') {
            fail('Download failed: ${job['error']}');
          }
          if (job['status'] == 'SUCCEEDED') {
            complete = true;
            break;
          }
          await Future<void>.delayed(const Duration(seconds: 2));
        }
        expect(complete, isTrue, reason: 'Chapter download did not finish');
        final local = await state.engine.call('downloadPages', {
          'key': '${full.key}::${chapter.url}',
        }) as List;
        expect(local.length, pages.length);
        expect(await File(local.first['url']).exists(), isTrue);
        final backup = BackupCodec.decode(
          BackupCodec.encode(await database.backup()),
        );
        await database.restore(backup);
        expect(
          (await database.select(database.libraryEntries).get())
              .where((r) => r.key == full.key)
              .length,
          1,
        );
        // Retain only synthetic/local test progress; downloaded files exercise the real worker.
        await preferences.setString(
          'integrationEvidence',
          jsonEncode({
            'source': source['id'],
            'extensionVersion': entry.version,
            'chapters': chapters.length,
            'pages': pages.length,
          }),
        );
      });
      await tester.pumpAndSettle();
      for (final label in [
        'Library',
        'Browse',
        'Updates',
        'Downloads',
        'Home',
      ]) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      final library = await database.select(database.libraryEntries).get();
      final manga = Manga.fromJson(jsonDecode(library.last.payload));
      final chapters = (await database.chapters(manga.key))
          .map((r) => Chapter.fromJson(jsonDecode(r.payload)))
          .toList();
      await tester.pumpWidget(
        MaterialApp(home: ReaderScreen(state, manga, chapters, chapters.last)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(ReaderScreen), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
