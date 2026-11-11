import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dream_reader/data/repositories.dart';

void main() {
  test('rejects malformed wire data', () {
    for (final bytes in [
      [0],
      [10, 100, 1],
      [8, 128],
      [15],
    ]) {
      expect(
        () => ProtoMessage(Uint8List.fromList(bytes)),
        throwsFormatException,
      );
    }
  });
  test('rejects insecure repository locations', () {
    for (final url in [
      'http://example.com/index.pb',
      'file:///tmp/index.pb',
      'https://user:pass@example.com/index.pb',
    ]) {
      expect(() => RepositoryService.secureUri(url), throwsFormatException);
    }
  });
  test('reads strings, integers and unknown fixed fields', () {
    final message = ProtoMessage(
      Uint8List.fromList([10, 3, 97, 98, 99, 16, 150, 1, 29, 0, 0, 0, 0]),
    );
    expect(message.text(1), 'abc');
    expect(message.number(2), 150);
  });
  test('current live Keiyoushi fixture has real sources and provenance', () {
    const path = 'test/fixtures/keiyoushi-2026-11-11.pb';
    final snapshot = RepositoryService.parse(
      File(path).readAsBytesSync(),
      RepositoryService.defaultUrl,
    );
    expect(snapshot.name, 'Keiyoushi');
    expect(snapshot.signer, RepositoryService.defaultFingerprint);
    expect(snapshot.extensions.length, greaterThan(100));
    expect(snapshot.extensions.any((e) => e.api == '1.6'), isTrue);
    expect(
      snapshot.extensions.every(
        (e) => e.packageName.isNotEmpty && e.sources.isNotEmpty,
      ),
      isTrue,
    );
  });
}
