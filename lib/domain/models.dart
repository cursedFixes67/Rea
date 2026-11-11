typedef Json = Map<String, dynamic>;

class Manga {
  final String sourceId,
      url,
      title,
      cover,
      description,
      author,
      artist,
      genre,
      updateStrategy;
  final Json memo;
  final bool initialized;
  final int status;
  const Manga({
    required this.sourceId,
    required this.url,
    required this.title,
    this.cover = '',
    this.description = '',
    this.author = '',
    this.artist = '',
    this.memo = const {},
    this.initialized = false,
    this.updateStrategy = 'ALWAYS_UPDATE',
    this.genre = '',
    this.status = 0,
  });
  String get key => '$sourceId::$url';
  factory Manga.fromJson(Json j) => Manga(
    sourceId: '${j['sourceId'] ?? ''}',
    url: j['url'] ?? '',
    title: j['title'] ?? '',
    cover: j['cover'] ?? '',
    description: j['description'] ?? '',
    author: j['author'] ?? '',
    artist: j['artist'] ?? '',
    memo: Map<String, dynamic>.from(j['memo'] as Map? ?? {}),
    initialized: j['initialized'] == true,
    updateStrategy: j['updateStrategy'] ?? 'ALWAYS_UPDATE',
    genre: j['genre'] ?? '',
    status: j['status'] ?? 0,
  );
  Json toJson() => {
    'sourceId': sourceId,
    'url': url,
    'title': title,
    'cover': cover,
    'description': description,
    'author': author,
    'artist': artist,
    'memo': memo,
    'initialized': initialized,
    'updateStrategy': updateStrategy,
    'genre': genre,
    'status': status,
  };
}

class Chapter {
  final String url, name, scanlator;
  final Json memo;
  final double number;
  final int date;
  const Chapter({
    required this.url,
    required this.name,
    this.number = -1,
    this.scanlator = '',
    this.memo = const {},
    this.date = 0,
  });
  factory Chapter.fromJson(Json j) => Chapter(
    url: j['url'] ?? '',
    name: j['name'] ?? '',
    scanlator: j['scanlator'] ?? '',
    memo: Map<String, dynamic>.from(j['memo'] as Map? ?? {}),
    number: (j['number'] as num? ?? -1).toDouble(),
    date: j['date'] ?? 0,
  );
  Json toJson() => {
    'url': url,
    'name': name,
    'number': number,
    'date': date,
    'scanlator': scanlator,
    'memo': memo,
  };
}

class ReaderPage {
  final String url;
  final Map<String, String> headers;
  final String sourceId, pageUrl;
  final int index;
  const ReaderPage(
    this.url,
    this.headers, {
    this.sourceId = '',
    this.pageUrl = '',
    this.index = 0,
  });
  Json toJson() => {
    'url': url,
    'headers': headers,
    'sourceId': sourceId,
    'pageUrl': pageUrl,
    'index': index,
  };
  factory ReaderPage.fromJson(Json j) => ReaderPage(
    j['url'] ?? '',
    (j['headers'] as Map? ?? {}).map((k, v) => MapEntry('$k', '$v')),
    sourceId: '${j['sourceId'] ?? ''}',
    pageUrl: j['pageUrl'] ?? '',
    index: j['index'] ?? 0,
  );
}

class ExtensionSource {
  final String id, name, language, homeUrl;
  const ExtensionSource(this.id, this.name, this.language, this.homeUrl);
  factory ExtensionSource.fromJson(Json j) => ExtensionSource(
    '${j['id']}',
    j['name'] ?? '',
    j['language'] ?? j['lang'] ?? '',
    j['homeUrl'] ?? j['baseUrl'] ?? '',
  );
  Json toJson() => {
    'id': id,
    'name': name,
    'language': language,
    'homeUrl': homeUrl,
  };
}

class ExtensionEntry {
  final String name,
      packageName,
      apkUrl,
      iconUrl,
      api,
      version,
      repository,
      signer;
  final int code, contentWarning;
  final List<ExtensionSource> sources;
  const ExtensionEntry({
    required this.name,
    required this.packageName,
    required this.apkUrl,
    required this.iconUrl,
    required this.api,
    required this.version,
    required this.code,
    required this.repository,
    required this.signer,
    required this.sources,
    this.contentWarning = 0,
  });
  String get language => sources.map((s) => s.language).toSet().join(', ');
  // Values follow Mihon's current NetworkExtensionStore protobuf enum.
  bool get adultOnly => contentWarning == 3;
  String get contentLabel => switch (contentWarning) {
    2 => 'Mixed content',
    3 => 'Adult content',
    _ => '',
  };
  bool matchesSearch(String query) {
    final term = query.trim().toLowerCase();
    return name.toLowerCase().contains(term) ||
        sources.any((s) => s.name.toLowerCase().contains(term));
  }

  Json toJson() => {
    'name': name,
    'packageName': packageName,
    'apkUrl': apkUrl,
    'iconUrl': iconUrl,
    'api': api,
    'version': version,
    'code': code,
    'repository': repository,
    'signer': signer,
    'sources': sources.map((s) => s.toJson()).toList(),
    'contentWarning': contentWarning,
  };
  factory ExtensionEntry.fromJson(Json j) => ExtensionEntry(
    name: j['name'],
    packageName: j['packageName'],
    apkUrl: j['apkUrl'],
    iconUrl: j['iconUrl'],
    api: j['api'],
    version: j['version'],
    code: j['code'],
    repository: j['repository'],
    signer: j['signer'],
    contentWarning: j['contentWarning'] ?? 0,
    sources: (j['sources'] as List)
        .map((s) => ExtensionSource.fromJson(Map<String, dynamic>.from(s)))
        .toList(),
  );
}
