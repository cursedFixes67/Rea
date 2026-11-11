import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../domain/models.dart';
import 'repositories.dart';

/// Imports the documented protobuf fields of Mihon Backup at 134e5de3d672968b91ac426fbea0020290972cff.
/// Credentials, extension APKs, source settings and tracker sessions are intentionally not imported.
class MihonBackupImporter {
  static Json decode(Uint8List bytes) {
    if (bytes.length > 64 * 1024 * 1024) {
      throw const FormatException('Backup exceeds 64 MiB');
    }
    final decoded = GZipDecoder().decodeBytes(
      bytes,
      verify: true,
      throwOnError: true,
      maxOutputSize: 64 * 1024 * 1024,
    );
    final backup = ProtoMessage(decoded);
    final categories = {
      for (final category in backup.messages(2))
        category.integerText(3): category.text(1),
    };
    final library = <Json>[], chapters = <Json>[], sessions = <Json>[];
    final bookmarks = <String, int>{};
    var sessionId = 0;
    for (final record in backup.messages(1)) {
      if (record.fields.containsKey(100) && record.number(100) == 0) continue;
      final manga = Manga(
        sourceId: BigInt.parse(record.integerText(1)).toSigned(64).toString(),
        url: record.text(2),
        title: record.text(3),
        artist: record.text(4),
        author: record.text(5),
        description: record.text(6),
        genre: (record.fields[7] ?? [])
            .whereType<Uint8List>()
            .map(utf8.decode)
            .join(', '),
        status: record.number(8),
        cover: record.text(9),
        initialized: record.number(111) == 1,
        updateStrategy: record.number(105) == 1
            ? 'ONLY_FETCH_ONCE'
            : 'ALWAYS_UPDATE',
        memo: _memo(record, 112),
      );
      if (manga.url.isEmpty || manga.title.isEmpty) {
        throw const FormatException(
          'Mihon backup contains a title without an identity',
        );
      }
      final categoryNames = _integers(record, 17)
          .map((id) => categories[id])
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toList();
      library.add({
        'key': manga.key,
        'sourceId': manga.sourceId,
        'title': manga.title,
        'payload': jsonEncode(manga.toJson()),
        'category': categoryNames.isEmpty
            ? 'Uncategorized'
            : categoryNames.join(' / '),
        'addedAt': record.number(13),
      });
      final history = {for (final h in record.messages(104)) h.text(1): h};
      for (final row in record.messages(16)) {
        final number = row.fields[9]?.firstOrNull;
        final chapter = Chapter(
          url: row.text(1),
          name: row.text(2),
          scanlator: row.text(3),
          number: number is Uint8List && number.length == 4
              ? ByteData.sublistView(number).getFloat32(0, Endian.little)
              : -1,
          date: row.number(8),
          memo: _memo(row, 13),
        );
        if (chapter.url.isEmpty) {
          throw const FormatException(
            'Mihon backup contains a chapter without a URL',
          );
        }
        final page = row.number(6).clamp(0, 2147483647);
        final read = row.number(4) == 1;
        final recent = history[chapter.url];
        chapters.add({
          'mangaKey': manga.key,
          'url': chapter.url,
          'payload': jsonEncode(chapter.toJson()),
          'page': page,
          'totalPages': 0,
          'completed': read,
          'lastRead': recent?.number(2),
        });
        if (row.number(5) == 1) {
          bookmarks['${manga.key}::${chapter.url}'] = page;
        }
        if (recent != null && recent.number(3) > 0) {
          sessions.add({
            'id': ++sessionId,
            'mangaKey': manga.key,
            'seconds': recent.number(3) ~/ 1000,
            'createdAt': recent.number(2),
          });
        }
      }
    }
    if (library.isEmpty) {
      throw const FormatException(
        'No compatible library entries found in this Mihon backup',
      );
    }
    return {
      'version': 1,
      'importedFrom': 'Mihon protobuf',
      'library': library,
      'chapters': chapters,
      'repositories': <Json>[],
      'sessions': sessions,
      'settings': {'bookmarks': jsonEncode(bookmarks)},
      'importNotes': 'Library, chapter progress, bookmarks, reading history and categories are imported. Multiple categories become a combined category. Tracking accounts, extension APKs, source preferences and application settings are not imported. Install matching sources separately.',
    };
  }

  static Json _memo(ProtoMessage message, int field) {
    final value = message.text(field);
    if (value.isEmpty) return {};
    final decoded = jsonDecode(value);
    if (decoded is! Json) {
      throw const FormatException('Invalid source metadata in backup');
    }
    return decoded;
  }

  static List<String> _integers(ProtoMessage message, int field) {
    final result = <String>[];
    for (final value in message.fields[field] ?? []) {
      if (value is BigInt) {
        result.add(value.toString());
      }
      if (value is Uint8List) {
        var current = BigInt.zero, shift = 0;
        for (final byte in value) {
          current |= BigInt.from(byte & 127) << shift;
          if (byte < 128) {
            result.add(current.toString());
            current = BigInt.zero;
            shift = 0;
          } else {
            shift += 7;
            if (shift >= 70) {
              throw const FormatException('Invalid packed category');
            }
          }
        }
        if (shift != 0) {
          throw const FormatException('Truncated packed category');
        }
      }
    }
    return result;
  }
}
