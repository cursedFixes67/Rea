import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import '../platform/engine.dart';
import '../ui/theme.dart';
import 'database.dart';
import 'repositories.dart';
import 'tracking.dart';

class AppState extends ChangeNotifier {
  final DreamDatabase db;
  final SharedPreferences preferences;
  final SourceEngine engine;
  final RepositoryService repositories;
  late final tracking = TrackingService(preferences);
  List<LibraryEntry> _library = [];
  List<Manga> _mangaLibrary = [];
  Map<String, Manga> _mangaByKey = {};
  List<LibraryEntry> get library => _library;
  Map<String, Manga> get mangaByKey => _mangaByKey;
  set library(List<LibraryEntry> entries) {
    // Decode once per database emission, not on each progress/theme rebuild.
    final decoded = entries
        .map((r) => Manga.fromJson(jsonDecode(r.payload)))
        .toList();
    _library = List.unmodifiable(entries);
    _mangaLibrary = List.unmodifiable(decoded);
    _mangaByKey = Map.unmodifiable({
      for (final manga in decoded) manga.key: manga,
    });
  }

  int get unreadChapterCount => library.fold<int>(0, (sum, entry) {
    final stats = chapterStats[entry.key];
    return sum +
        ((stats?['total'] as int? ?? 0) - (stats?['completed'] as int? ?? 0))
            .clamp(0, 1 << 30);
  });
  List<ExtensionEntry> catalogue = [];
  List<Json> sources = [], sourceErrors = [];
  Json installed = {};
  List<RepositoryEntry> repositoryList = [];
  StreamSubscription<List<LibraryEntry>>? _librarySubscription;
  Map<String, Json> chapterStats = {};
  StreamSubscription<Map<String, Json>>? _chapterSubscription;
  bool syncing = false;
  Object? syncError;
  Appearance appearance;
  AppState(
    this.db,
    this.preferences, {
    SourceEngine? engine,
    RepositoryService? repositories,
  }) : engine = engine ?? SourceEngine(),
       repositories = repositories ?? RepositoryService(),
       appearance =
           Appearance.values[(preferences.getInt('appearance') ?? 0).clamp(
             0,
             Appearance.values.length - 1,
           )];
  bool get onboardingDone => preferences.getBool('onboarding') ?? false;
  Color get accent =>
      Color(preferences.getInt('accent') ?? dreamMint.toARGB32());
  String get interfaceFont =>
      preferences.getString('interfaceFont') ?? 'Manrope';
  int get interfaceDensity =>
      (preferences.getInt('interfaceDensity') ?? 0).clamp(-1, 1);
  Future<void> setTypography(String font, int density) async {
    if (!{'Manrope', 'Newsreader', 'system'}.contains(font) ||
        density < -1 ||
        density > 1) {
      throw ArgumentError('Unsupported typography');
    }
    await preferences.setString('interfaceFont', font);
    await preferences.setInt('interfaceDensity', density);
    notifyListeners();
  }

  List<Manga> get mangaLibrary => _mangaLibrary;
  bool hasManga(Manga manga) => _mangaByKey.containsKey(manga.key);
  Future<void> initialize() async {
    _chapterSubscription = db.watchChapterStats().listen((value) {
      chapterStats = value;
      notifyListeners();
    });
    _librarySubscription = db.watchLibrary().listen((value) {
      library = value;
      notifyListeners();
    });
    await loadRepositories();
    if (engine.available) {
      try {
        await refreshSources();
      } catch (error) {
        sourceErrors = [
          {'message': '$error'},
        ];
      }
    }
  }

  Future<void> finishOnboarding(bool enableRepository) async {
    if (enableRepository) {
      await db
          .into(db.repositoryEntries)
          .insertOnConflictUpdate(
            RepositoryEntriesCompanion.insert(
              url: RepositoryService.defaultUrl,
              name: 'Keiyoushi',
              signer: RepositoryService.defaultFingerprint,
            ),
          );
    }
    await preferences.setBool('onboarding', true);
    await loadRepositories();
    notifyListeners();
    if (enableRepository) await syncRepositories();
  }

  Future<void> setAppearance(Appearance value) async {
    appearance = value;
    await preferences.setInt('appearance', value.index);
    notifyListeners();
  }

  Future<void> setAccent(Color value) async {
    await preferences.setInt('accent', value.toARGB32());
    notifyListeners();
  }

  Future<void> setDownloadConcurrency(int value) async {
    if (value < 1 || value > 6) throw ArgumentError.value(value, 'value');
    await preferences.setInt('downloadConcurrency', value);
    if (engine.available) await engine.call('downloadConfigure');
    notifyListeners();
  }

  Future<void> loadRepositories() async {
    repositoryList = await db.select(db.repositoryEntries).get();
    catalogue = repositoryList
        .where((r) => r.enabled)
        .expand(
          (r) => (jsonDecode(r.catalogue) as List).map(
            (e) => ExtensionEntry.fromJson(Map<String, dynamic>.from(e)),
          ),
        )
        .toList();
    notifyListeners();
  }

  Future<void> syncRepositories() async {
    if (syncing) return;
    syncing = true;
    syncError = null;
    notifyListeners();
    final failures = <String>[];
    try {
      for (final repository in repositoryList.where((r) => r.enabled)) {
        try {
          final snapshot = await repositories.sync(repository.url);
          if (snapshot.signer != repository.signer) {
            throw StateError(
              'Repository signing key changed. Review the repository before trusting a new key.',
            );
          }
          await (db.update(
            db.repositoryEntries,
          )..where((r) => r.url.equals(repository.url))).write(
            RepositoryEntriesCompanion(
              name: Value(snapshot.name),
              catalogue: Value(
                jsonEncode(snapshot.extensions.map((e) => e.toJson()).toList()),
              ),
              syncedAt: Value(DateTime.now()),
            ),
          );
        } catch (error) {
          failures.add('${repository.name}: $error');
        }
      }
      await loadRepositories();
      if (failures.isNotEmpty) syncError = failures.join('\n');
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<RepositorySnapshot> inspectRepository(String url) =>
      repositories.sync(url);
  Future<void> addRepository(String url, RepositorySnapshot snapshot) async {
    await db
        .into(db.repositoryEntries)
        .insertOnConflictUpdate(
          RepositoryEntriesCompanion.insert(
            url: url,
            name: snapshot.name,
            signer: snapshot.signer,
            catalogue: Value(
              jsonEncode(snapshot.extensions.map((e) => e.toJson()).toList()),
            ),
            syncedAt: Value(DateTime.now()),
          ),
        );
    await loadRepositories();
  }

  Future<void> refreshSources() async {
    final result = await engine.sources();
    sources = (result['sources'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    sourceErrors = (result['errors'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    installed = Map<String, dynamic>.from(result['installed']);
    notifyListeners();
  }

  Future<void> install(ExtensionEntry entry) async {
    await engine.install(entry);
    await refreshSources();
  }

  Future<void> toggleLibrary(Manga manga) async {
    if (hasManga(manga)) {
      await db.removeManga(manga.key);
    } else {
      await db.addManga(manga);
    }
  }

  @override
  void dispose() {
    _librarySubscription?.cancel();
    _chapterSubscription?.cancel();
    db.close();
    super.dispose();
  }
}
