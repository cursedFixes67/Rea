import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

import '../domain/models.dart';

/// Bounded protobuf reader. Unknown fields survive parsing by field number.
class ProtoMessage {
  final Map<int, List<Object>> fields = {};
  ProtoMessage(Uint8List bytes) {
    var offset = 0;
    BigInt varint() {
      var value = BigInt.zero;
      for (var shift = 0; shift < 70; shift += 7) {
        if (offset >= bytes.length) {
          throw const FormatException('Truncated protobuf');
        }
        final b = bytes[offset++];
        value |= BigInt.from(b & 127) << shift;
        if (b < 128) return value;
      }
      throw const FormatException('Invalid protobuf integer');
    }

    while (offset < bytes.length) {
      final tag = varint().toInt();
      final field = tag >> 3;
      if (field == 0) throw const FormatException('Invalid protobuf field');
      Object value;
      switch (tag & 7) {
        case 0:
          value = varint();
        case 1:
        case 5:
          final length = (tag & 7) == 1 ? 8 : 4;
          if (offset + length > bytes.length) {
            throw const FormatException('Truncated fixed field');
          }
          value = Uint8List.sublistView(bytes, offset, offset + length);
          offset += length;
        case 2:
          final length = varint().toInt();
          if (length < 0 || length > bytes.length - offset) {
            throw const FormatException('Invalid field length');
          }
          value = Uint8List.sublistView(bytes, offset, offset + length);
          offset += length;
        default:
          throw const FormatException('Unsupported protobuf wire type');
      }
      fields.putIfAbsent(field, () => []).add(value);
    }
  }
  String text(int field) {
    final v = fields[field]?.first;
    return v is Uint8List ? utf8.decode(v) : '';
  }

  int number(int field) => fields[field]?.first is BigInt
      ? (fields[field]!.first as BigInt).toInt()
      : 0;
  String integerText(int field) =>
      fields[field]?.first is BigInt ? fields[field]!.first.toString() : '0';
  List<ProtoMessage> messages(int field) => (fields[field] ?? [])
      .whereType<Uint8List>()
      .map(ProtoMessage.new)
      .toList();
  ProtoMessage child(int field) =>
      messages(field).firstOrNull ?? ProtoMessage(Uint8List(0));
}

class RepositorySnapshot {
  final String name, signer, listUrl;
  final List<ExtensionEntry> extensions;
  const RepositorySnapshot(
    this.name,
    this.signer,
    this.extensions, {
    this.listUrl = '',
  });
}

class RepositoryService {
  static const defaultUrl =
      'https://github.com/keiyoushi/extensions/raw/repo/index.pb';
  static const defaultFingerprint =
      '9add655a78e96c4ec7a53ef89dccb557cb5d767489fac5e785d671a5a75d4da2';
  final Dio http;
  RepositoryService({Dio? http})
    : http =
          http ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 40),
            ),
          );

  static Uri secureUri(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const FormatException('Repository URLs must use HTTPS');
    }
    return uri;
  }

  Future<Uint8List> _fetch(String url) async {
    secureUri(url);
    final requested = Uri.parse(url);
    final parts = requested.pathSegments;
    final fetchUrl =
        requested.host == 'github.com' && parts.length >= 5 && parts[2] == 'raw'
        ? Uri.https(
            'raw.githubusercontent.com',
            '${parts[0]}/${parts[1]}/${parts.sublist(3).join('/')}',
          ).toString()
        : url;
    final response = await http.get<List<int>>(
      fetchUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.length > 16 * 1024 * 1024) {
      throw const FormatException('Invalid repository size');
    }
    return Uint8List.fromList(bytes);
  }

  Future<RepositorySnapshot> sync(String url, {int depth = 0}) async {
    if (depth > 4) throw const FormatException('Repository redirect loop');
    final bytes = unpack(await _fetch(url));
    final first = bytes.isEmpty ? 0 : bytes.first;
    if (first == 123 || first == 91) {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is Map && json['index_v2'] is String) {
        return sync(json['index_v2'], depth: depth + 1);
      }
      if (json is List) {
        final base = url.replaceFirst(RegExp(r'/index(?:\.min)?\.json$'), '');
        final metaBytes = await _fetch('$base/repo.json');
        final meta = jsonDecode(utf8.decode(metaBytes)) as Map;
        if (meta['index_v2'] is String) {
          return sync(meta['index_v2'], depth: depth + 1);
        }
        final fingerprint = '${meta['meta']?['signingKeyFingerprint'] ?? ''}';
        final entries = json
            .map(
              (e) => ExtensionEntry(
                name: e['name'],
                packageName: e['pkg'],
                apkUrl: '$base/apk/${e['apk']}',
                iconUrl: '$base/icon/${e['pkg']}.png',
                api: '${e['version']}'.split('.').take(2).join('.'),
                version: e['version'],
                code: e['code'],
                repository: url,
                signer: fingerprint,
                contentWarning: e['nsfw'] == 1 ? 3 : 1,
                sources: (e['sources'] as List)
                    .map(
                      (s) => ExtensionSource.fromJson(
                        Map<String, dynamic>.from(s),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
        return RepositorySnapshot(
          '${meta['meta']?['name'] ?? 'Repository'}',
          fingerprint,
          entries,
        );
      }
      throw const FormatException(
        'Unsupported JSON repository. Use its index.pb URL.',
      );
    }
    final snapshot = parse(bytes, url);
    if (snapshot.listUrl.isNotEmpty) {
      final list = ProtoMessage(unpack(await _fetch(snapshot.listUrl)));
      return RepositorySnapshot(
        snapshot.name,
        snapshot.signer,
        parseEntries(list, url, snapshot.signer),
      );
    }
    return snapshot;
  }

  static Uint8List unpack(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 31 && bytes[1] == 139) {
      final decoded = GZipDecoder().decodeBytes(
        bytes,
        verify: true,
        throwOnError: true,
        maxOutputSize: 32 * 1024 * 1024,
      );
      if (decoded.length > 32 * 1024 * 1024) {
        throw const FormatException('Repository is too large');
      }
      return Uint8List.fromList(decoded);
    }
    return bytes;
  }

  static RepositorySnapshot parse(Uint8List bytes, String url) {
    final root = ProtoMessage(unpack(bytes));
    final signer = root.text(3);
    if (root.text(1).isEmpty ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(signer)) {
      throw const FormatException(
        'Repository identity or signing fingerprint is invalid',
      );
    }
    if (!root.fields.containsKey(101) && root.text(102).isEmpty) {
      throw const FormatException('Unsupported repository index version');
    }
    return RepositorySnapshot(
      root.text(1),
      signer.toLowerCase(),
      parseEntries(root.child(101), url, signer.toLowerCase()),
      listUrl: root.text(102),
    );
  }

  static List<ExtensionEntry> parseEntries(
    ProtoMessage list,
    String url,
    String signer,
  ) => list.messages(1).map((e) {
    final resources = e.child(3);
    secureUri(resources.text(1));
    if (resources.text(2).isNotEmpty) secureUri(resources.text(2));
    return ExtensionEntry(
      name: e.text(1),
      packageName: e.text(2),
      apkUrl: resources.text(1),
      iconUrl: resources.text(2),
      api: e.text(4),
      code: e.number(5),
      version: e.text(6),
      contentWarning: e.number(7),
      repository: url,
      signer: signer,
      sources: e
          .messages(8)
          .map(
            (s) => ExtensionSource(
              s.integerText(1),
              s.text(2),
              s.text(3),
              s.text(4),
            ),
          )
          .toList(),
    );
  }).toList();
}
