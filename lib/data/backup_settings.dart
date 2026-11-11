import 'dart:convert';

/// Validate settings before any restore mutation, including the database merge.
class BackupSettings {
  static void validate(dynamic settings) {
    if (settings == null) return;
    if (settings is! Map<String, dynamic>) {
      throw const FormatException('Backup settings must be an object');
    }
    const booleans = {
      'onboarding',
      'wifiOnly',
      'volumeKeys',
      'autoNextChapter',
      'reverseTapZones',
    };
    const integers = {'appearance', 'accent'};
    const lists = {'searchHistory', 'searchSources', 'homeHidden', 'homeOrder'};
    const strings = {
      'readerMode',
      'bookmarks',
      'tracking.links',
      'tracking.client.anilist',
      'tracking.client.myAnimeList',
      'restoredDownloadInventory',
    };
    for (final entry in settings.entries) {
      final key = entry.key, value = entry.value;
      if ((booleans.contains(key) && value is! bool) ||
          (integers.contains(key) && value is! int) ||
          (strings.contains(key) && value is! String) ||
          (lists.contains(key) &&
              (value is! List || value.any((v) => v is! String)))) {
        throw FormatException('Invalid type for backup setting "$key"');
      }
      if (key == 'appearance' && ((value as int) < 0 || value > 4)) {
        throw const FormatException('Unsupported appearance preset');
      }
      if (key == 'accent' && ((value as int) < 0 || value > 0xffffffff)) {
        throw const FormatException('Invalid theme color');
      }
      if (key == 'readerMode' &&
          !{
            'webtoon',
            'vertical',
            'ltr',
            'rtl',
            'double',
            'longStrip',
          }.contains(value)) {
        throw const FormatException('Unsupported reading mode');
      }
      if (key == 'homeOrder' &&
          (value as List).toSet().length != value.length) {
        throw const FormatException('Home sections cannot be duplicated');
      }
      if (key == 'bookmarks') {
        final bookmarks = jsonDecode(value as String);
        if (bookmarks is! Map<String, dynamic> ||
            bookmarks.values.any((v) => v is! int || v < 0)) {
          throw const FormatException('Invalid bookmark page positions');
        }
      }
    }
  }
}
