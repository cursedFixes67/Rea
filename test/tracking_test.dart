import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_reader/data/tracking.dart';

class MemorySecrets implements TrackerSecrets {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

class FixtureAdapter implements HttpClientAdapter {
  final Future<Map<String, dynamic>> Function(RequestOptions) respond;
  FixtureAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        [],
        (all, chunk) => all..addAll(chunk),
      );
      options.data = utf8.decode(bytes);
    }
    return ResponseBody.fromString(
      jsonEncode(await respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'tracking.client.anilist': 'synthetic-client',
      'tracking.client.myAnimeList': 'synthetic-mal-client',
    });
    preferences = await SharedPreferences.getInstance();
  });
  test('rejects unsolicited OAuth state before retaining credentials', () async {
    final secrets = MemorySecrets();
    final service = TrackingService(
      preferences,
      secrets: secrets,
      browser: (_) async =>
          '${TrackingService.redirect}#access_token=synthetic&state=wrong&expires_in=3600',
    );
    await expectLater(service.connect(Tracker.anilist), throwsFormatException);
    expect(secrets.values, isEmpty);
  });
  test('MAL public-client flow uses PKCE and keeps credentials out of preferences', () async {
    final secrets = MemorySecrets();
    String? challenge;
    final http = Dio()
      ..httpClientAdapter = FixtureAdapter((request) async {
        expect(
          request.uri.toString(),
          'https://myanimelist.net/v1/oauth2/token',
        );
        final body = Uri.splitQueryString(request.data as String);
        expect(body['code_verifier'], challenge);
        expect(body['code'], 'synthetic-code');
        expect(body['client_secret'], isNull);
        return {
          'access_token': 'synthetic-access',
          'refresh_token': 'synthetic-refresh',
          'expires_in': 3600,
        };
      });
    final service = TrackingService(
      preferences,
      secrets: secrets,
      http: http,
      browser: (url) async {
        final query = Uri.parse(url).queryParameters;
        challenge = query['code_challenge'];
        expect(challenge!.length, inInclusiveRange(43, 128));
        expect(query['code_challenge_method'], 'plain');
        return '${TrackingService.redirect}?code=synthetic-code&state=${query['state']}';
      },
    );
    await service.connect(Tracker.myAnimeList);
    expect(await service.connected(Tracker.myAnimeList), isTrue);
    expect(
      preferences.getKeys().every(
        (k) => !'${preferences.get(k)}'.contains('synthetic-access'),
      ),
      isTrue,
    );
    await service.disconnect(Tracker.myAnimeList);
    expect(secrets.values, isEmpty);
  });
  test(
    'refreshes expired MAL token and preserves higher remote chapter progress',
    () async {
      final secrets = MemorySecrets();
      await secrets.write(
        'tracking.auth.myAnimeList',
        jsonEncode({
          'access_token': 'expired',
          'refresh_token': 'synthetic-refresh',
          'client_id': 'synthetic-client',
          'expires_at': 1,
        }),
      );
      final calls = <String>[];
      final http = Dio()
        ..httpClientAdapter = FixtureAdapter((request) async {
          calls.add(request.method);
          if (request.path.endsWith('/token')) {
            expect(
              Uri.splitQueryString(request.data as String)['grant_type'],
              'refresh_token',
            );
            return {'access_token': 'fresh-synthetic', 'expires_in': 3600};
          }
          expect(request.headers['Authorization'], 'Bearer fresh-synthetic');
          if (request.method == 'GET') {
            return {
              'my_list_status': {'num_chapters_read': 12, 'score': 9},
            };
          }
          expect(request.method, 'PUT');
          expect(Uri.splitQueryString(request.data as String), {
            'num_chapters_read': '12',
          });
          return {'num_chapters_read': 12};
        });
      final service = TrackingService(
        preferences,
        secrets: secrets,
        http: http,
      );
      await service.link('1::/story', Tracker.myAnimeList, {
        'id': 123,
        'title': 'Synthetic story',
      });
      expect(await service.sync('1::/story', Tracker.myAnimeList, 8), 12);
      expect(calls, ['POST', 'GET', 'PUT']);
      expect(
        jsonDecode(
          secrets.values['tracking.auth.myAnimeList']!,
        )['refresh_token'],
        'synthetic-refresh',
      );
    },
  );
  test(
    'invalid imported tracking links cannot crash the title screen',
    () async {
      final service = TrackingService(preferences, secrets: MemorySecrets());
      await preferences.setString(
        'tracking.links',
        '{"story":{"anilist":{"id":"bad","title":3}}}',
      );
      expect(service.links('story'), isEmpty);
      await preferences.setString('tracking.links', 'not json');
      expect(service.links('story'), isEmpty);
    },
  );
}
