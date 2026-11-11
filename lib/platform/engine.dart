import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';

class SourceEngine {
  static const channel = MethodChannel('com.dreamreader.app/engine');
  bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<dynamic> call(String method, [Json args = const {}]) async {
    if (!available) {
      throw StateError(
        'Source extensions run on Android. Install the Android build to use this source.',
      );
    }
    return channel.invokeMethod(method, args);
  }

  Future<Json> sources() async =>
      Map<String, dynamic>.from(await call('sources'));
  Future<void> install(ExtensionEntry extension) async =>
      call('install', {'extension': extension.toJson(), 'consent': true});
  Future<void> uninstall(String package) async =>
      call('uninstall', {'packageName': package});
  Future<Json> browse(
    String id, {
    int page = 1,
    String query = '',
    String mode = 'popular',
    Json filters = const {},
  }) async => Map<String, dynamic>.from(
    await call('browse', {
      'sourceId': id,
      'page': page,
      'query': query,
      'mode': query.isNotEmpty || filters.isNotEmpty ? 'search' : mode,
      'filters': filters,
    }),
  );
  Future<Json> details(Manga manga) async => Map<String, dynamic>.from(
    await call('details', {
      'sourceId': manga.sourceId,
      'manga': manga.toJson(),
    }),
  );
  Future<List<ReaderPage>> pages(Manga manga, Chapter chapter) async =>
      (await call('pages', {
            'sourceId': manga.sourceId,
            'chapter': chapter.toJson(),
          }) as List)
          .map((p) => ReaderPage.fromJson(Map<String, dynamic>.from(p)))
          .toList();
}
