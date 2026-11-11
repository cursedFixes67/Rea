// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:dream_reader/data/repositories.dart';
Future<void> main() async {
  final snapshot = await RepositoryService().sync(RepositoryService.defaultUrl);
  final matches = snapshot.extensions.where((e) => RegExp(r'mangadex|manga plus|webtoon|comicbookplus', caseSensitive: false).hasMatch(e.name)).toList();
  print('${snapshot.name}: ${snapshot.extensions.length} extensions; signer ${snapshot.signer}');
  for (final item in matches) { print(jsonEncode(item.toJson())); }
  File('/tmp/dream-current-catalogue.json').writeAsStringSync(jsonEncode(snapshot.extensions.map((e) => e.toJson()).toList()));
}
