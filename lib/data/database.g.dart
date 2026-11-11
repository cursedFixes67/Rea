// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LibraryEntriesTable extends LibraryEntries
    with TableInfo<$LibraryEntriesTable, LibraryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Uncategorized'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    sourceId,
    title,
    payload,
    category,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LibraryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $LibraryEntriesTable createAlias(String alias) {
    return $LibraryEntriesTable(attachedDatabase, alias);
  }
}

class LibraryEntry extends DataClass implements Insertable<LibraryEntry> {
  final String key;
  final String sourceId;
  final String title;
  final String payload;
  final String category;
  final DateTime addedAt;
  const LibraryEntry({
    required this.key,
    required this.sourceId,
    required this.title,
    required this.payload,
    required this.category,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['source_id'] = Variable<String>(sourceId);
    map['title'] = Variable<String>(title);
    map['payload'] = Variable<String>(payload);
    map['category'] = Variable<String>(category);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  LibraryEntriesCompanion toCompanion(bool nullToAbsent) {
    return LibraryEntriesCompanion(
      key: Value(key),
      sourceId: Value(sourceId),
      title: Value(title),
      payload: Value(payload),
      category: Value(category),
      addedAt: Value(addedAt),
    );
  }

  factory LibraryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryEntry(
      key: serializer.fromJson<String>(json['key']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      title: serializer.fromJson<String>(json['title']),
      payload: serializer.fromJson<String>(json['payload']),
      category: serializer.fromJson<String>(json['category']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'sourceId': serializer.toJson<String>(sourceId),
      'title': serializer.toJson<String>(title),
      'payload': serializer.toJson<String>(payload),
      'category': serializer.toJson<String>(category),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  LibraryEntry copyWith({
    String? key,
    String? sourceId,
    String? title,
    String? payload,
    String? category,
    DateTime? addedAt,
  }) => LibraryEntry(
    key: key ?? this.key,
    sourceId: sourceId ?? this.sourceId,
    title: title ?? this.title,
    payload: payload ?? this.payload,
    category: category ?? this.category,
    addedAt: addedAt ?? this.addedAt,
  );
  LibraryEntry copyWithCompanion(LibraryEntriesCompanion data) {
    return LibraryEntry(
      key: data.key.present ? data.key.value : this.key,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      title: data.title.present ? data.title.value : this.title,
      payload: data.payload.present ? data.payload.value : this.payload,
      category: data.category.present ? data.category.value : this.category,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntry(')
          ..write('key: $key, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('payload: $payload, ')
          ..write('category: $category, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, sourceId, title, payload, category, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryEntry &&
          other.key == this.key &&
          other.sourceId == this.sourceId &&
          other.title == this.title &&
          other.payload == this.payload &&
          other.category == this.category &&
          other.addedAt == this.addedAt);
}

class LibraryEntriesCompanion extends UpdateCompanion<LibraryEntry> {
  final Value<String> key;
  final Value<String> sourceId;
  final Value<String> title;
  final Value<String> payload;
  final Value<String> category;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const LibraryEntriesCompanion({
    this.key = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.title = const Value.absent(),
    this.payload = const Value.absent(),
    this.category = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryEntriesCompanion.insert({
    required String key,
    required String sourceId,
    required String title,
    required String payload,
    this.category = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       sourceId = Value(sourceId),
       title = Value(title),
       payload = Value(payload);
  static Insertable<LibraryEntry> custom({
    Expression<String>? key,
    Expression<String>? sourceId,
    Expression<String>? title,
    Expression<String>? payload,
    Expression<String>? category,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (sourceId != null) 'source_id': sourceId,
      if (title != null) 'title': title,
      if (payload != null) 'payload': payload,
      if (category != null) 'category': category,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? sourceId,
    Value<String>? title,
    Value<String>? payload,
    Value<String>? category,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return LibraryEntriesCompanion(
      key: key ?? this.key,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      payload: payload ?? this.payload,
      category: category ?? this.category,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntriesCompanion(')
          ..write('key: $key, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('payload: $payload, ')
          ..write('category: $category, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChapterEntriesTable extends ChapterEntries
    with TableInfo<$ChapterEntriesTable, ChapterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChapterEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mangaKeyMeta = const VerificationMeta(
    'mangaKey',
  );
  @override
  late final GeneratedColumn<String> mangaKey = GeneratedColumn<String>(
    'manga_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastReadMeta = const VerificationMeta(
    'lastRead',
  );
  @override
  late final GeneratedColumn<DateTime> lastRead = GeneratedColumn<DateTime>(
    'last_read',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mangaKey,
    url,
    payload,
    page,
    totalPages,
    completed,
    lastRead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapter_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('manga_key')) {
      context.handle(
        _mangaKeyMeta,
        mangaKey.isAcceptableOrUnknown(data['manga_key']!, _mangaKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_mangaKeyMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('last_read')) {
      context.handle(
        _lastReadMeta,
        lastRead.isAcceptableOrUnknown(data['last_read']!, _lastReadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mangaKey, url};
  @override
  ChapterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterEntry(
      mangaKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manga_key'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      lastRead: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read'],
      ),
    );
  }

  @override
  $ChapterEntriesTable createAlias(String alias) {
    return $ChapterEntriesTable(attachedDatabase, alias);
  }
}

class ChapterEntry extends DataClass implements Insertable<ChapterEntry> {
  final String mangaKey;
  final String url;
  final String payload;
  final int page;
  final int totalPages;
  final bool completed;
  final DateTime? lastRead;
  const ChapterEntry({
    required this.mangaKey,
    required this.url,
    required this.payload,
    required this.page,
    required this.totalPages,
    required this.completed,
    this.lastRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['manga_key'] = Variable<String>(mangaKey);
    map['url'] = Variable<String>(url);
    map['payload'] = Variable<String>(payload);
    map['page'] = Variable<int>(page);
    map['total_pages'] = Variable<int>(totalPages);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || lastRead != null) {
      map['last_read'] = Variable<DateTime>(lastRead);
    }
    return map;
  }

  ChapterEntriesCompanion toCompanion(bool nullToAbsent) {
    return ChapterEntriesCompanion(
      mangaKey: Value(mangaKey),
      url: Value(url),
      payload: Value(payload),
      page: Value(page),
      totalPages: Value(totalPages),
      completed: Value(completed),
      lastRead: lastRead == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRead),
    );
  }

  factory ChapterEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterEntry(
      mangaKey: serializer.fromJson<String>(json['mangaKey']),
      url: serializer.fromJson<String>(json['url']),
      payload: serializer.fromJson<String>(json['payload']),
      page: serializer.fromJson<int>(json['page']),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      completed: serializer.fromJson<bool>(json['completed']),
      lastRead: serializer.fromJson<DateTime?>(json['lastRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mangaKey': serializer.toJson<String>(mangaKey),
      'url': serializer.toJson<String>(url),
      'payload': serializer.toJson<String>(payload),
      'page': serializer.toJson<int>(page),
      'totalPages': serializer.toJson<int>(totalPages),
      'completed': serializer.toJson<bool>(completed),
      'lastRead': serializer.toJson<DateTime?>(lastRead),
    };
  }

  ChapterEntry copyWith({
    String? mangaKey,
    String? url,
    String? payload,
    int? page,
    int? totalPages,
    bool? completed,
    Value<DateTime?> lastRead = const Value.absent(),
  }) => ChapterEntry(
    mangaKey: mangaKey ?? this.mangaKey,
    url: url ?? this.url,
    payload: payload ?? this.payload,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    completed: completed ?? this.completed,
    lastRead: lastRead.present ? lastRead.value : this.lastRead,
  );
  ChapterEntry copyWithCompanion(ChapterEntriesCompanion data) {
    return ChapterEntry(
      mangaKey: data.mangaKey.present ? data.mangaKey.value : this.mangaKey,
      url: data.url.present ? data.url.value : this.url,
      payload: data.payload.present ? data.payload.value : this.payload,
      page: data.page.present ? data.page.value : this.page,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      completed: data.completed.present ? data.completed.value : this.completed,
      lastRead: data.lastRead.present ? data.lastRead.value : this.lastRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterEntry(')
          ..write('mangaKey: $mangaKey, ')
          ..write('url: $url, ')
          ..write('payload: $payload, ')
          ..write('page: $page, ')
          ..write('totalPages: $totalPages, ')
          ..write('completed: $completed, ')
          ..write('lastRead: $lastRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mangaKey,
    url,
    payload,
    page,
    totalPages,
    completed,
    lastRead,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterEntry &&
          other.mangaKey == this.mangaKey &&
          other.url == this.url &&
          other.payload == this.payload &&
          other.page == this.page &&
          other.totalPages == this.totalPages &&
          other.completed == this.completed &&
          other.lastRead == this.lastRead);
}

class ChapterEntriesCompanion extends UpdateCompanion<ChapterEntry> {
  final Value<String> mangaKey;
  final Value<String> url;
  final Value<String> payload;
  final Value<int> page;
  final Value<int> totalPages;
  final Value<bool> completed;
  final Value<DateTime?> lastRead;
  final Value<int> rowid;
  const ChapterEntriesCompanion({
    this.mangaKey = const Value.absent(),
    this.url = const Value.absent(),
    this.payload = const Value.absent(),
    this.page = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.completed = const Value.absent(),
    this.lastRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChapterEntriesCompanion.insert({
    required String mangaKey,
    required String url,
    required String payload,
    this.page = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.completed = const Value.absent(),
    this.lastRead = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mangaKey = Value(mangaKey),
       url = Value(url),
       payload = Value(payload);
  static Insertable<ChapterEntry> custom({
    Expression<String>? mangaKey,
    Expression<String>? url,
    Expression<String>? payload,
    Expression<int>? page,
    Expression<int>? totalPages,
    Expression<bool>? completed,
    Expression<DateTime>? lastRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mangaKey != null) 'manga_key': mangaKey,
      if (url != null) 'url': url,
      if (payload != null) 'payload': payload,
      if (page != null) 'page': page,
      if (totalPages != null) 'total_pages': totalPages,
      if (completed != null) 'completed': completed,
      if (lastRead != null) 'last_read': lastRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChapterEntriesCompanion copyWith({
    Value<String>? mangaKey,
    Value<String>? url,
    Value<String>? payload,
    Value<int>? page,
    Value<int>? totalPages,
    Value<bool>? completed,
    Value<DateTime?>? lastRead,
    Value<int>? rowid,
  }) {
    return ChapterEntriesCompanion(
      mangaKey: mangaKey ?? this.mangaKey,
      url: url ?? this.url,
      payload: payload ?? this.payload,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      completed: completed ?? this.completed,
      lastRead: lastRead ?? this.lastRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mangaKey.present) {
      map['manga_key'] = Variable<String>(mangaKey.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (lastRead.present) {
      map['last_read'] = Variable<DateTime>(lastRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChapterEntriesCompanion(')
          ..write('mangaKey: $mangaKey, ')
          ..write('url: $url, ')
          ..write('payload: $payload, ')
          ..write('page: $page, ')
          ..write('totalPages: $totalPages, ')
          ..write('completed: $completed, ')
          ..write('lastRead: $lastRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RepositoryEntriesTable extends RepositoryEntries
    with TableInfo<$RepositoryEntriesTable, RepositoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RepositoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signerMeta = const VerificationMeta('signer');
  @override
  late final GeneratedColumn<String> signer = GeneratedColumn<String>(
    'signer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogueMeta = const VerificationMeta(
    'catalogue',
  );
  @override
  late final GeneratedColumn<String> catalogue = GeneratedColumn<String>(
    'catalogue',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    url,
    name,
    signer,
    catalogue,
    enabled,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'repository_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<RepositoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('signer')) {
      context.handle(
        _signerMeta,
        signer.isAcceptableOrUnknown(data['signer']!, _signerMeta),
      );
    } else if (isInserting) {
      context.missing(_signerMeta);
    }
    if (data.containsKey('catalogue')) {
      context.handle(
        _catalogueMeta,
        catalogue.isAcceptableOrUnknown(data['catalogue']!, _catalogueMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  RepositoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RepositoryEntry(
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      signer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signer'],
      )!,
      catalogue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalogue'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $RepositoryEntriesTable createAlias(String alias) {
    return $RepositoryEntriesTable(attachedDatabase, alias);
  }
}

class RepositoryEntry extends DataClass implements Insertable<RepositoryEntry> {
  final String url;
  final String name;
  final String signer;
  final String catalogue;
  final bool enabled;
  final DateTime? syncedAt;
  const RepositoryEntry({
    required this.url,
    required this.name,
    required this.signer,
    required this.catalogue,
    required this.enabled,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['name'] = Variable<String>(name);
    map['signer'] = Variable<String>(signer);
    map['catalogue'] = Variable<String>(catalogue);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  RepositoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return RepositoryEntriesCompanion(
      url: Value(url),
      name: Value(name),
      signer: Value(signer),
      catalogue: Value(catalogue),
      enabled: Value(enabled),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory RepositoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RepositoryEntry(
      url: serializer.fromJson<String>(json['url']),
      name: serializer.fromJson<String>(json['name']),
      signer: serializer.fromJson<String>(json['signer']),
      catalogue: serializer.fromJson<String>(json['catalogue']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'name': serializer.toJson<String>(name),
      'signer': serializer.toJson<String>(signer),
      'catalogue': serializer.toJson<String>(catalogue),
      'enabled': serializer.toJson<bool>(enabled),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  RepositoryEntry copyWith({
    String? url,
    String? name,
    String? signer,
    String? catalogue,
    bool? enabled,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => RepositoryEntry(
    url: url ?? this.url,
    name: name ?? this.name,
    signer: signer ?? this.signer,
    catalogue: catalogue ?? this.catalogue,
    enabled: enabled ?? this.enabled,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  RepositoryEntry copyWithCompanion(RepositoryEntriesCompanion data) {
    return RepositoryEntry(
      url: data.url.present ? data.url.value : this.url,
      name: data.name.present ? data.name.value : this.name,
      signer: data.signer.present ? data.signer.value : this.signer,
      catalogue: data.catalogue.present ? data.catalogue.value : this.catalogue,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RepositoryEntry(')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('signer: $signer, ')
          ..write('catalogue: $catalogue, ')
          ..write('enabled: $enabled, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(url, name, signer, catalogue, enabled, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RepositoryEntry &&
          other.url == this.url &&
          other.name == this.name &&
          other.signer == this.signer &&
          other.catalogue == this.catalogue &&
          other.enabled == this.enabled &&
          other.syncedAt == this.syncedAt);
}

class RepositoryEntriesCompanion extends UpdateCompanion<RepositoryEntry> {
  final Value<String> url;
  final Value<String> name;
  final Value<String> signer;
  final Value<String> catalogue;
  final Value<bool> enabled;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const RepositoryEntriesCompanion({
    this.url = const Value.absent(),
    this.name = const Value.absent(),
    this.signer = const Value.absent(),
    this.catalogue = const Value.absent(),
    this.enabled = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RepositoryEntriesCompanion.insert({
    required String url,
    required String name,
    required String signer,
    this.catalogue = const Value.absent(),
    this.enabled = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       name = Value(name),
       signer = Value(signer);
  static Insertable<RepositoryEntry> custom({
    Expression<String>? url,
    Expression<String>? name,
    Expression<String>? signer,
    Expression<String>? catalogue,
    Expression<bool>? enabled,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (signer != null) 'signer': signer,
      if (catalogue != null) 'catalogue': catalogue,
      if (enabled != null) 'enabled': enabled,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RepositoryEntriesCompanion copyWith({
    Value<String>? url,
    Value<String>? name,
    Value<String>? signer,
    Value<String>? catalogue,
    Value<bool>? enabled,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return RepositoryEntriesCompanion(
      url: url ?? this.url,
      name: name ?? this.name,
      signer: signer ?? this.signer,
      catalogue: catalogue ?? this.catalogue,
      enabled: enabled ?? this.enabled,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (signer.present) {
      map['signer'] = Variable<String>(signer.value);
    }
    if (catalogue.present) {
      map['catalogue'] = Variable<String>(catalogue.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RepositoryEntriesCompanion(')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('signer: $signer, ')
          ..write('catalogue: $catalogue, ')
          ..write('enabled: $enabled, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mangaKeyMeta = const VerificationMeta(
    'mangaKey',
  );
  @override
  late final GeneratedColumn<String> mangaKey = GeneratedColumn<String>(
    'manga_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, mangaKey, seconds, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('manga_key')) {
      context.handle(
        _mangaKeyMeta,
        mangaKey.isAcceptableOrUnknown(data['manga_key']!, _mangaKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_mangaKeyMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mangaKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manga_key'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSession extends DataClass implements Insertable<ReadingSession> {
  final int id;
  final String mangaKey;
  final int seconds;
  final DateTime createdAt;
  const ReadingSession({
    required this.id,
    required this.mangaKey,
    required this.seconds,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['manga_key'] = Variable<String>(mangaKey);
    map['seconds'] = Variable<int>(seconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      mangaKey: Value(mangaKey),
      seconds: Value(seconds),
      createdAt: Value(createdAt),
    );
  }

  factory ReadingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSession(
      id: serializer.fromJson<int>(json['id']),
      mangaKey: serializer.fromJson<String>(json['mangaKey']),
      seconds: serializer.fromJson<int>(json['seconds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mangaKey': serializer.toJson<String>(mangaKey),
      'seconds': serializer.toJson<int>(seconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReadingSession copyWith({
    int? id,
    String? mangaKey,
    int? seconds,
    DateTime? createdAt,
  }) => ReadingSession(
    id: id ?? this.id,
    mangaKey: mangaKey ?? this.mangaKey,
    seconds: seconds ?? this.seconds,
    createdAt: createdAt ?? this.createdAt,
  );
  ReadingSession copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSession(
      id: data.id.present ? data.id.value : this.id,
      mangaKey: data.mangaKey.present ? data.mangaKey.value : this.mangaKey,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSession(')
          ..write('id: $id, ')
          ..write('mangaKey: $mangaKey, ')
          ..write('seconds: $seconds, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mangaKey, seconds, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSession &&
          other.id == this.id &&
          other.mangaKey == this.mangaKey &&
          other.seconds == this.seconds &&
          other.createdAt == this.createdAt);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSession> {
  final Value<int> id;
  final Value<String> mangaKey;
  final Value<int> seconds;
  final Value<DateTime> createdAt;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.mangaKey = const Value.absent(),
    this.seconds = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String mangaKey,
    required int seconds,
    this.createdAt = const Value.absent(),
  }) : mangaKey = Value(mangaKey),
       seconds = Value(seconds);
  static Insertable<ReadingSession> custom({
    Expression<int>? id,
    Expression<String>? mangaKey,
    Expression<int>? seconds,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mangaKey != null) 'manga_key': mangaKey,
      if (seconds != null) 'seconds': seconds,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? mangaKey,
    Value<int>? seconds,
    Value<DateTime>? createdAt,
  }) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      mangaKey: mangaKey ?? this.mangaKey,
      seconds: seconds ?? this.seconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mangaKey.present) {
      map['manga_key'] = Variable<String>(mangaKey.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('mangaKey: $mangaKey, ')
          ..write('seconds: $seconds, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$DreamDatabase extends GeneratedDatabase {
  _$DreamDatabase(QueryExecutor e) : super(e);
  $DreamDatabaseManager get managers => $DreamDatabaseManager(this);
  late final $LibraryEntriesTable libraryEntries = $LibraryEntriesTable(this);
  late final $ChapterEntriesTable chapterEntries = $ChapterEntriesTable(this);
  late final $RepositoryEntriesTable repositoryEntries =
      $RepositoryEntriesTable(this);
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    libraryEntries,
    chapterEntries,
    repositoryEntries,
    readingSessions,
  ];
}

typedef $$LibraryEntriesTableCreateCompanionBuilder =
    LibraryEntriesCompanion Function({
      required String key,
      required String sourceId,
      required String title,
      required String payload,
      Value<String> category,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });
typedef $$LibraryEntriesTableUpdateCompanionBuilder =
    LibraryEntriesCompanion Function({
      Value<String> key,
      Value<String> sourceId,
      Value<String> title,
      Value<String> payload,
      Value<String> category,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$LibraryEntriesTableFilterComposer
    extends Composer<_$DreamDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryEntriesTableOrderingComposer
    extends Composer<_$DreamDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryEntriesTableAnnotationComposer
    extends Composer<_$DreamDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$LibraryEntriesTableTableManager
    extends
        RootTableManager<
          _$DreamDatabase,
          $LibraryEntriesTable,
          LibraryEntry,
          $$LibraryEntriesTableFilterComposer,
          $$LibraryEntriesTableOrderingComposer,
          $$LibraryEntriesTableAnnotationComposer,
          $$LibraryEntriesTableCreateCompanionBuilder,
          $$LibraryEntriesTableUpdateCompanionBuilder,
          (
            LibraryEntry,
            BaseReferences<_$DreamDatabase, $LibraryEntriesTable, LibraryEntry>,
          ),
          LibraryEntry,
          PrefetchHooks Function()
        > {
  $$LibraryEntriesTableTableManager(
    _$DreamDatabase db,
    $LibraryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryEntriesCompanion(
                key: key,
                sourceId: sourceId,
                title: title,
                payload: payload,
                category: category,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String sourceId,
                required String title,
                required String payload,
                Value<String> category = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryEntriesCompanion.insert(
                key: key,
                sourceId: sourceId,
                title: title,
                payload: payload,
                category: category,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryEntriesTable, LibraryEntry>(table),
                  BaseReferences<
                    _$DreamDatabase,
                    $LibraryEntriesTable,
                    LibraryEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$DreamDatabase,
      $LibraryEntriesTable,
      LibraryEntry,
      $$LibraryEntriesTableFilterComposer,
      $$LibraryEntriesTableOrderingComposer,
      $$LibraryEntriesTableAnnotationComposer,
      $$LibraryEntriesTableCreateCompanionBuilder,
      $$LibraryEntriesTableUpdateCompanionBuilder,
      (
        LibraryEntry,
        BaseReferences<_$DreamDatabase, $LibraryEntriesTable, LibraryEntry>,
      ),
      LibraryEntry,
      PrefetchHooks Function()
    >;
typedef $$ChapterEntriesTableCreateCompanionBuilder =
    ChapterEntriesCompanion Function({
      required String mangaKey,
      required String url,
      required String payload,
      Value<int> page,
      Value<int> totalPages,
      Value<bool> completed,
      Value<DateTime?> lastRead,
      Value<int> rowid,
    });
typedef $$ChapterEntriesTableUpdateCompanionBuilder =
    ChapterEntriesCompanion Function({
      Value<String> mangaKey,
      Value<String> url,
      Value<String> payload,
      Value<int> page,
      Value<int> totalPages,
      Value<bool> completed,
      Value<DateTime?> lastRead,
      Value<int> rowid,
    });

class $$ChapterEntriesTableFilterComposer
    extends Composer<_$DreamDatabase, $ChapterEntriesTable> {
  $$ChapterEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mangaKey => $composableBuilder(
    column: $table.mangaKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRead => $composableBuilder(
    column: $table.lastRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChapterEntriesTableOrderingComposer
    extends Composer<_$DreamDatabase, $ChapterEntriesTable> {
  $$ChapterEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mangaKey => $composableBuilder(
    column: $table.mangaKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRead => $composableBuilder(
    column: $table.lastRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChapterEntriesTableAnnotationComposer
    extends Composer<_$DreamDatabase, $ChapterEntriesTable> {
  $$ChapterEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mangaKey =>
      $composableBuilder(column: $table.mangaKey, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get lastRead =>
      $composableBuilder(column: $table.lastRead, builder: (column) => column);
}

class $$ChapterEntriesTableTableManager
    extends
        RootTableManager<
          _$DreamDatabase,
          $ChapterEntriesTable,
          ChapterEntry,
          $$ChapterEntriesTableFilterComposer,
          $$ChapterEntriesTableOrderingComposer,
          $$ChapterEntriesTableAnnotationComposer,
          $$ChapterEntriesTableCreateCompanionBuilder,
          $$ChapterEntriesTableUpdateCompanionBuilder,
          (
            ChapterEntry,
            BaseReferences<_$DreamDatabase, $ChapterEntriesTable, ChapterEntry>,
          ),
          ChapterEntry,
          PrefetchHooks Function()
        > {
  $$ChapterEntriesTableTableManager(
    _$DreamDatabase db,
    $ChapterEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChapterEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChapterEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChapterEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mangaKey = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> lastRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChapterEntriesCompanion(
                mangaKey: mangaKey,
                url: url,
                payload: payload,
                page: page,
                totalPages: totalPages,
                completed: completed,
                lastRead: lastRead,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mangaKey,
                required String url,
                required String payload,
                Value<int> page = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> lastRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChapterEntriesCompanion.insert(
                mangaKey: mangaKey,
                url: url,
                payload: payload,
                page: page,
                totalPages: totalPages,
                completed: completed,
                lastRead: lastRead,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChapterEntriesTable, ChapterEntry>(table),
                  BaseReferences<
                    _$DreamDatabase,
                    $ChapterEntriesTable,
                    ChapterEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChapterEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$DreamDatabase,
      $ChapterEntriesTable,
      ChapterEntry,
      $$ChapterEntriesTableFilterComposer,
      $$ChapterEntriesTableOrderingComposer,
      $$ChapterEntriesTableAnnotationComposer,
      $$ChapterEntriesTableCreateCompanionBuilder,
      $$ChapterEntriesTableUpdateCompanionBuilder,
      (
        ChapterEntry,
        BaseReferences<_$DreamDatabase, $ChapterEntriesTable, ChapterEntry>,
      ),
      ChapterEntry,
      PrefetchHooks Function()
    >;
typedef $$RepositoryEntriesTableCreateCompanionBuilder =
    RepositoryEntriesCompanion Function({
      required String url,
      required String name,
      required String signer,
      Value<String> catalogue,
      Value<bool> enabled,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$RepositoryEntriesTableUpdateCompanionBuilder =
    RepositoryEntriesCompanion Function({
      Value<String> url,
      Value<String> name,
      Value<String> signer,
      Value<String> catalogue,
      Value<bool> enabled,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$RepositoryEntriesTableFilterComposer
    extends Composer<_$DreamDatabase, $RepositoryEntriesTable> {
  $$RepositoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signer => $composableBuilder(
    column: $table.signer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogue => $composableBuilder(
    column: $table.catalogue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RepositoryEntriesTableOrderingComposer
    extends Composer<_$DreamDatabase, $RepositoryEntriesTable> {
  $$RepositoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signer => $composableBuilder(
    column: $table.signer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogue => $composableBuilder(
    column: $table.catalogue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RepositoryEntriesTableAnnotationComposer
    extends Composer<_$DreamDatabase, $RepositoryEntriesTable> {
  $$RepositoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get signer =>
      $composableBuilder(column: $table.signer, builder: (column) => column);

  GeneratedColumn<String> get catalogue =>
      $composableBuilder(column: $table.catalogue, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$RepositoryEntriesTableTableManager
    extends
        RootTableManager<
          _$DreamDatabase,
          $RepositoryEntriesTable,
          RepositoryEntry,
          $$RepositoryEntriesTableFilterComposer,
          $$RepositoryEntriesTableOrderingComposer,
          $$RepositoryEntriesTableAnnotationComposer,
          $$RepositoryEntriesTableCreateCompanionBuilder,
          $$RepositoryEntriesTableUpdateCompanionBuilder,
          (
            RepositoryEntry,
            BaseReferences<
              _$DreamDatabase,
              $RepositoryEntriesTable,
              RepositoryEntry
            >,
          ),
          RepositoryEntry,
          PrefetchHooks Function()
        > {
  $$RepositoryEntriesTableTableManager(
    _$DreamDatabase db,
    $RepositoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RepositoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RepositoryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RepositoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> signer = const Value.absent(),
                Value<String> catalogue = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RepositoryEntriesCompanion(
                url: url,
                name: name,
                signer: signer,
                catalogue: catalogue,
                enabled: enabled,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String url,
                required String name,
                required String signer,
                Value<String> catalogue = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RepositoryEntriesCompanion.insert(
                url: url,
                name: name,
                signer: signer,
                catalogue: catalogue,
                enabled: enabled,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RepositoryEntriesTable, RepositoryEntry>(table),
                  BaseReferences<
                    _$DreamDatabase,
                    $RepositoryEntriesTable,
                    RepositoryEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RepositoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$DreamDatabase,
      $RepositoryEntriesTable,
      RepositoryEntry,
      $$RepositoryEntriesTableFilterComposer,
      $$RepositoryEntriesTableOrderingComposer,
      $$RepositoryEntriesTableAnnotationComposer,
      $$RepositoryEntriesTableCreateCompanionBuilder,
      $$RepositoryEntriesTableUpdateCompanionBuilder,
      (
        RepositoryEntry,
        BaseReferences<
          _$DreamDatabase,
          $RepositoryEntriesTable,
          RepositoryEntry
        >,
      ),
      RepositoryEntry,
      PrefetchHooks Function()
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<int> id,
      required String mangaKey,
      required int seconds,
      Value<DateTime> createdAt,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<int> id,
      Value<String> mangaKey,
      Value<int> seconds,
      Value<DateTime> createdAt,
    });

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$DreamDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mangaKey => $composableBuilder(
    column: $table.mangaKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$DreamDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mangaKey => $composableBuilder(
    column: $table.mangaKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$DreamDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mangaKey =>
      $composableBuilder(column: $table.mangaKey, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$DreamDatabase,
          $ReadingSessionsTable,
          ReadingSession,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (
            ReadingSession,
            BaseReferences<
              _$DreamDatabase,
              $ReadingSessionsTable,
              ReadingSession
            >,
          ),
          ReadingSession,
          PrefetchHooks Function()
        > {
  $$ReadingSessionsTableTableManager(
    _$DreamDatabase db,
    $ReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mangaKey = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadingSessionsCompanion(
                id: id,
                mangaKey: mangaKey,
                seconds: seconds,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mangaKey,
                required int seconds,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadingSessionsCompanion.insert(
                id: id,
                mangaKey: mangaKey,
                seconds: seconds,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingSessionsTable, ReadingSession>(table),
                  BaseReferences<
                    _$DreamDatabase,
                    $ReadingSessionsTable,
                    ReadingSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$DreamDatabase,
      $ReadingSessionsTable,
      ReadingSession,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (
        ReadingSession,
        BaseReferences<_$DreamDatabase, $ReadingSessionsTable, ReadingSession>,
      ),
      ReadingSession,
      PrefetchHooks Function()
    >;

class $DreamDatabaseManager {
  final _$DreamDatabase _db;
  $DreamDatabaseManager(this._db);
  $$LibraryEntriesTableTableManager get libraryEntries =>
      $$LibraryEntriesTableTableManager(_db, _db.libraryEntries);
  $$ChapterEntriesTableTableManager get chapterEntries =>
      $$ChapterEntriesTableTableManager(_db, _db.chapterEntries);
  $$RepositoryEntriesTableTableManager get repositoryEntries =>
      $$RepositoryEntriesTableTableManager(_db, _db.repositoryEntries);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
}
