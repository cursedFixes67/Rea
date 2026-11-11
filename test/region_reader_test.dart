import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dream_reader/domain/models.dart';
import 'package:dream_reader/platform/engine.dart';
import 'package:dream_reader/ui/local_reader_image.dart';

class RegionEngine extends SourceEngine {
  final Uint8List bytes;
  final requested = <int>[];
  RegionEngine(this.bytes);
  @override
  Future<dynamic> call(String method, [Json args = const {}]) async {
    if (method == 'readerImageInfo') {
      return {
        'tiled': true,
        'width': 1000,
        'height': 100000,
        'regionHeight': 2000,
        'count': 50,
      };
    }
    if (method == 'readerImageRegion') {
      requested.add(args['index'] as int);
      return bytes;
    }
    throw StateError('Unexpected call $method');
  }
}

void main() {
  testWidgets('long strips decode visible regions and release old images', (
    tester,
  ) async {
    final bytes = File('test/fixtures/reader-test-page.png').readAsBytesSync();
    final engine = RegionEngine(bytes);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    var decoded = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: [
              LocalReaderImage(
                path: '/private/reader/page.image',
                engine: engine,
                onDecoded: () => decoded++,
                errorBuilder: (error) => Text('Unexpected error: $error'),
              ),
            ],
          ),
        ),
      ),
    );
    Future<void> settleImages() async {
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
    }

    await settleImages();
    expect(engine.requested, isNotEmpty);
    expect(engine.requested.every((index) => index < 4), isTrue);
    expect(
      decoded,
      0,
      reason: 'first region must not complete the whole strip',
    );
    expect(
      tester.widgetList<Image>(find.byType(Image)).length,
      lessThanOrEqualTo(4),
    );
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await settleImages();
    expect(engine.requested, contains(49));
    expect(decoded, greaterThan(0));
    expect(
      tester.widgetList<Image>(find.byType(Image)).length,
      lessThanOrEqualTo(4),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
