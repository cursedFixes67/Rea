import 'package:flutter_test/flutter_test.dart';
import 'package:dream_reader/domain/models.dart';

void main() {
  test(
    'native source memo and identity survive storage and platform round trips',
    () {
      final manga = Manga.fromJson({
        'sourceId': '9223372036854775806',
        'url': '/title',
        'title': 'Story',
        'artist': 'Artist',
        'memo': {
          'source.token': {'id': '01', 'flag': true},
        },
        'initialized': true,
        'updateStrategy': 'ONLY_FETCH_ONCE',
      });
      final decoded = Manga.fromJson(manga.toJson());
      expect(decoded.memo, manga.memo);
      expect(decoded.sourceId, manga.sourceId);
      expect(decoded.artist, 'Artist');
      expect(decoded.initialized, isTrue);
      expect(decoded.updateStrategy, 'ONLY_FETCH_ONCE');
      final chapter = Chapter.fromJson({
        'url': '/c',
        'name': 'Chapter',
        'number': 3.5,
        'date': 12345,
        'scanlator': 'Group',
        'memo': {'source.page-id': '0007'},
      });
      final copy = Chapter.fromJson(chapter.toJson());
      expect(copy.memo, chapter.memo);
      expect(copy.scanlator, 'Group');
      expect(copy.number, 3.5);
    },
  );
}
