import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class BackupCodec {
  static Uint8List encode(Map<String, dynamic> payload) {
    final data = jsonEncode(payload);
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'dream-reader-backup',
          'version': 1,
          'sha256': sha256.convert(utf8.encode(data)).toString(),
          'payload': data,
        }),
      ),
    );
  }

  static Map<String, dynamic> decode(Uint8List bytes) {
    if (bytes.length > 64 * 1024 * 1024) {
      throw const FormatException('Backup exceeds 64 MiB');
    }
    final envelope = jsonDecode(utf8.decode(bytes));
    if (envelope is! Map ||
        envelope['format'] != 'dream-reader-backup' ||
        envelope['version'] != 1 ||
        envelope['payload'] is! String) {
      throw const FormatException('Not a supported Dream Reader backup');
    }
    final data = envelope['payload'] as String;
    if (sha256.convert(utf8.encode(data)).toString() != envelope['sha256']) {
      throw const FormatException('Backup integrity check failed');
    }
    final payload = jsonDecode(data);
    if (payload is! Map<String, dynamic> ||
        payload['version'] != 1 ||
        payload['library'] is! List ||
        payload['chapters'] is! List ||
        payload['repositories'] is! List) {
      throw const FormatException('Backup contents are incomplete');
    }
    return payload;
  }
}
