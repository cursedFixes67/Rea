import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

enum Tracker { anilist, myAnimeList }

extension TrackerLabel on Tracker {
  String get label => this == Tracker.anilist ? 'AniList' : 'MyAnimeList';
}

abstract interface class TrackerSecrets {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class DeviceTrackerSecrets implements TrackerSecrets {
  final storage = const FlutterSecureStorage();
  @override
  Future<String?> read(String key) => storage.read(key: key);
  @override
  Future<void> write(String key, String? value) => value == null
      ? storage.delete(key: key)
      : storage.write(key: key, value: value);
}

typedef TrackerBrowser = Future<String> Function(String url);

/// Public client IDs belong to this app's operator. Credentials never enter backups.
class TrackingService {
  static const redirect = 'com.dreamreader.app.auth://oauth';
  final SharedPreferences preferences;
  final TrackerSecrets secrets;
  final Dio http;
  final TrackerBrowser browser;
  TrackingService(
    this.preferences, {
    TrackerSecrets? secrets,
    Dio? http,
    TrackerBrowser? browser,
  }) : secrets = secrets ?? DeviceTrackerSecrets(),
       http =
           http ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 30),
               sendTimeout: const Duration(seconds: 20),
             ),
           ),
       browser =
           browser ??
           ((url) => FlutterWebAuth2.authenticate(
             url: url,
             callbackUrlScheme: 'com.dreamreader.app.auth',
           ));
  String clientId(Tracker tracker) =>
      preferences.getString('tracking.client.${tracker.name}') ??
      (tracker == Tracker.anilist
          ? const String.fromEnvironment('ANILIST_CLIENT_ID')
          : const String.fromEnvironment('MAL_CLIENT_ID'));
  String _key(Tracker tracker) => 'tracking.auth.${tracker.name}';
  String _random() {
    final random = Random.secure();
    return base64Url
        .encode(List.generate(48, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  Future<Json?> _credentials(Tracker tracker) async {
    final raw = await secrets.read(_key(tracker));
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic> ||
          value['access_token'] is! String ||
          value['expires_at'] is! num ||
          value['client_id'] is! String) {
        return null;
      }
      return value;
    } on FormatException {
      return null;
    }
  }

  Future<bool> connected(Tracker tracker) async =>
      await _credentials(tracker) != null;
  Future<void> disconnect(Tracker tracker) =>
      secrets.write(_key(tracker), null);
  Future<void> connect(Tracker tracker) async {
    final client = clientId(tracker).trim();
    if (client.isEmpty) {
      throw StateError('A registered ${tracker.label} client ID is required.');
    }
    final state = _random(), verifier = _random();
    final authorize = Uri.https(
      tracker == Tracker.anilist ? 'anilist.co' : 'myanimelist.net',
      tracker == Tracker.anilist
          ? '/api/v2/oauth/authorize'
          : '/v1/oauth2/authorize',
      {
        'client_id': client,
        'redirect_uri': redirect,
        'state': state,
        'response_type': tracker == Tracker.anilist ? 'token' : 'code',
        if (tracker == Tracker.myAnimeList) ...{
          'code_challenge': verifier,
          'code_challenge_method': 'plain',
        },
      },
    );
    final callback = Uri.parse(await browser(authorize.toString()));
    if (callback.scheme != 'com.dreamreader.app.auth' ||
        callback.host != 'oauth' ||
        callback.path.isNotEmpty) {
      throw const FormatException('Unexpected authorization callback.');
    }
    final values = tracker == Tracker.anilist
        ? Uri.splitQueryString(callback.fragment)
        : callback.queryParameters;
    if (values['state'] != state) {
      throw const FormatException(
        'Authorization state did not match. Please sign in again.',
      );
    }
    if (values.containsKey('error')) {
      throw StateError('Authorization was declined.');
    }
    Json token;
    if (tracker == Tracker.anilist) {
      token = Map<String, dynamic>.from(values);
    } else {
      final code = values['code'];
      if (code == null || code.isEmpty) {
        throw const FormatException('Authorization did not return a code.');
      }
      token = await _exchange({
        'client_id': client,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirect,
        'code_verifier': verifier,
      });
    }
    await _save(tracker, token, client);
  }

  Future<Json> _exchange(Json form) async {
    try {
      final result = await http.post(
        'https://myanimelist.net/v1/oauth2/token',
        data: form,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return Map<String, dynamic>.from(result.data);
    } on DioException catch (e) {
      throw StateError(
        'MyAnimeList authorization failed (${e.response?.statusCode ?? 'network unavailable'}).',
      );
    }
  }

  Future<void> _save(Tracker tracker, Json token, String client) async {
    final access = token['access_token'];
    if (access is! String || access.isEmpty) {
      throw const FormatException('Authorization returned no access token.');
    }
    final seconds =
        int.tryParse('${token['expires_in']}') ??
        (tracker == Tracker.anilist ? 31536000 : 0);
    if (seconds <= 0) {
      throw const FormatException('Authorization returned an invalid expiry.');
    }
    await secrets.write(
      _key(tracker),
      jsonEncode({
        'access_token': access,
        'refresh_token': token['refresh_token'],
        'client_id': client,
        'expires_at': DateTime.now().millisecondsSinceEpoch + seconds * 1000,
      }),
    );
  }

  Future<String> _token(Tracker tracker) async {
    var credentials = await _credentials(tracker);
    if (credentials == null) {
      throw StateError('Connect ${tracker.label} in Settings first.');
    }
    if ((credentials['expires_at'] as num) <=
        DateTime.now().millisecondsSinceEpoch + 30000) {
      final refresh = credentials['refresh_token'];
      if (tracker != Tracker.myAnimeList ||
          refresh is! String ||
          refresh.isEmpty) {
        throw StateError(
          '${tracker.label} authorization expired. Reconnect in Settings.',
        );
      }
      final result = await _exchange({
        'client_id': credentials['client_id'],
        'grant_type': 'refresh_token',
        'refresh_token': refresh,
      });
      result['refresh_token'] ??= refresh;
      await _save(tracker, result, '${credentials['client_id']}');
      credentials = (await _credentials(tracker))!;
    }
    return credentials['access_token'] as String;
  }

  Future<dynamic> _request(
    Tracker tracker,
    String path, {
    String method = 'GET',
    Json? data,
    Json? query,
  }) async {
    final token = await _token(tracker);
    try {
      final response = await http.request(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $token'},
          contentType: tracker == Tracker.myAnimeList
              ? Headers.formUrlEncodedContentType
              : Headers.jsonContentType,
        ),
      );
      final value = response.data;
      if (value is Map && value['errors'] != null) {
        throw StateError(
          '${tracker.label} rejected the request. Please retry or reconnect.',
        );
      }
      return value;
    } on DioException catch (e) {
      throw StateError(
        '${tracker.label} request failed (${e.response?.statusCode ?? 'network unavailable'}). Local reading progress is preserved.',
      );
    }
  }

  Future<Json> _graph(String query, Json variables) async =>
      Map<String, dynamic>.from(
        (await _request(
          Tracker.anilist,
          'https://graphql.anilist.co',
          method: 'POST',
          data: {'query': query, 'variables': variables},
        ))['data'],
      );
  Future<List<Json>> search(Tracker tracker, String query) async {
    if (query.trim().isEmpty) return [];
    if (tracker == Tracker.anilist) {
      final data = await _graph(
        r'query($search: String!) { Page(perPage: 20) { media(search: $search, type: MANGA) { id title { userPreferred } coverImage { medium } chapters } } }',
        {'search': query.trim()},
      );
      return (data['Page']['media'] as List)
          .map(
            (m) => <String, dynamic>{
              'id': m['id'],
              'title': m['title']['userPreferred'],
              'cover': m['coverImage']['medium'],
              'chapters': m['chapters'],
            },
          )
          .toList();
    }
    final data = await _request(
      tracker,
      'https://api.myanimelist.net/v2/manga',
      query: {'q': query.trim(), 'limit': 20, 'fields': 'num_chapters'},
    );
    return (data['data'] as List).map((m) {
      final node = m['node'];
      return <String, dynamic>{
        'id': node['id'],
        'title': node['title'],
        'cover': node['main_picture']?['medium'] ?? '',
        'chapters': node['num_chapters'],
      };
    }).toList();
  }

  Json _allLinks() {
    try {
      final value = jsonDecode(preferences.getString('tracking.links') ?? '{}');
      if (value is! Map<String, dynamic>) return {};
      return {
        for (final item in value.entries)
          if (item.value is Map)
            item.key: {
              for (final tracker in Tracker.values)
                if (item.value[tracker.name] is Map &&
                    item.value[tracker.name]['id'] is int &&
                    item.value[tracker.name]['id'] > 0 &&
                    item.value[tracker.name]['title'] is String)
                  tracker.name: item.value[tracker.name],
            },
      };
    } on FormatException {
      return {};
    }
  }

  Json links(String mangaKey) {
    final all = _allLinks();
    return Map<String, dynamic>.from(all[mangaKey] ?? {});
  }

  Future<void> link(String mangaKey, Tracker tracker, Json? entry) async {
    final all = _allLinks();
    final links = Map<String, dynamic>.from(all[mangaKey] ?? {});
    if (entry == null) {
      links.remove(tracker.name);
    } else {
      links[tracker.name] = {'id': entry['id'], 'title': entry['title']};
    }
    if (links.isEmpty) {
      all.remove(mangaKey);
    } else {
      all[mangaKey] = links;
    }
    await preferences.setString('tracking.links', jsonEncode(all));
  }

  /// Explicit user action; read remote progress first and never move it backwards.
  Future<int> sync(
    String mangaKey,
    Tracker tracker,
    int completedChapters,
  ) async {
    final entry = links(mangaKey)[tracker.name];
    if (entry == null) {
      throw StateError('Link this title to ${tracker.label} first.');
    }
    final id = entry['id'] as int;
    int remote;
    if (tracker == Tracker.anilist) {
      final data = await _graph(
        r'query($id: Int!) { Media(id: $id, type: MANGA) { mediaListEntry { progress } } }',
        {'id': id},
      );
      remote = data['Media']['mediaListEntry']?['progress'] as int? ?? 0;
    } else {
      final data = await _request(
        tracker,
        'https://api.myanimelist.net/v2/manga/$id',
        query: {'fields': 'my_list_status'},
      );
      remote = data['my_list_status']?['num_chapters_read'] as int? ?? 0;
    }
    final progress = max(remote, completedChapters.clamp(0, 1000000));
    if (tracker == Tracker.anilist) {
      await _graph(
        r'mutation($id: Int!, $progress: Int!) { SaveMediaListEntry(mediaId: $id, progress: $progress) { id progress } }',
        {'id': id, 'progress': progress},
      );
    } else {
      await _request(
        tracker,
        'https://api.myanimelist.net/v2/manga/$id/my_list_status',
        method: 'PUT',
        data: {'num_chapters_read': progress},
      );
    }
    return progress;
  }
}
