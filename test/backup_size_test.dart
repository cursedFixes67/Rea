import 'package:flutter_test/flutter_test.dart';
import 'package:dream_reader/data/backup.dart';

void main() {
  test(
    'export refuses to produce a backup that restore would reject for size',
    () {
      final payload = <String, dynamic>{
        'version': 1,
        'library': [],
        'chapters': [],
        'repositories': [],
        'padding': 'x' * BackupCodec.maxEncodedBytes,
      };
      expect(() => BackupCodec.encode(payload), throwsFormatException);
    },
  );
}
