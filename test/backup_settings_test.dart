import 'package:flutter_test/flutter_test.dart';
import 'package:dream_reader/data/backup.dart';

void main() {
  final empty = <String, dynamic>{
    'version': 1,
    'library': [],
    'chapters': [],
    'repositories': [],
  };
  test(
    'valid checksum does not allow wrongly typed settings to reach restore',
    () {
      final bytes = BackupCodec.encode({
        ...empty,
        'settings': {'readerMode': 42},
      });
      expect(() => BackupCodec.decode(bytes), throwsFormatException);
    },
  );
  test('rejects malformed bookmark values and duplicate Home sections', () {
    for (final settings in [
      {'bookmarks': '{"story::chapter":"last-page"}'},
      {'bookmarks': '{"story::chapter":-1}'},
      {
        'homeOrder': ['continue', 'continue'],
      },
    ]) {
      expect(
        () => BackupCodec.decode(
          BackupCodec.encode({...empty, 'settings': settings}),
        ),
        throwsFormatException,
      );
    }
  });
  test('preserves valid settings and bookmarks in a verified backup', () {
    final settings = {
      'readerMode': 'rtl',
      'wifiOnly': true,
      'appearance': 1,
      'accent': 0xffa8e6cf,
      'homeOrder': ['continue', 'recent'],
      'bookmarks': '{"story::chapter":12}',
    };
    expect(
      BackupCodec.decode(
        BackupCodec.encode({...empty, 'settings': settings}),
      )['settings'],
      settings,
    );
  });
}
