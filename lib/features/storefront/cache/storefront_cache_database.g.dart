// GENERATED CODE - DO NOT MODIFY BY HAND

// coverage:ignore-file

part of 'storefront_cache_database.dart';

// ignore_for_file: type=lint
class $StorefrontCacheMetadataTable extends StorefrontCacheMetadata
    with TableInfo<$StorefrontCacheMetadataTable, StorefrontCacheMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorefrontCacheMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopSlugMeta = const VerificationMeta(
    'shopSlug',
  );
  @override
  late final GeneratedColumn<String> shopSlug = GeneratedColumn<String>(
    'shop_slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogVersionMeta = const VerificationMeta(
    'catalogVersion',
  );
  @override
  late final GeneratedColumn<int> catalogVersion = GeneratedColumn<int>(
    'catalog_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshedAtMeta = const VerificationMeta(
    'refreshedAt',
  );
  @override
  late final GeneratedColumn<DateTime> refreshedAt = GeneratedColumn<DateTime>(
    'refreshed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSuccessfulRefreshAtMeta =
      const VerificationMeta('lastSuccessfulRefreshAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulRefreshAt =
      GeneratedColumn<DateTime>(
        'last_successful_refresh_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultPageSizeMeta = const VerificationMeta(
    'defaultPageSize',
  );
  @override
  late final GeneratedColumn<int> defaultPageSize = GeneratedColumn<int>(
    'default_page_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maximumPageSizeMeta = const VerificationMeta(
    'maximumPageSize',
  );
  @override
  late final GeneratedColumn<int> maximumPageSize = GeneratedColumn<int>(
    'maximum_page_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pickupEnabledMeta = const VerificationMeta(
    'pickupEnabled',
  );
  @override
  late final GeneratedColumn<bool> pickupEnabled = GeneratedColumn<bool>(
    'pickup_enabled',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pickup_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _deliveryEnabledMeta = const VerificationMeta(
    'deliveryEnabled',
  );
  @override
  late final GeneratedColumn<bool> deliveryEnabled = GeneratedColumn<bool>(
    'delivery_enabled',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("delivery_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _reservationEnabledMeta =
      const VerificationMeta('reservationEnabled');
  @override
  late final GeneratedColumn<bool> reservationEnabled = GeneratedColumn<bool>(
    'reservation_enabled',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reservation_enabled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    shopSlug,
    catalogVersion,
    refreshedAt,
    lastSuccessfulRefreshAt,
    currency,
    locale,
    timeZone,
    defaultPageSize,
    maximumPageSize,
    pickupEnabled,
    deliveryEnabled,
    reservationEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storefront_cache_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorefrontCacheMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_slug')) {
      context.handle(
        _shopSlugMeta,
        shopSlug.isAcceptableOrUnknown(data['shop_slug']!, _shopSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_shopSlugMeta);
    }
    if (data.containsKey('catalog_version')) {
      context.handle(
        _catalogVersionMeta,
        catalogVersion.isAcceptableOrUnknown(
          data['catalog_version']!,
          _catalogVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogVersionMeta);
    }
    if (data.containsKey('refreshed_at')) {
      context.handle(
        _refreshedAtMeta,
        refreshedAt.isAcceptableOrUnknown(
          data['refreshed_at']!,
          _refreshedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshedAtMeta);
    }
    if (data.containsKey('last_successful_refresh_at')) {
      context.handle(
        _lastSuccessfulRefreshAtMeta,
        lastSuccessfulRefreshAt.isAcceptableOrUnknown(
          data['last_successful_refresh_at']!,
          _lastSuccessfulRefreshAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSuccessfulRefreshAtMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    if (data.containsKey('default_page_size')) {
      context.handle(
        _defaultPageSizeMeta,
        defaultPageSize.isAcceptableOrUnknown(
          data['default_page_size']!,
          _defaultPageSizeMeta,
        ),
      );
    }
    if (data.containsKey('maximum_page_size')) {
      context.handle(
        _maximumPageSizeMeta,
        maximumPageSize.isAcceptableOrUnknown(
          data['maximum_page_size']!,
          _maximumPageSizeMeta,
        ),
      );
    }
    if (data.containsKey('pickup_enabled')) {
      context.handle(
        _pickupEnabledMeta,
        pickupEnabled.isAcceptableOrUnknown(
          data['pickup_enabled']!,
          _pickupEnabledMeta,
        ),
      );
    }
    if (data.containsKey('delivery_enabled')) {
      context.handle(
        _deliveryEnabledMeta,
        deliveryEnabled.isAcceptableOrUnknown(
          data['delivery_enabled']!,
          _deliveryEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reservation_enabled')) {
      context.handle(
        _reservationEnabledMeta,
        reservationEnabled.isAcceptableOrUnknown(
          data['reservation_enabled']!,
          _reservationEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopSlug};
  @override
  StorefrontCacheMetadataRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorefrontCacheMetadataRow(
      shopSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_slug'],
      )!,
      catalogVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_version'],
      )!,
      refreshedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refreshed_at'],
      )!,
      lastSuccessfulRefreshAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_refresh_at'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      ),
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      ),
      defaultPageSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_page_size'],
      ),
      maximumPageSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maximum_page_size'],
      ),
      pickupEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pickup_enabled'],
      ),
      deliveryEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}delivery_enabled'],
      ),
      reservationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reservation_enabled'],
      ),
    );
  }

  @override
  $StorefrontCacheMetadataTable createAlias(String alias) {
    return $StorefrontCacheMetadataTable(attachedDatabase, alias);
  }
}

class StorefrontCacheMetadataRow extends DataClass
    implements Insertable<StorefrontCacheMetadataRow> {
  final String shopSlug;
  final int catalogVersion;
  final DateTime refreshedAt;
  final DateTime lastSuccessfulRefreshAt;
  final String? currency;
  final String? locale;
  final String? timeZone;
  final int? defaultPageSize;
  final int? maximumPageSize;
  final bool? pickupEnabled;
  final bool? deliveryEnabled;
  final bool? reservationEnabled;
  const StorefrontCacheMetadataRow({
    required this.shopSlug,
    required this.catalogVersion,
    required this.refreshedAt,
    required this.lastSuccessfulRefreshAt,
    this.currency,
    this.locale,
    this.timeZone,
    this.defaultPageSize,
    this.maximumPageSize,
    this.pickupEnabled,
    this.deliveryEnabled,
    this.reservationEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_slug'] = Variable<String>(shopSlug);
    map['catalog_version'] = Variable<int>(catalogVersion);
    map['refreshed_at'] = Variable<DateTime>(refreshedAt);
    map['last_successful_refresh_at'] = Variable<DateTime>(
      lastSuccessfulRefreshAt,
    );
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || locale != null) {
      map['locale'] = Variable<String>(locale);
    }
    if (!nullToAbsent || timeZone != null) {
      map['time_zone'] = Variable<String>(timeZone);
    }
    if (!nullToAbsent || defaultPageSize != null) {
      map['default_page_size'] = Variable<int>(defaultPageSize);
    }
    if (!nullToAbsent || maximumPageSize != null) {
      map['maximum_page_size'] = Variable<int>(maximumPageSize);
    }
    if (!nullToAbsent || pickupEnabled != null) {
      map['pickup_enabled'] = Variable<bool>(pickupEnabled);
    }
    if (!nullToAbsent || deliveryEnabled != null) {
      map['delivery_enabled'] = Variable<bool>(deliveryEnabled);
    }
    if (!nullToAbsent || reservationEnabled != null) {
      map['reservation_enabled'] = Variable<bool>(reservationEnabled);
    }
    return map;
  }

  StorefrontCacheMetadataCompanion toCompanion(bool nullToAbsent) {
    return StorefrontCacheMetadataCompanion(
      shopSlug: Value(shopSlug),
      catalogVersion: Value(catalogVersion),
      refreshedAt: Value(refreshedAt),
      lastSuccessfulRefreshAt: Value(lastSuccessfulRefreshAt),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      locale: locale == null && nullToAbsent
          ? const Value.absent()
          : Value(locale),
      timeZone: timeZone == null && nullToAbsent
          ? const Value.absent()
          : Value(timeZone),
      defaultPageSize: defaultPageSize == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultPageSize),
      maximumPageSize: maximumPageSize == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumPageSize),
      pickupEnabled: pickupEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(pickupEnabled),
      deliveryEnabled: deliveryEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryEnabled),
      reservationEnabled: reservationEnabled == null && nullToAbsent
          ? const Value.absent()
          : Value(reservationEnabled),
    );
  }

  factory StorefrontCacheMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorefrontCacheMetadataRow(
      shopSlug: serializer.fromJson<String>(json['shopSlug']),
      catalogVersion: serializer.fromJson<int>(json['catalogVersion']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
      lastSuccessfulRefreshAt: serializer.fromJson<DateTime>(
        json['lastSuccessfulRefreshAt'],
      ),
      currency: serializer.fromJson<String?>(json['currency']),
      locale: serializer.fromJson<String?>(json['locale']),
      timeZone: serializer.fromJson<String?>(json['timeZone']),
      defaultPageSize: serializer.fromJson<int?>(json['defaultPageSize']),
      maximumPageSize: serializer.fromJson<int?>(json['maximumPageSize']),
      pickupEnabled: serializer.fromJson<bool?>(json['pickupEnabled']),
      deliveryEnabled: serializer.fromJson<bool?>(json['deliveryEnabled']),
      reservationEnabled: serializer.fromJson<bool?>(
        json['reservationEnabled'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopSlug': serializer.toJson<String>(shopSlug),
      'catalogVersion': serializer.toJson<int>(catalogVersion),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
      'lastSuccessfulRefreshAt': serializer.toJson<DateTime>(
        lastSuccessfulRefreshAt,
      ),
      'currency': serializer.toJson<String?>(currency),
      'locale': serializer.toJson<String?>(locale),
      'timeZone': serializer.toJson<String?>(timeZone),
      'defaultPageSize': serializer.toJson<int?>(defaultPageSize),
      'maximumPageSize': serializer.toJson<int?>(maximumPageSize),
      'pickupEnabled': serializer.toJson<bool?>(pickupEnabled),
      'deliveryEnabled': serializer.toJson<bool?>(deliveryEnabled),
      'reservationEnabled': serializer.toJson<bool?>(reservationEnabled),
    };
  }

  StorefrontCacheMetadataRow copyWith({
    String? shopSlug,
    int? catalogVersion,
    DateTime? refreshedAt,
    DateTime? lastSuccessfulRefreshAt,
    Value<String?> currency = const Value.absent(),
    Value<String?> locale = const Value.absent(),
    Value<String?> timeZone = const Value.absent(),
    Value<int?> defaultPageSize = const Value.absent(),
    Value<int?> maximumPageSize = const Value.absent(),
    Value<bool?> pickupEnabled = const Value.absent(),
    Value<bool?> deliveryEnabled = const Value.absent(),
    Value<bool?> reservationEnabled = const Value.absent(),
  }) => StorefrontCacheMetadataRow(
    shopSlug: shopSlug ?? this.shopSlug,
    catalogVersion: catalogVersion ?? this.catalogVersion,
    refreshedAt: refreshedAt ?? this.refreshedAt,
    lastSuccessfulRefreshAt:
        lastSuccessfulRefreshAt ?? this.lastSuccessfulRefreshAt,
    currency: currency.present ? currency.value : this.currency,
    locale: locale.present ? locale.value : this.locale,
    timeZone: timeZone.present ? timeZone.value : this.timeZone,
    defaultPageSize: defaultPageSize.present
        ? defaultPageSize.value
        : this.defaultPageSize,
    maximumPageSize: maximumPageSize.present
        ? maximumPageSize.value
        : this.maximumPageSize,
    pickupEnabled: pickupEnabled.present
        ? pickupEnabled.value
        : this.pickupEnabled,
    deliveryEnabled: deliveryEnabled.present
        ? deliveryEnabled.value
        : this.deliveryEnabled,
    reservationEnabled: reservationEnabled.present
        ? reservationEnabled.value
        : this.reservationEnabled,
  );
  StorefrontCacheMetadataRow copyWithCompanion(
    StorefrontCacheMetadataCompanion data,
  ) {
    return StorefrontCacheMetadataRow(
      shopSlug: data.shopSlug.present ? data.shopSlug.value : this.shopSlug,
      catalogVersion: data.catalogVersion.present
          ? data.catalogVersion.value
          : this.catalogVersion,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
      lastSuccessfulRefreshAt: data.lastSuccessfulRefreshAt.present
          ? data.lastSuccessfulRefreshAt.value
          : this.lastSuccessfulRefreshAt,
      currency: data.currency.present ? data.currency.value : this.currency,
      locale: data.locale.present ? data.locale.value : this.locale,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      defaultPageSize: data.defaultPageSize.present
          ? data.defaultPageSize.value
          : this.defaultPageSize,
      maximumPageSize: data.maximumPageSize.present
          ? data.maximumPageSize.value
          : this.maximumPageSize,
      pickupEnabled: data.pickupEnabled.present
          ? data.pickupEnabled.value
          : this.pickupEnabled,
      deliveryEnabled: data.deliveryEnabled.present
          ? data.deliveryEnabled.value
          : this.deliveryEnabled,
      reservationEnabled: data.reservationEnabled.present
          ? data.reservationEnabled.value
          : this.reservationEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorefrontCacheMetadataRow(')
          ..write('shopSlug: $shopSlug, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('lastSuccessfulRefreshAt: $lastSuccessfulRefreshAt, ')
          ..write('currency: $currency, ')
          ..write('locale: $locale, ')
          ..write('timeZone: $timeZone, ')
          ..write('defaultPageSize: $defaultPageSize, ')
          ..write('maximumPageSize: $maximumPageSize, ')
          ..write('pickupEnabled: $pickupEnabled, ')
          ..write('deliveryEnabled: $deliveryEnabled, ')
          ..write('reservationEnabled: $reservationEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    shopSlug,
    catalogVersion,
    refreshedAt,
    lastSuccessfulRefreshAt,
    currency,
    locale,
    timeZone,
    defaultPageSize,
    maximumPageSize,
    pickupEnabled,
    deliveryEnabled,
    reservationEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorefrontCacheMetadataRow &&
          other.shopSlug == this.shopSlug &&
          other.catalogVersion == this.catalogVersion &&
          other.refreshedAt == this.refreshedAt &&
          other.lastSuccessfulRefreshAt == this.lastSuccessfulRefreshAt &&
          other.currency == this.currency &&
          other.locale == this.locale &&
          other.timeZone == this.timeZone &&
          other.defaultPageSize == this.defaultPageSize &&
          other.maximumPageSize == this.maximumPageSize &&
          other.pickupEnabled == this.pickupEnabled &&
          other.deliveryEnabled == this.deliveryEnabled &&
          other.reservationEnabled == this.reservationEnabled);
}

class StorefrontCacheMetadataCompanion
    extends UpdateCompanion<StorefrontCacheMetadataRow> {
  final Value<String> shopSlug;
  final Value<int> catalogVersion;
  final Value<DateTime> refreshedAt;
  final Value<DateTime> lastSuccessfulRefreshAt;
  final Value<String?> currency;
  final Value<String?> locale;
  final Value<String?> timeZone;
  final Value<int?> defaultPageSize;
  final Value<int?> maximumPageSize;
  final Value<bool?> pickupEnabled;
  final Value<bool?> deliveryEnabled;
  final Value<bool?> reservationEnabled;
  final Value<int> rowid;
  const StorefrontCacheMetadataCompanion({
    this.shopSlug = const Value.absent(),
    this.catalogVersion = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.lastSuccessfulRefreshAt = const Value.absent(),
    this.currency = const Value.absent(),
    this.locale = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.defaultPageSize = const Value.absent(),
    this.maximumPageSize = const Value.absent(),
    this.pickupEnabled = const Value.absent(),
    this.deliveryEnabled = const Value.absent(),
    this.reservationEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorefrontCacheMetadataCompanion.insert({
    required String shopSlug,
    required int catalogVersion,
    required DateTime refreshedAt,
    required DateTime lastSuccessfulRefreshAt,
    this.currency = const Value.absent(),
    this.locale = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.defaultPageSize = const Value.absent(),
    this.maximumPageSize = const Value.absent(),
    this.pickupEnabled = const Value.absent(),
    this.deliveryEnabled = const Value.absent(),
    this.reservationEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : shopSlug = Value(shopSlug),
       catalogVersion = Value(catalogVersion),
       refreshedAt = Value(refreshedAt),
       lastSuccessfulRefreshAt = Value(lastSuccessfulRefreshAt);
  static Insertable<StorefrontCacheMetadataRow> custom({
    Expression<String>? shopSlug,
    Expression<int>? catalogVersion,
    Expression<DateTime>? refreshedAt,
    Expression<DateTime>? lastSuccessfulRefreshAt,
    Expression<String>? currency,
    Expression<String>? locale,
    Expression<String>? timeZone,
    Expression<int>? defaultPageSize,
    Expression<int>? maximumPageSize,
    Expression<bool>? pickupEnabled,
    Expression<bool>? deliveryEnabled,
    Expression<bool>? reservationEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopSlug != null) 'shop_slug': shopSlug,
      if (catalogVersion != null) 'catalog_version': catalogVersion,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (lastSuccessfulRefreshAt != null)
        'last_successful_refresh_at': lastSuccessfulRefreshAt,
      if (currency != null) 'currency': currency,
      if (locale != null) 'locale': locale,
      if (timeZone != null) 'time_zone': timeZone,
      if (defaultPageSize != null) 'default_page_size': defaultPageSize,
      if (maximumPageSize != null) 'maximum_page_size': maximumPageSize,
      if (pickupEnabled != null) 'pickup_enabled': pickupEnabled,
      if (deliveryEnabled != null) 'delivery_enabled': deliveryEnabled,
      if (reservationEnabled != null) 'reservation_enabled': reservationEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorefrontCacheMetadataCompanion copyWith({
    Value<String>? shopSlug,
    Value<int>? catalogVersion,
    Value<DateTime>? refreshedAt,
    Value<DateTime>? lastSuccessfulRefreshAt,
    Value<String?>? currency,
    Value<String?>? locale,
    Value<String?>? timeZone,
    Value<int?>? defaultPageSize,
    Value<int?>? maximumPageSize,
    Value<bool?>? pickupEnabled,
    Value<bool?>? deliveryEnabled,
    Value<bool?>? reservationEnabled,
    Value<int>? rowid,
  }) {
    return StorefrontCacheMetadataCompanion(
      shopSlug: shopSlug ?? this.shopSlug,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      lastSuccessfulRefreshAt:
          lastSuccessfulRefreshAt ?? this.lastSuccessfulRefreshAt,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      timeZone: timeZone ?? this.timeZone,
      defaultPageSize: defaultPageSize ?? this.defaultPageSize,
      maximumPageSize: maximumPageSize ?? this.maximumPageSize,
      pickupEnabled: pickupEnabled ?? this.pickupEnabled,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      reservationEnabled: reservationEnabled ?? this.reservationEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopSlug.present) {
      map['shop_slug'] = Variable<String>(shopSlug.value);
    }
    if (catalogVersion.present) {
      map['catalog_version'] = Variable<int>(catalogVersion.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<DateTime>(refreshedAt.value);
    }
    if (lastSuccessfulRefreshAt.present) {
      map['last_successful_refresh_at'] = Variable<DateTime>(
        lastSuccessfulRefreshAt.value,
      );
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (defaultPageSize.present) {
      map['default_page_size'] = Variable<int>(defaultPageSize.value);
    }
    if (maximumPageSize.present) {
      map['maximum_page_size'] = Variable<int>(maximumPageSize.value);
    }
    if (pickupEnabled.present) {
      map['pickup_enabled'] = Variable<bool>(pickupEnabled.value);
    }
    if (deliveryEnabled.present) {
      map['delivery_enabled'] = Variable<bool>(deliveryEnabled.value);
    }
    if (reservationEnabled.present) {
      map['reservation_enabled'] = Variable<bool>(reservationEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorefrontCacheMetadataCompanion(')
          ..write('shopSlug: $shopSlug, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('lastSuccessfulRefreshAt: $lastSuccessfulRefreshAt, ')
          ..write('currency: $currency, ')
          ..write('locale: $locale, ')
          ..write('timeZone: $timeZone, ')
          ..write('defaultPageSize: $defaultPageSize, ')
          ..write('maximumPageSize: $maximumPageSize, ')
          ..write('pickupEnabled: $pickupEnabled, ')
          ..write('deliveryEnabled: $deliveryEnabled, ')
          ..write('reservationEnabled: $reservationEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStorefrontCategoriesTable extends CachedStorefrontCategories
    with
        TableInfo<
          $CachedStorefrontCategoriesTable,
          CachedStorefrontCategoryRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStorefrontCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopSlugMeta = const VerificationMeta(
    'shopSlug',
  );
  @override
  late final GeneratedColumn<String> shopSlug = GeneratedColumn<String>(
    'shop_slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortRankMeta = const VerificationMeta(
    'sortRank',
  );
  @override
  late final GeneratedColumn<int> sortRank = GeneratedColumn<int>(
    'sort_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogVersionMeta = const VerificationMeta(
    'catalogVersion',
  );
  @override
  late final GeneratedColumn<int> catalogVersion = GeneratedColumn<int>(
    'catalog_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    shopSlug,
    categoryId,
    slug,
    name,
    sortRank,
    catalogVersion,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_storefront_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStorefrontCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_slug')) {
      context.handle(
        _shopSlugMeta,
        shopSlug.isAcceptableOrUnknown(data['shop_slug']!, _shopSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_shopSlugMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_rank')) {
      context.handle(
        _sortRankMeta,
        sortRank.isAcceptableOrUnknown(data['sort_rank']!, _sortRankMeta),
      );
    } else if (isInserting) {
      context.missing(_sortRankMeta);
    }
    if (data.containsKey('catalog_version')) {
      context.handle(
        _catalogVersionMeta,
        catalogVersion.isAcceptableOrUnknown(
          data['catalog_version']!,
          _catalogVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogVersionMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopSlug, categoryId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {shopSlug, slug},
  ];
  @override
  CachedStorefrontCategoryRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStorefrontCategoryRow(
      shopSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_slug'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_rank'],
      )!,
      catalogVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_version'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedStorefrontCategoriesTable createAlias(String alias) {
    return $CachedStorefrontCategoriesTable(attachedDatabase, alias);
  }
}

class CachedStorefrontCategoryRow extends DataClass
    implements Insertable<CachedStorefrontCategoryRow> {
  final String shopSlug;
  final String categoryId;
  final String slug;
  final String name;
  final int sortRank;
  final int catalogVersion;
  final DateTime cachedAt;
  const CachedStorefrontCategoryRow({
    required this.shopSlug,
    required this.categoryId,
    required this.slug,
    required this.name,
    required this.sortRank,
    required this.catalogVersion,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_slug'] = Variable<String>(shopSlug);
    map['category_id'] = Variable<String>(categoryId);
    map['slug'] = Variable<String>(slug);
    map['name'] = Variable<String>(name);
    map['sort_rank'] = Variable<int>(sortRank);
    map['catalog_version'] = Variable<int>(catalogVersion);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedStorefrontCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedStorefrontCategoriesCompanion(
      shopSlug: Value(shopSlug),
      categoryId: Value(categoryId),
      slug: Value(slug),
      name: Value(name),
      sortRank: Value(sortRank),
      catalogVersion: Value(catalogVersion),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedStorefrontCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStorefrontCategoryRow(
      shopSlug: serializer.fromJson<String>(json['shopSlug']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      slug: serializer.fromJson<String>(json['slug']),
      name: serializer.fromJson<String>(json['name']),
      sortRank: serializer.fromJson<int>(json['sortRank']),
      catalogVersion: serializer.fromJson<int>(json['catalogVersion']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopSlug': serializer.toJson<String>(shopSlug),
      'categoryId': serializer.toJson<String>(categoryId),
      'slug': serializer.toJson<String>(slug),
      'name': serializer.toJson<String>(name),
      'sortRank': serializer.toJson<int>(sortRank),
      'catalogVersion': serializer.toJson<int>(catalogVersion),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedStorefrontCategoryRow copyWith({
    String? shopSlug,
    String? categoryId,
    String? slug,
    String? name,
    int? sortRank,
    int? catalogVersion,
    DateTime? cachedAt,
  }) => CachedStorefrontCategoryRow(
    shopSlug: shopSlug ?? this.shopSlug,
    categoryId: categoryId ?? this.categoryId,
    slug: slug ?? this.slug,
    name: name ?? this.name,
    sortRank: sortRank ?? this.sortRank,
    catalogVersion: catalogVersion ?? this.catalogVersion,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedStorefrontCategoryRow copyWithCompanion(
    CachedStorefrontCategoriesCompanion data,
  ) {
    return CachedStorefrontCategoryRow(
      shopSlug: data.shopSlug.present ? data.shopSlug.value : this.shopSlug,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      slug: data.slug.present ? data.slug.value : this.slug,
      name: data.name.present ? data.name.value : this.name,
      sortRank: data.sortRank.present ? data.sortRank.value : this.sortRank,
      catalogVersion: data.catalogVersion.present
          ? data.catalogVersion.value
          : this.catalogVersion,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStorefrontCategoryRow(')
          ..write('shopSlug: $shopSlug, ')
          ..write('categoryId: $categoryId, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('sortRank: $sortRank, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    shopSlug,
    categoryId,
    slug,
    name,
    sortRank,
    catalogVersion,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStorefrontCategoryRow &&
          other.shopSlug == this.shopSlug &&
          other.categoryId == this.categoryId &&
          other.slug == this.slug &&
          other.name == this.name &&
          other.sortRank == this.sortRank &&
          other.catalogVersion == this.catalogVersion &&
          other.cachedAt == this.cachedAt);
}

class CachedStorefrontCategoriesCompanion
    extends UpdateCompanion<CachedStorefrontCategoryRow> {
  final Value<String> shopSlug;
  final Value<String> categoryId;
  final Value<String> slug;
  final Value<String> name;
  final Value<int> sortRank;
  final Value<int> catalogVersion;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedStorefrontCategoriesCompanion({
    this.shopSlug = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.slug = const Value.absent(),
    this.name = const Value.absent(),
    this.sortRank = const Value.absent(),
    this.catalogVersion = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStorefrontCategoriesCompanion.insert({
    required String shopSlug,
    required String categoryId,
    required String slug,
    required String name,
    required int sortRank,
    required int catalogVersion,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : shopSlug = Value(shopSlug),
       categoryId = Value(categoryId),
       slug = Value(slug),
       name = Value(name),
       sortRank = Value(sortRank),
       catalogVersion = Value(catalogVersion),
       cachedAt = Value(cachedAt);
  static Insertable<CachedStorefrontCategoryRow> custom({
    Expression<String>? shopSlug,
    Expression<String>? categoryId,
    Expression<String>? slug,
    Expression<String>? name,
    Expression<int>? sortRank,
    Expression<int>? catalogVersion,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopSlug != null) 'shop_slug': shopSlug,
      if (categoryId != null) 'category_id': categoryId,
      if (slug != null) 'slug': slug,
      if (name != null) 'name': name,
      if (sortRank != null) 'sort_rank': sortRank,
      if (catalogVersion != null) 'catalog_version': catalogVersion,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStorefrontCategoriesCompanion copyWith({
    Value<String>? shopSlug,
    Value<String>? categoryId,
    Value<String>? slug,
    Value<String>? name,
    Value<int>? sortRank,
    Value<int>? catalogVersion,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedStorefrontCategoriesCompanion(
      shopSlug: shopSlug ?? this.shopSlug,
      categoryId: categoryId ?? this.categoryId,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      sortRank: sortRank ?? this.sortRank,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopSlug.present) {
      map['shop_slug'] = Variable<String>(shopSlug.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortRank.present) {
      map['sort_rank'] = Variable<int>(sortRank.value);
    }
    if (catalogVersion.present) {
      map['catalog_version'] = Variable<int>(catalogVersion.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStorefrontCategoriesCompanion(')
          ..write('shopSlug: $shopSlug, ')
          ..write('categoryId: $categoryId, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('sortRank: $sortRank, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStorefrontProductsTable extends CachedStorefrontProducts
    with TableInfo<$CachedStorefrontProductsTable, CachedStorefrontProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStorefrontProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopSlugMeta = const VerificationMeta(
    'shopSlug',
  );
  @override
  late final GeneratedColumn<String> shopSlug = GeneratedColumn<String>(
    'shop_slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicationIdMeta = const VerificationMeta(
    'publicationId',
  );
  @override
  late final GeneratedColumn<String> publicationId = GeneratedColumn<String>(
    'publication_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categorySlugMeta = const VerificationMeta(
    'categorySlug',
  );
  @override
  late final GeneratedColumn<String> categorySlug = GeneratedColumn<String>(
    'category_slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categorySortRankMeta = const VerificationMeta(
    'categorySortRank',
  );
  @override
  late final GeneratedColumn<int> categorySortRank = GeneratedColumn<int>(
    'category_sort_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _normalizedSearchTextMeta =
      const VerificationMeta('normalizedSearchText');
  @override
  late final GeneratedColumn<String> normalizedSearchText =
      GeneratedColumn<String>(
        'normalized_search_text',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1,
          maxTextLength: 640,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _priceClpMeta = const VerificationMeta(
    'priceClp',
  );
  @override
  late final GeneratedColumn<int> priceClp = GeneratedColumn<int>(
    'price_clp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compareAtPriceClpMeta = const VerificationMeta(
    'compareAtPriceClp',
  );
  @override
  late final GeneratedColumn<int> compareAtPriceClp = GeneratedColumn<int>(
    'compare_at_price_clp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discountBpsMeta = const VerificationMeta(
    'discountBps',
  );
  @override
  late final GeneratedColumn<int> discountBps = GeneratedColumn<int>(
    'discount_bps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promotionIdMeta = const VerificationMeta(
    'promotionId',
  );
  @override
  late final GeneratedColumn<String> promotionId = GeneratedColumn<String>(
    'promotion_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promotionNameMeta = const VerificationMeta(
    'promotionName',
  );
  @override
  late final GeneratedColumn<String> promotionName = GeneratedColumn<String>(
    'promotion_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promotionStartsAtMeta = const VerificationMeta(
    'promotionStartsAt',
  );
  @override
  late final GeneratedColumn<DateTime> promotionStartsAt =
      GeneratedColumn<DateTime>(
        'promotion_starts_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _promotionEndsAtMeta = const VerificationMeta(
    'promotionEndsAt',
  );
  @override
  late final GeneratedColumn<DateTime> promotionEndsAt =
      GeneratedColumn<DateTime>(
        'promotion_ends_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _featuredMeta = const VerificationMeta(
    'featured',
  );
  @override
  late final GeneratedColumn<bool> featured = GeneratedColumn<bool>(
    'featured',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("featured" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sortRankMeta = const VerificationMeta(
    'sortRank',
  );
  @override
  late final GeneratedColumn<int> sortRank = GeneratedColumn<int>(
    'sort_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  @override
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 8,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pickupEnabledMeta = const VerificationMeta(
    'pickupEnabled',
  );
  @override
  late final GeneratedColumn<bool> pickupEnabled = GeneratedColumn<bool>(
    'pickup_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pickup_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _deliveryEnabledMeta = const VerificationMeta(
    'deliveryEnabled',
  );
  @override
  late final GeneratedColumn<bool> deliveryEnabled = GeneratedColumn<bool>(
    'delivery_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("delivery_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _reservationEnabledMeta =
      const VerificationMeta('reservationEnabled');
  @override
  late final GeneratedColumn<bool> reservationEnabled = GeneratedColumn<bool>(
    'reservation_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reservation_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _imageVersionMeta = const VerificationMeta(
    'imageVersion',
  );
  @override
  late final GeneratedColumn<String> imageVersion = GeneratedColumn<String>(
    'image_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageThumbUrlMeta = const VerificationMeta(
    'imageThumbUrl',
  );
  @override
  late final GeneratedColumn<String> imageThumbUrl = GeneratedColumn<String>(
    'image_thumb_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageCardUrlMeta = const VerificationMeta(
    'imageCardUrl',
  );
  @override
  late final GeneratedColumn<String> imageCardUrl = GeneratedColumn<String>(
    'image_card_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageDetailUrlMeta = const VerificationMeta(
    'imageDetailUrl',
  );
  @override
  late final GeneratedColumn<String> imageDetailUrl = GeneratedColumn<String>(
    'image_detail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageSha256Meta = const VerificationMeta(
    'imageSha256',
  );
  @override
  late final GeneratedColumn<String> imageSha256 = GeneratedColumn<String>(
    'image_sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catalogVersionMeta = const VerificationMeta(
    'catalogVersion',
  );
  @override
  late final GeneratedColumn<int> catalogVersion = GeneratedColumn<int>(
    'catalog_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    shopSlug,
    publicationId,
    categoryId,
    categorySlug,
    categoryName,
    categorySortRank,
    name,
    description,
    brand,
    normalizedSearchText,
    priceClp,
    compareAtPriceClp,
    discountBps,
    promotionId,
    promotionName,
    promotionStartsAt,
    promotionEndsAt,
    featured,
    sortRank,
    availability,
    pickupEnabled,
    deliveryEnabled,
    reservationEnabled,
    imageVersion,
    imageThumbUrl,
    imageCardUrl,
    imageDetailUrl,
    imageSha256,
    catalogVersion,
    publishedAt,
    updatedAt,
    cachedAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_storefront_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStorefrontProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_slug')) {
      context.handle(
        _shopSlugMeta,
        shopSlug.isAcceptableOrUnknown(data['shop_slug']!, _shopSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_shopSlugMeta);
    }
    if (data.containsKey('publication_id')) {
      context.handle(
        _publicationIdMeta,
        publicationId.isAcceptableOrUnknown(
          data['publication_id']!,
          _publicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicationIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('category_slug')) {
      context.handle(
        _categorySlugMeta,
        categorySlug.isAcceptableOrUnknown(
          data['category_slug']!,
          _categorySlugMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categorySlugMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
    }
    if (data.containsKey('category_sort_rank')) {
      context.handle(
        _categorySortRankMeta,
        categorySortRank.isAcceptableOrUnknown(
          data['category_sort_rank']!,
          _categorySortRankMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categorySortRankMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('normalized_search_text')) {
      context.handle(
        _normalizedSearchTextMeta,
        normalizedSearchText.isAcceptableOrUnknown(
          data['normalized_search_text']!,
          _normalizedSearchTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedSearchTextMeta);
    }
    if (data.containsKey('price_clp')) {
      context.handle(
        _priceClpMeta,
        priceClp.isAcceptableOrUnknown(data['price_clp']!, _priceClpMeta),
      );
    } else if (isInserting) {
      context.missing(_priceClpMeta);
    }
    if (data.containsKey('compare_at_price_clp')) {
      context.handle(
        _compareAtPriceClpMeta,
        compareAtPriceClp.isAcceptableOrUnknown(
          data['compare_at_price_clp']!,
          _compareAtPriceClpMeta,
        ),
      );
    }
    if (data.containsKey('discount_bps')) {
      context.handle(
        _discountBpsMeta,
        discountBps.isAcceptableOrUnknown(
          data['discount_bps']!,
          _discountBpsMeta,
        ),
      );
    }
    if (data.containsKey('promotion_id')) {
      context.handle(
        _promotionIdMeta,
        promotionId.isAcceptableOrUnknown(
          data['promotion_id']!,
          _promotionIdMeta,
        ),
      );
    }
    if (data.containsKey('promotion_name')) {
      context.handle(
        _promotionNameMeta,
        promotionName.isAcceptableOrUnknown(
          data['promotion_name']!,
          _promotionNameMeta,
        ),
      );
    }
    if (data.containsKey('promotion_starts_at')) {
      context.handle(
        _promotionStartsAtMeta,
        promotionStartsAt.isAcceptableOrUnknown(
          data['promotion_starts_at']!,
          _promotionStartsAtMeta,
        ),
      );
    }
    if (data.containsKey('promotion_ends_at')) {
      context.handle(
        _promotionEndsAtMeta,
        promotionEndsAt.isAcceptableOrUnknown(
          data['promotion_ends_at']!,
          _promotionEndsAtMeta,
        ),
      );
    }
    if (data.containsKey('featured')) {
      context.handle(
        _featuredMeta,
        featured.isAcceptableOrUnknown(data['featured']!, _featuredMeta),
      );
    } else if (isInserting) {
      context.missing(_featuredMeta);
    }
    if (data.containsKey('sort_rank')) {
      context.handle(
        _sortRankMeta,
        sortRank.isAcceptableOrUnknown(data['sort_rank']!, _sortRankMeta),
      );
    } else if (isInserting) {
      context.missing(_sortRankMeta);
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availabilityMeta);
    }
    if (data.containsKey('pickup_enabled')) {
      context.handle(
        _pickupEnabledMeta,
        pickupEnabled.isAcceptableOrUnknown(
          data['pickup_enabled']!,
          _pickupEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pickupEnabledMeta);
    }
    if (data.containsKey('delivery_enabled')) {
      context.handle(
        _deliveryEnabledMeta,
        deliveryEnabled.isAcceptableOrUnknown(
          data['delivery_enabled']!,
          _deliveryEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryEnabledMeta);
    }
    if (data.containsKey('reservation_enabled')) {
      context.handle(
        _reservationEnabledMeta,
        reservationEnabled.isAcceptableOrUnknown(
          data['reservation_enabled']!,
          _reservationEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reservationEnabledMeta);
    }
    if (data.containsKey('image_version')) {
      context.handle(
        _imageVersionMeta,
        imageVersion.isAcceptableOrUnknown(
          data['image_version']!,
          _imageVersionMeta,
        ),
      );
    }
    if (data.containsKey('image_thumb_url')) {
      context.handle(
        _imageThumbUrlMeta,
        imageThumbUrl.isAcceptableOrUnknown(
          data['image_thumb_url']!,
          _imageThumbUrlMeta,
        ),
      );
    }
    if (data.containsKey('image_card_url')) {
      context.handle(
        _imageCardUrlMeta,
        imageCardUrl.isAcceptableOrUnknown(
          data['image_card_url']!,
          _imageCardUrlMeta,
        ),
      );
    }
    if (data.containsKey('image_detail_url')) {
      context.handle(
        _imageDetailUrlMeta,
        imageDetailUrl.isAcceptableOrUnknown(
          data['image_detail_url']!,
          _imageDetailUrlMeta,
        ),
      );
    }
    if (data.containsKey('image_sha256')) {
      context.handle(
        _imageSha256Meta,
        imageSha256.isAcceptableOrUnknown(
          data['image_sha256']!,
          _imageSha256Meta,
        ),
      );
    }
    if (data.containsKey('catalog_version')) {
      context.handle(
        _catalogVersionMeta,
        catalogVersion.isAcceptableOrUnknown(
          data['catalog_version']!,
          _catalogVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogVersionMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopSlug, publicationId};
  @override
  CachedStorefrontProductRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStorefrontProductRow(
      shopSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_slug'],
      )!,
      publicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      categorySlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_slug'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      categorySortRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_sort_rank'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      normalizedSearchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_search_text'],
      )!,
      priceClp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_clp'],
      )!,
      compareAtPriceClp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}compare_at_price_clp'],
      ),
      discountBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_bps'],
      ),
      promotionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promotion_id'],
      ),
      promotionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promotion_name'],
      ),
      promotionStartsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}promotion_starts_at'],
      ),
      promotionEndsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}promotion_ends_at'],
      ),
      featured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}featured'],
      )!,
      sortRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_rank'],
      )!,
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      )!,
      pickupEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pickup_enabled'],
      )!,
      deliveryEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}delivery_enabled'],
      )!,
      reservationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reservation_enabled'],
      )!,
      imageVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_version'],
      ),
      imageThumbUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_thumb_url'],
      ),
      imageCardUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_card_url'],
      ),
      imageDetailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_detail_url'],
      ),
      imageSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_sha256'],
      ),
      catalogVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_version'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
    );
  }

  @override
  $CachedStorefrontProductsTable createAlias(String alias) {
    return $CachedStorefrontProductsTable(attachedDatabase, alias);
  }
}

class CachedStorefrontProductRow extends DataClass
    implements Insertable<CachedStorefrontProductRow> {
  final String shopSlug;
  final String publicationId;
  final String categoryId;
  final String categorySlug;
  final String categoryName;
  final int categorySortRank;
  final String name;
  final String? description;
  final String? brand;
  final String normalizedSearchText;
  final int priceClp;
  final int? compareAtPriceClp;
  final int? discountBps;
  final String? promotionId;
  final String? promotionName;
  final DateTime? promotionStartsAt;
  final DateTime? promotionEndsAt;
  final bool featured;
  final int sortRank;
  final String availability;
  final bool pickupEnabled;
  final bool deliveryEnabled;
  final bool reservationEnabled;
  final String? imageVersion;
  final String? imageThumbUrl;
  final String? imageCardUrl;
  final String? imageDetailUrl;
  final String? imageSha256;
  final int catalogVersion;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final DateTime cachedAt;
  final DateTime lastAccessedAt;
  const CachedStorefrontProductRow({
    required this.shopSlug,
    required this.publicationId,
    required this.categoryId,
    required this.categorySlug,
    required this.categoryName,
    required this.categorySortRank,
    required this.name,
    this.description,
    this.brand,
    required this.normalizedSearchText,
    required this.priceClp,
    this.compareAtPriceClp,
    this.discountBps,
    this.promotionId,
    this.promotionName,
    this.promotionStartsAt,
    this.promotionEndsAt,
    required this.featured,
    required this.sortRank,
    required this.availability,
    required this.pickupEnabled,
    required this.deliveryEnabled,
    required this.reservationEnabled,
    this.imageVersion,
    this.imageThumbUrl,
    this.imageCardUrl,
    this.imageDetailUrl,
    this.imageSha256,
    required this.catalogVersion,
    required this.publishedAt,
    required this.updatedAt,
    required this.cachedAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_slug'] = Variable<String>(shopSlug);
    map['publication_id'] = Variable<String>(publicationId);
    map['category_id'] = Variable<String>(categoryId);
    map['category_slug'] = Variable<String>(categorySlug);
    map['category_name'] = Variable<String>(categoryName);
    map['category_sort_rank'] = Variable<int>(categorySortRank);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['normalized_search_text'] = Variable<String>(normalizedSearchText);
    map['price_clp'] = Variable<int>(priceClp);
    if (!nullToAbsent || compareAtPriceClp != null) {
      map['compare_at_price_clp'] = Variable<int>(compareAtPriceClp);
    }
    if (!nullToAbsent || discountBps != null) {
      map['discount_bps'] = Variable<int>(discountBps);
    }
    if (!nullToAbsent || promotionId != null) {
      map['promotion_id'] = Variable<String>(promotionId);
    }
    if (!nullToAbsent || promotionName != null) {
      map['promotion_name'] = Variable<String>(promotionName);
    }
    if (!nullToAbsent || promotionStartsAt != null) {
      map['promotion_starts_at'] = Variable<DateTime>(promotionStartsAt);
    }
    if (!nullToAbsent || promotionEndsAt != null) {
      map['promotion_ends_at'] = Variable<DateTime>(promotionEndsAt);
    }
    map['featured'] = Variable<bool>(featured);
    map['sort_rank'] = Variable<int>(sortRank);
    map['availability'] = Variable<String>(availability);
    map['pickup_enabled'] = Variable<bool>(pickupEnabled);
    map['delivery_enabled'] = Variable<bool>(deliveryEnabled);
    map['reservation_enabled'] = Variable<bool>(reservationEnabled);
    if (!nullToAbsent || imageVersion != null) {
      map['image_version'] = Variable<String>(imageVersion);
    }
    if (!nullToAbsent || imageThumbUrl != null) {
      map['image_thumb_url'] = Variable<String>(imageThumbUrl);
    }
    if (!nullToAbsent || imageCardUrl != null) {
      map['image_card_url'] = Variable<String>(imageCardUrl);
    }
    if (!nullToAbsent || imageDetailUrl != null) {
      map['image_detail_url'] = Variable<String>(imageDetailUrl);
    }
    if (!nullToAbsent || imageSha256 != null) {
      map['image_sha256'] = Variable<String>(imageSha256);
    }
    map['catalog_version'] = Variable<int>(catalogVersion);
    map['published_at'] = Variable<DateTime>(publishedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  CachedStorefrontProductsCompanion toCompanion(bool nullToAbsent) {
    return CachedStorefrontProductsCompanion(
      shopSlug: Value(shopSlug),
      publicationId: Value(publicationId),
      categoryId: Value(categoryId),
      categorySlug: Value(categorySlug),
      categoryName: Value(categoryName),
      categorySortRank: Value(categorySortRank),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      normalizedSearchText: Value(normalizedSearchText),
      priceClp: Value(priceClp),
      compareAtPriceClp: compareAtPriceClp == null && nullToAbsent
          ? const Value.absent()
          : Value(compareAtPriceClp),
      discountBps: discountBps == null && nullToAbsent
          ? const Value.absent()
          : Value(discountBps),
      promotionId: promotionId == null && nullToAbsent
          ? const Value.absent()
          : Value(promotionId),
      promotionName: promotionName == null && nullToAbsent
          ? const Value.absent()
          : Value(promotionName),
      promotionStartsAt: promotionStartsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(promotionStartsAt),
      promotionEndsAt: promotionEndsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(promotionEndsAt),
      featured: Value(featured),
      sortRank: Value(sortRank),
      availability: Value(availability),
      pickupEnabled: Value(pickupEnabled),
      deliveryEnabled: Value(deliveryEnabled),
      reservationEnabled: Value(reservationEnabled),
      imageVersion: imageVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(imageVersion),
      imageThumbUrl: imageThumbUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageThumbUrl),
      imageCardUrl: imageCardUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageCardUrl),
      imageDetailUrl: imageDetailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageDetailUrl),
      imageSha256: imageSha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(imageSha256),
      catalogVersion: Value(catalogVersion),
      publishedAt: Value(publishedAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory CachedStorefrontProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStorefrontProductRow(
      shopSlug: serializer.fromJson<String>(json['shopSlug']),
      publicationId: serializer.fromJson<String>(json['publicationId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      categorySlug: serializer.fromJson<String>(json['categorySlug']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      categorySortRank: serializer.fromJson<int>(json['categorySortRank']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      brand: serializer.fromJson<String?>(json['brand']),
      normalizedSearchText: serializer.fromJson<String>(
        json['normalizedSearchText'],
      ),
      priceClp: serializer.fromJson<int>(json['priceClp']),
      compareAtPriceClp: serializer.fromJson<int?>(json['compareAtPriceClp']),
      discountBps: serializer.fromJson<int?>(json['discountBps']),
      promotionId: serializer.fromJson<String?>(json['promotionId']),
      promotionName: serializer.fromJson<String?>(json['promotionName']),
      promotionStartsAt: serializer.fromJson<DateTime?>(
        json['promotionStartsAt'],
      ),
      promotionEndsAt: serializer.fromJson<DateTime?>(json['promotionEndsAt']),
      featured: serializer.fromJson<bool>(json['featured']),
      sortRank: serializer.fromJson<int>(json['sortRank']),
      availability: serializer.fromJson<String>(json['availability']),
      pickupEnabled: serializer.fromJson<bool>(json['pickupEnabled']),
      deliveryEnabled: serializer.fromJson<bool>(json['deliveryEnabled']),
      reservationEnabled: serializer.fromJson<bool>(json['reservationEnabled']),
      imageVersion: serializer.fromJson<String?>(json['imageVersion']),
      imageThumbUrl: serializer.fromJson<String?>(json['imageThumbUrl']),
      imageCardUrl: serializer.fromJson<String?>(json['imageCardUrl']),
      imageDetailUrl: serializer.fromJson<String?>(json['imageDetailUrl']),
      imageSha256: serializer.fromJson<String?>(json['imageSha256']),
      catalogVersion: serializer.fromJson<int>(json['catalogVersion']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopSlug': serializer.toJson<String>(shopSlug),
      'publicationId': serializer.toJson<String>(publicationId),
      'categoryId': serializer.toJson<String>(categoryId),
      'categorySlug': serializer.toJson<String>(categorySlug),
      'categoryName': serializer.toJson<String>(categoryName),
      'categorySortRank': serializer.toJson<int>(categorySortRank),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'brand': serializer.toJson<String?>(brand),
      'normalizedSearchText': serializer.toJson<String>(normalizedSearchText),
      'priceClp': serializer.toJson<int>(priceClp),
      'compareAtPriceClp': serializer.toJson<int?>(compareAtPriceClp),
      'discountBps': serializer.toJson<int?>(discountBps),
      'promotionId': serializer.toJson<String?>(promotionId),
      'promotionName': serializer.toJson<String?>(promotionName),
      'promotionStartsAt': serializer.toJson<DateTime?>(promotionStartsAt),
      'promotionEndsAt': serializer.toJson<DateTime?>(promotionEndsAt),
      'featured': serializer.toJson<bool>(featured),
      'sortRank': serializer.toJson<int>(sortRank),
      'availability': serializer.toJson<String>(availability),
      'pickupEnabled': serializer.toJson<bool>(pickupEnabled),
      'deliveryEnabled': serializer.toJson<bool>(deliveryEnabled),
      'reservationEnabled': serializer.toJson<bool>(reservationEnabled),
      'imageVersion': serializer.toJson<String?>(imageVersion),
      'imageThumbUrl': serializer.toJson<String?>(imageThumbUrl),
      'imageCardUrl': serializer.toJson<String?>(imageCardUrl),
      'imageDetailUrl': serializer.toJson<String?>(imageDetailUrl),
      'imageSha256': serializer.toJson<String?>(imageSha256),
      'catalogVersion': serializer.toJson<int>(catalogVersion),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  CachedStorefrontProductRow copyWith({
    String? shopSlug,
    String? publicationId,
    String? categoryId,
    String? categorySlug,
    String? categoryName,
    int? categorySortRank,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    String? normalizedSearchText,
    int? priceClp,
    Value<int?> compareAtPriceClp = const Value.absent(),
    Value<int?> discountBps = const Value.absent(),
    Value<String?> promotionId = const Value.absent(),
    Value<String?> promotionName = const Value.absent(),
    Value<DateTime?> promotionStartsAt = const Value.absent(),
    Value<DateTime?> promotionEndsAt = const Value.absent(),
    bool? featured,
    int? sortRank,
    String? availability,
    bool? pickupEnabled,
    bool? deliveryEnabled,
    bool? reservationEnabled,
    Value<String?> imageVersion = const Value.absent(),
    Value<String?> imageThumbUrl = const Value.absent(),
    Value<String?> imageCardUrl = const Value.absent(),
    Value<String?> imageDetailUrl = const Value.absent(),
    Value<String?> imageSha256 = const Value.absent(),
    int? catalogVersion,
    DateTime? publishedAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
    DateTime? lastAccessedAt,
  }) => CachedStorefrontProductRow(
    shopSlug: shopSlug ?? this.shopSlug,
    publicationId: publicationId ?? this.publicationId,
    categoryId: categoryId ?? this.categoryId,
    categorySlug: categorySlug ?? this.categorySlug,
    categoryName: categoryName ?? this.categoryName,
    categorySortRank: categorySortRank ?? this.categorySortRank,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    brand: brand.present ? brand.value : this.brand,
    normalizedSearchText: normalizedSearchText ?? this.normalizedSearchText,
    priceClp: priceClp ?? this.priceClp,
    compareAtPriceClp: compareAtPriceClp.present
        ? compareAtPriceClp.value
        : this.compareAtPriceClp,
    discountBps: discountBps.present ? discountBps.value : this.discountBps,
    promotionId: promotionId.present ? promotionId.value : this.promotionId,
    promotionName: promotionName.present
        ? promotionName.value
        : this.promotionName,
    promotionStartsAt: promotionStartsAt.present
        ? promotionStartsAt.value
        : this.promotionStartsAt,
    promotionEndsAt: promotionEndsAt.present
        ? promotionEndsAt.value
        : this.promotionEndsAt,
    featured: featured ?? this.featured,
    sortRank: sortRank ?? this.sortRank,
    availability: availability ?? this.availability,
    pickupEnabled: pickupEnabled ?? this.pickupEnabled,
    deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
    reservationEnabled: reservationEnabled ?? this.reservationEnabled,
    imageVersion: imageVersion.present ? imageVersion.value : this.imageVersion,
    imageThumbUrl: imageThumbUrl.present
        ? imageThumbUrl.value
        : this.imageThumbUrl,
    imageCardUrl: imageCardUrl.present ? imageCardUrl.value : this.imageCardUrl,
    imageDetailUrl: imageDetailUrl.present
        ? imageDetailUrl.value
        : this.imageDetailUrl,
    imageSha256: imageSha256.present ? imageSha256.value : this.imageSha256,
    catalogVersion: catalogVersion ?? this.catalogVersion,
    publishedAt: publishedAt ?? this.publishedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  CachedStorefrontProductRow copyWithCompanion(
    CachedStorefrontProductsCompanion data,
  ) {
    return CachedStorefrontProductRow(
      shopSlug: data.shopSlug.present ? data.shopSlug.value : this.shopSlug,
      publicationId: data.publicationId.present
          ? data.publicationId.value
          : this.publicationId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categorySlug: data.categorySlug.present
          ? data.categorySlug.value
          : this.categorySlug,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categorySortRank: data.categorySortRank.present
          ? data.categorySortRank.value
          : this.categorySortRank,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      brand: data.brand.present ? data.brand.value : this.brand,
      normalizedSearchText: data.normalizedSearchText.present
          ? data.normalizedSearchText.value
          : this.normalizedSearchText,
      priceClp: data.priceClp.present ? data.priceClp.value : this.priceClp,
      compareAtPriceClp: data.compareAtPriceClp.present
          ? data.compareAtPriceClp.value
          : this.compareAtPriceClp,
      discountBps: data.discountBps.present
          ? data.discountBps.value
          : this.discountBps,
      promotionId: data.promotionId.present
          ? data.promotionId.value
          : this.promotionId,
      promotionName: data.promotionName.present
          ? data.promotionName.value
          : this.promotionName,
      promotionStartsAt: data.promotionStartsAt.present
          ? data.promotionStartsAt.value
          : this.promotionStartsAt,
      promotionEndsAt: data.promotionEndsAt.present
          ? data.promotionEndsAt.value
          : this.promotionEndsAt,
      featured: data.featured.present ? data.featured.value : this.featured,
      sortRank: data.sortRank.present ? data.sortRank.value : this.sortRank,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
      pickupEnabled: data.pickupEnabled.present
          ? data.pickupEnabled.value
          : this.pickupEnabled,
      deliveryEnabled: data.deliveryEnabled.present
          ? data.deliveryEnabled.value
          : this.deliveryEnabled,
      reservationEnabled: data.reservationEnabled.present
          ? data.reservationEnabled.value
          : this.reservationEnabled,
      imageVersion: data.imageVersion.present
          ? data.imageVersion.value
          : this.imageVersion,
      imageThumbUrl: data.imageThumbUrl.present
          ? data.imageThumbUrl.value
          : this.imageThumbUrl,
      imageCardUrl: data.imageCardUrl.present
          ? data.imageCardUrl.value
          : this.imageCardUrl,
      imageDetailUrl: data.imageDetailUrl.present
          ? data.imageDetailUrl.value
          : this.imageDetailUrl,
      imageSha256: data.imageSha256.present
          ? data.imageSha256.value
          : this.imageSha256,
      catalogVersion: data.catalogVersion.present
          ? data.catalogVersion.value
          : this.catalogVersion,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStorefrontProductRow(')
          ..write('shopSlug: $shopSlug, ')
          ..write('publicationId: $publicationId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('categoryName: $categoryName, ')
          ..write('categorySortRank: $categorySortRank, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('brand: $brand, ')
          ..write('normalizedSearchText: $normalizedSearchText, ')
          ..write('priceClp: $priceClp, ')
          ..write('compareAtPriceClp: $compareAtPriceClp, ')
          ..write('discountBps: $discountBps, ')
          ..write('promotionId: $promotionId, ')
          ..write('promotionName: $promotionName, ')
          ..write('promotionStartsAt: $promotionStartsAt, ')
          ..write('promotionEndsAt: $promotionEndsAt, ')
          ..write('featured: $featured, ')
          ..write('sortRank: $sortRank, ')
          ..write('availability: $availability, ')
          ..write('pickupEnabled: $pickupEnabled, ')
          ..write('deliveryEnabled: $deliveryEnabled, ')
          ..write('reservationEnabled: $reservationEnabled, ')
          ..write('imageVersion: $imageVersion, ')
          ..write('imageThumbUrl: $imageThumbUrl, ')
          ..write('imageCardUrl: $imageCardUrl, ')
          ..write('imageDetailUrl: $imageDetailUrl, ')
          ..write('imageSha256: $imageSha256, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    shopSlug,
    publicationId,
    categoryId,
    categorySlug,
    categoryName,
    categorySortRank,
    name,
    description,
    brand,
    normalizedSearchText,
    priceClp,
    compareAtPriceClp,
    discountBps,
    promotionId,
    promotionName,
    promotionStartsAt,
    promotionEndsAt,
    featured,
    sortRank,
    availability,
    pickupEnabled,
    deliveryEnabled,
    reservationEnabled,
    imageVersion,
    imageThumbUrl,
    imageCardUrl,
    imageDetailUrl,
    imageSha256,
    catalogVersion,
    publishedAt,
    updatedAt,
    cachedAt,
    lastAccessedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStorefrontProductRow &&
          other.shopSlug == this.shopSlug &&
          other.publicationId == this.publicationId &&
          other.categoryId == this.categoryId &&
          other.categorySlug == this.categorySlug &&
          other.categoryName == this.categoryName &&
          other.categorySortRank == this.categorySortRank &&
          other.name == this.name &&
          other.description == this.description &&
          other.brand == this.brand &&
          other.normalizedSearchText == this.normalizedSearchText &&
          other.priceClp == this.priceClp &&
          other.compareAtPriceClp == this.compareAtPriceClp &&
          other.discountBps == this.discountBps &&
          other.promotionId == this.promotionId &&
          other.promotionName == this.promotionName &&
          other.promotionStartsAt == this.promotionStartsAt &&
          other.promotionEndsAt == this.promotionEndsAt &&
          other.featured == this.featured &&
          other.sortRank == this.sortRank &&
          other.availability == this.availability &&
          other.pickupEnabled == this.pickupEnabled &&
          other.deliveryEnabled == this.deliveryEnabled &&
          other.reservationEnabled == this.reservationEnabled &&
          other.imageVersion == this.imageVersion &&
          other.imageThumbUrl == this.imageThumbUrl &&
          other.imageCardUrl == this.imageCardUrl &&
          other.imageDetailUrl == this.imageDetailUrl &&
          other.imageSha256 == this.imageSha256 &&
          other.catalogVersion == this.catalogVersion &&
          other.publishedAt == this.publishedAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class CachedStorefrontProductsCompanion
    extends UpdateCompanion<CachedStorefrontProductRow> {
  final Value<String> shopSlug;
  final Value<String> publicationId;
  final Value<String> categoryId;
  final Value<String> categorySlug;
  final Value<String> categoryName;
  final Value<int> categorySortRank;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> brand;
  final Value<String> normalizedSearchText;
  final Value<int> priceClp;
  final Value<int?> compareAtPriceClp;
  final Value<int?> discountBps;
  final Value<String?> promotionId;
  final Value<String?> promotionName;
  final Value<DateTime?> promotionStartsAt;
  final Value<DateTime?> promotionEndsAt;
  final Value<bool> featured;
  final Value<int> sortRank;
  final Value<String> availability;
  final Value<bool> pickupEnabled;
  final Value<bool> deliveryEnabled;
  final Value<bool> reservationEnabled;
  final Value<String?> imageVersion;
  final Value<String?> imageThumbUrl;
  final Value<String?> imageCardUrl;
  final Value<String?> imageDetailUrl;
  final Value<String?> imageSha256;
  final Value<int> catalogVersion;
  final Value<DateTime> publishedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const CachedStorefrontProductsCompanion({
    this.shopSlug = const Value.absent(),
    this.publicationId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categorySlug = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categorySortRank = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.brand = const Value.absent(),
    this.normalizedSearchText = const Value.absent(),
    this.priceClp = const Value.absent(),
    this.compareAtPriceClp = const Value.absent(),
    this.discountBps = const Value.absent(),
    this.promotionId = const Value.absent(),
    this.promotionName = const Value.absent(),
    this.promotionStartsAt = const Value.absent(),
    this.promotionEndsAt = const Value.absent(),
    this.featured = const Value.absent(),
    this.sortRank = const Value.absent(),
    this.availability = const Value.absent(),
    this.pickupEnabled = const Value.absent(),
    this.deliveryEnabled = const Value.absent(),
    this.reservationEnabled = const Value.absent(),
    this.imageVersion = const Value.absent(),
    this.imageThumbUrl = const Value.absent(),
    this.imageCardUrl = const Value.absent(),
    this.imageDetailUrl = const Value.absent(),
    this.imageSha256 = const Value.absent(),
    this.catalogVersion = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStorefrontProductsCompanion.insert({
    required String shopSlug,
    required String publicationId,
    required String categoryId,
    required String categorySlug,
    required String categoryName,
    required int categorySortRank,
    required String name,
    this.description = const Value.absent(),
    this.brand = const Value.absent(),
    required String normalizedSearchText,
    required int priceClp,
    this.compareAtPriceClp = const Value.absent(),
    this.discountBps = const Value.absent(),
    this.promotionId = const Value.absent(),
    this.promotionName = const Value.absent(),
    this.promotionStartsAt = const Value.absent(),
    this.promotionEndsAt = const Value.absent(),
    required bool featured,
    required int sortRank,
    required String availability,
    required bool pickupEnabled,
    required bool deliveryEnabled,
    required bool reservationEnabled,
    this.imageVersion = const Value.absent(),
    this.imageThumbUrl = const Value.absent(),
    this.imageCardUrl = const Value.absent(),
    this.imageDetailUrl = const Value.absent(),
    this.imageSha256 = const Value.absent(),
    required int catalogVersion,
    required DateTime publishedAt,
    required DateTime updatedAt,
    required DateTime cachedAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : shopSlug = Value(shopSlug),
       publicationId = Value(publicationId),
       categoryId = Value(categoryId),
       categorySlug = Value(categorySlug),
       categoryName = Value(categoryName),
       categorySortRank = Value(categorySortRank),
       name = Value(name),
       normalizedSearchText = Value(normalizedSearchText),
       priceClp = Value(priceClp),
       featured = Value(featured),
       sortRank = Value(sortRank),
       availability = Value(availability),
       pickupEnabled = Value(pickupEnabled),
       deliveryEnabled = Value(deliveryEnabled),
       reservationEnabled = Value(reservationEnabled),
       catalogVersion = Value(catalogVersion),
       publishedAt = Value(publishedAt),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<CachedStorefrontProductRow> custom({
    Expression<String>? shopSlug,
    Expression<String>? publicationId,
    Expression<String>? categoryId,
    Expression<String>? categorySlug,
    Expression<String>? categoryName,
    Expression<int>? categorySortRank,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? brand,
    Expression<String>? normalizedSearchText,
    Expression<int>? priceClp,
    Expression<int>? compareAtPriceClp,
    Expression<int>? discountBps,
    Expression<String>? promotionId,
    Expression<String>? promotionName,
    Expression<DateTime>? promotionStartsAt,
    Expression<DateTime>? promotionEndsAt,
    Expression<bool>? featured,
    Expression<int>? sortRank,
    Expression<String>? availability,
    Expression<bool>? pickupEnabled,
    Expression<bool>? deliveryEnabled,
    Expression<bool>? reservationEnabled,
    Expression<String>? imageVersion,
    Expression<String>? imageThumbUrl,
    Expression<String>? imageCardUrl,
    Expression<String>? imageDetailUrl,
    Expression<String>? imageSha256,
    Expression<int>? catalogVersion,
    Expression<DateTime>? publishedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopSlug != null) 'shop_slug': shopSlug,
      if (publicationId != null) 'publication_id': publicationId,
      if (categoryId != null) 'category_id': categoryId,
      if (categorySlug != null) 'category_slug': categorySlug,
      if (categoryName != null) 'category_name': categoryName,
      if (categorySortRank != null) 'category_sort_rank': categorySortRank,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (brand != null) 'brand': brand,
      if (normalizedSearchText != null)
        'normalized_search_text': normalizedSearchText,
      if (priceClp != null) 'price_clp': priceClp,
      if (compareAtPriceClp != null) 'compare_at_price_clp': compareAtPriceClp,
      if (discountBps != null) 'discount_bps': discountBps,
      if (promotionId != null) 'promotion_id': promotionId,
      if (promotionName != null) 'promotion_name': promotionName,
      if (promotionStartsAt != null) 'promotion_starts_at': promotionStartsAt,
      if (promotionEndsAt != null) 'promotion_ends_at': promotionEndsAt,
      if (featured != null) 'featured': featured,
      if (sortRank != null) 'sort_rank': sortRank,
      if (availability != null) 'availability': availability,
      if (pickupEnabled != null) 'pickup_enabled': pickupEnabled,
      if (deliveryEnabled != null) 'delivery_enabled': deliveryEnabled,
      if (reservationEnabled != null) 'reservation_enabled': reservationEnabled,
      if (imageVersion != null) 'image_version': imageVersion,
      if (imageThumbUrl != null) 'image_thumb_url': imageThumbUrl,
      if (imageCardUrl != null) 'image_card_url': imageCardUrl,
      if (imageDetailUrl != null) 'image_detail_url': imageDetailUrl,
      if (imageSha256 != null) 'image_sha256': imageSha256,
      if (catalogVersion != null) 'catalog_version': catalogVersion,
      if (publishedAt != null) 'published_at': publishedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStorefrontProductsCompanion copyWith({
    Value<String>? shopSlug,
    Value<String>? publicationId,
    Value<String>? categoryId,
    Value<String>? categorySlug,
    Value<String>? categoryName,
    Value<int>? categorySortRank,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? brand,
    Value<String>? normalizedSearchText,
    Value<int>? priceClp,
    Value<int?>? compareAtPriceClp,
    Value<int?>? discountBps,
    Value<String?>? promotionId,
    Value<String?>? promotionName,
    Value<DateTime?>? promotionStartsAt,
    Value<DateTime?>? promotionEndsAt,
    Value<bool>? featured,
    Value<int>? sortRank,
    Value<String>? availability,
    Value<bool>? pickupEnabled,
    Value<bool>? deliveryEnabled,
    Value<bool>? reservationEnabled,
    Value<String?>? imageVersion,
    Value<String?>? imageThumbUrl,
    Value<String?>? imageCardUrl,
    Value<String?>? imageDetailUrl,
    Value<String?>? imageSha256,
    Value<int>? catalogVersion,
    Value<DateTime>? publishedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<DateTime>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return CachedStorefrontProductsCompanion(
      shopSlug: shopSlug ?? this.shopSlug,
      publicationId: publicationId ?? this.publicationId,
      categoryId: categoryId ?? this.categoryId,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryName: categoryName ?? this.categoryName,
      categorySortRank: categorySortRank ?? this.categorySortRank,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      normalizedSearchText: normalizedSearchText ?? this.normalizedSearchText,
      priceClp: priceClp ?? this.priceClp,
      compareAtPriceClp: compareAtPriceClp ?? this.compareAtPriceClp,
      discountBps: discountBps ?? this.discountBps,
      promotionId: promotionId ?? this.promotionId,
      promotionName: promotionName ?? this.promotionName,
      promotionStartsAt: promotionStartsAt ?? this.promotionStartsAt,
      promotionEndsAt: promotionEndsAt ?? this.promotionEndsAt,
      featured: featured ?? this.featured,
      sortRank: sortRank ?? this.sortRank,
      availability: availability ?? this.availability,
      pickupEnabled: pickupEnabled ?? this.pickupEnabled,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      reservationEnabled: reservationEnabled ?? this.reservationEnabled,
      imageVersion: imageVersion ?? this.imageVersion,
      imageThumbUrl: imageThumbUrl ?? this.imageThumbUrl,
      imageCardUrl: imageCardUrl ?? this.imageCardUrl,
      imageDetailUrl: imageDetailUrl ?? this.imageDetailUrl,
      imageSha256: imageSha256 ?? this.imageSha256,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopSlug.present) {
      map['shop_slug'] = Variable<String>(shopSlug.value);
    }
    if (publicationId.present) {
      map['publication_id'] = Variable<String>(publicationId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categorySlug.present) {
      map['category_slug'] = Variable<String>(categorySlug.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categorySortRank.present) {
      map['category_sort_rank'] = Variable<int>(categorySortRank.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (normalizedSearchText.present) {
      map['normalized_search_text'] = Variable<String>(
        normalizedSearchText.value,
      );
    }
    if (priceClp.present) {
      map['price_clp'] = Variable<int>(priceClp.value);
    }
    if (compareAtPriceClp.present) {
      map['compare_at_price_clp'] = Variable<int>(compareAtPriceClp.value);
    }
    if (discountBps.present) {
      map['discount_bps'] = Variable<int>(discountBps.value);
    }
    if (promotionId.present) {
      map['promotion_id'] = Variable<String>(promotionId.value);
    }
    if (promotionName.present) {
      map['promotion_name'] = Variable<String>(promotionName.value);
    }
    if (promotionStartsAt.present) {
      map['promotion_starts_at'] = Variable<DateTime>(promotionStartsAt.value);
    }
    if (promotionEndsAt.present) {
      map['promotion_ends_at'] = Variable<DateTime>(promotionEndsAt.value);
    }
    if (featured.present) {
      map['featured'] = Variable<bool>(featured.value);
    }
    if (sortRank.present) {
      map['sort_rank'] = Variable<int>(sortRank.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (pickupEnabled.present) {
      map['pickup_enabled'] = Variable<bool>(pickupEnabled.value);
    }
    if (deliveryEnabled.present) {
      map['delivery_enabled'] = Variable<bool>(deliveryEnabled.value);
    }
    if (reservationEnabled.present) {
      map['reservation_enabled'] = Variable<bool>(reservationEnabled.value);
    }
    if (imageVersion.present) {
      map['image_version'] = Variable<String>(imageVersion.value);
    }
    if (imageThumbUrl.present) {
      map['image_thumb_url'] = Variable<String>(imageThumbUrl.value);
    }
    if (imageCardUrl.present) {
      map['image_card_url'] = Variable<String>(imageCardUrl.value);
    }
    if (imageDetailUrl.present) {
      map['image_detail_url'] = Variable<String>(imageDetailUrl.value);
    }
    if (imageSha256.present) {
      map['image_sha256'] = Variable<String>(imageSha256.value);
    }
    if (catalogVersion.present) {
      map['catalog_version'] = Variable<int>(catalogVersion.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStorefrontProductsCompanion(')
          ..write('shopSlug: $shopSlug, ')
          ..write('publicationId: $publicationId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categorySlug: $categorySlug, ')
          ..write('categoryName: $categoryName, ')
          ..write('categorySortRank: $categorySortRank, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('brand: $brand, ')
          ..write('normalizedSearchText: $normalizedSearchText, ')
          ..write('priceClp: $priceClp, ')
          ..write('compareAtPriceClp: $compareAtPriceClp, ')
          ..write('discountBps: $discountBps, ')
          ..write('promotionId: $promotionId, ')
          ..write('promotionName: $promotionName, ')
          ..write('promotionStartsAt: $promotionStartsAt, ')
          ..write('promotionEndsAt: $promotionEndsAt, ')
          ..write('featured: $featured, ')
          ..write('sortRank: $sortRank, ')
          ..write('availability: $availability, ')
          ..write('pickupEnabled: $pickupEnabled, ')
          ..write('deliveryEnabled: $deliveryEnabled, ')
          ..write('reservationEnabled: $reservationEnabled, ')
          ..write('imageVersion: $imageVersion, ')
          ..write('imageThumbUrl: $imageThumbUrl, ')
          ..write('imageCardUrl: $imageCardUrl, ')
          ..write('imageDetailUrl: $imageDetailUrl, ')
          ..write('imageSha256: $imageSha256, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStorefrontDetailsTable extends CachedStorefrontDetails
    with TableInfo<$CachedStorefrontDetailsTable, CachedStorefrontDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStorefrontDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopSlugMeta = const VerificationMeta(
    'shopSlug',
  );
  @override
  late final GeneratedColumn<String> shopSlug = GeneratedColumn<String>(
    'shop_slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicationIdMeta = const VerificationMeta(
    'publicationId',
  );
  @override
  late final GeneratedColumn<String> publicationId = GeneratedColumn<String>(
    'publication_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    shopSlug,
    publicationId,
    cachedAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_storefront_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStorefrontDetailRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_slug')) {
      context.handle(
        _shopSlugMeta,
        shopSlug.isAcceptableOrUnknown(data['shop_slug']!, _shopSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_shopSlugMeta);
    }
    if (data.containsKey('publication_id')) {
      context.handle(
        _publicationIdMeta,
        publicationId.isAcceptableOrUnknown(
          data['publication_id']!,
          _publicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicationIdMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopSlug, publicationId};
  @override
  CachedStorefrontDetailRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStorefrontDetailRow(
      shopSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_slug'],
      )!,
      publicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_id'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
    );
  }

  @override
  $CachedStorefrontDetailsTable createAlias(String alias) {
    return $CachedStorefrontDetailsTable(attachedDatabase, alias);
  }
}

class CachedStorefrontDetailRow extends DataClass
    implements Insertable<CachedStorefrontDetailRow> {
  final String shopSlug;
  final String publicationId;
  final DateTime cachedAt;
  final DateTime lastAccessedAt;
  const CachedStorefrontDetailRow({
    required this.shopSlug,
    required this.publicationId,
    required this.cachedAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_slug'] = Variable<String>(shopSlug);
    map['publication_id'] = Variable<String>(publicationId);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  CachedStorefrontDetailsCompanion toCompanion(bool nullToAbsent) {
    return CachedStorefrontDetailsCompanion(
      shopSlug: Value(shopSlug),
      publicationId: Value(publicationId),
      cachedAt: Value(cachedAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory CachedStorefrontDetailRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStorefrontDetailRow(
      shopSlug: serializer.fromJson<String>(json['shopSlug']),
      publicationId: serializer.fromJson<String>(json['publicationId']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopSlug': serializer.toJson<String>(shopSlug),
      'publicationId': serializer.toJson<String>(publicationId),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  CachedStorefrontDetailRow copyWith({
    String? shopSlug,
    String? publicationId,
    DateTime? cachedAt,
    DateTime? lastAccessedAt,
  }) => CachedStorefrontDetailRow(
    shopSlug: shopSlug ?? this.shopSlug,
    publicationId: publicationId ?? this.publicationId,
    cachedAt: cachedAt ?? this.cachedAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  CachedStorefrontDetailRow copyWithCompanion(
    CachedStorefrontDetailsCompanion data,
  ) {
    return CachedStorefrontDetailRow(
      shopSlug: data.shopSlug.present ? data.shopSlug.value : this.shopSlug,
      publicationId: data.publicationId.present
          ? data.publicationId.value
          : this.publicationId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStorefrontDetailRow(')
          ..write('shopSlug: $shopSlug, ')
          ..write('publicationId: $publicationId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(shopSlug, publicationId, cachedAt, lastAccessedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStorefrontDetailRow &&
          other.shopSlug == this.shopSlug &&
          other.publicationId == this.publicationId &&
          other.cachedAt == this.cachedAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class CachedStorefrontDetailsCompanion
    extends UpdateCompanion<CachedStorefrontDetailRow> {
  final Value<String> shopSlug;
  final Value<String> publicationId;
  final Value<DateTime> cachedAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const CachedStorefrontDetailsCompanion({
    this.shopSlug = const Value.absent(),
    this.publicationId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStorefrontDetailsCompanion.insert({
    required String shopSlug,
    required String publicationId,
    required DateTime cachedAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : shopSlug = Value(shopSlug),
       publicationId = Value(publicationId),
       cachedAt = Value(cachedAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<CachedStorefrontDetailRow> custom({
    Expression<String>? shopSlug,
    Expression<String>? publicationId,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopSlug != null) 'shop_slug': shopSlug,
      if (publicationId != null) 'publication_id': publicationId,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStorefrontDetailsCompanion copyWith({
    Value<String>? shopSlug,
    Value<String>? publicationId,
    Value<DateTime>? cachedAt,
    Value<DateTime>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return CachedStorefrontDetailsCompanion(
      shopSlug: shopSlug ?? this.shopSlug,
      publicationId: publicationId ?? this.publicationId,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopSlug.present) {
      map['shop_slug'] = Variable<String>(shopSlug.value);
    }
    if (publicationId.present) {
      map['publication_id'] = Variable<String>(publicationId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStorefrontDetailsCompanion(')
          ..write('shopSlug: $shopSlug, ')
          ..write('publicationId: $publicationId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StorefrontCacheScopesTable extends StorefrontCacheScopes
    with TableInfo<$StorefrontCacheScopesTable, StorefrontCacheScopeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorefrontCacheScopesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopSlugMeta = const VerificationMeta(
    'shopSlug',
  );
  @override
  late final GeneratedColumn<String> shopSlug = GeneratedColumn<String>(
    'shop_slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 320,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogVersionMeta = const VerificationMeta(
    'catalogVersion',
  );
  @override
  late final GeneratedColumn<int> catalogVersion = GeneratedColumn<int>(
    'catalog_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshedAtMeta = const VerificationMeta(
    'refreshedAt',
  );
  @override
  late final GeneratedColumn<DateTime> refreshedAt = GeneratedColumn<DateTime>(
    'refreshed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    shopSlug,
    scopeKey,
    catalogVersion,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storefront_cache_scopes';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorefrontCacheScopeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_slug')) {
      context.handle(
        _shopSlugMeta,
        shopSlug.isAcceptableOrUnknown(data['shop_slug']!, _shopSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_shopSlugMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('catalog_version')) {
      context.handle(
        _catalogVersionMeta,
        catalogVersion.isAcceptableOrUnknown(
          data['catalog_version']!,
          _catalogVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogVersionMeta);
    }
    if (data.containsKey('refreshed_at')) {
      context.handle(
        _refreshedAtMeta,
        refreshedAt.isAcceptableOrUnknown(
          data['refreshed_at']!,
          _refreshedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopSlug, scopeKey};
  @override
  StorefrontCacheScopeRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorefrontCacheScopeRow(
      shopSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_slug'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      catalogVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_version'],
      )!,
      refreshedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refreshed_at'],
      )!,
    );
  }

  @override
  $StorefrontCacheScopesTable createAlias(String alias) {
    return $StorefrontCacheScopesTable(attachedDatabase, alias);
  }
}

class StorefrontCacheScopeRow extends DataClass
    implements Insertable<StorefrontCacheScopeRow> {
  final String shopSlug;
  final String scopeKey;
  final int catalogVersion;
  final DateTime refreshedAt;
  const StorefrontCacheScopeRow({
    required this.shopSlug,
    required this.scopeKey,
    required this.catalogVersion,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_slug'] = Variable<String>(shopSlug);
    map['scope_key'] = Variable<String>(scopeKey);
    map['catalog_version'] = Variable<int>(catalogVersion);
    map['refreshed_at'] = Variable<DateTime>(refreshedAt);
    return map;
  }

  StorefrontCacheScopesCompanion toCompanion(bool nullToAbsent) {
    return StorefrontCacheScopesCompanion(
      shopSlug: Value(shopSlug),
      scopeKey: Value(scopeKey),
      catalogVersion: Value(catalogVersion),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory StorefrontCacheScopeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorefrontCacheScopeRow(
      shopSlug: serializer.fromJson<String>(json['shopSlug']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      catalogVersion: serializer.fromJson<int>(json['catalogVersion']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopSlug': serializer.toJson<String>(shopSlug),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'catalogVersion': serializer.toJson<int>(catalogVersion),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  StorefrontCacheScopeRow copyWith({
    String? shopSlug,
    String? scopeKey,
    int? catalogVersion,
    DateTime? refreshedAt,
  }) => StorefrontCacheScopeRow(
    shopSlug: shopSlug ?? this.shopSlug,
    scopeKey: scopeKey ?? this.scopeKey,
    catalogVersion: catalogVersion ?? this.catalogVersion,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  StorefrontCacheScopeRow copyWithCompanion(
    StorefrontCacheScopesCompanion data,
  ) {
    return StorefrontCacheScopeRow(
      shopSlug: data.shopSlug.present ? data.shopSlug.value : this.shopSlug,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      catalogVersion: data.catalogVersion.present
          ? data.catalogVersion.value
          : this.catalogVersion,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorefrontCacheScopeRow(')
          ..write('shopSlug: $shopSlug, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(shopSlug, scopeKey, catalogVersion, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorefrontCacheScopeRow &&
          other.shopSlug == this.shopSlug &&
          other.scopeKey == this.scopeKey &&
          other.catalogVersion == this.catalogVersion &&
          other.refreshedAt == this.refreshedAt);
}

class StorefrontCacheScopesCompanion
    extends UpdateCompanion<StorefrontCacheScopeRow> {
  final Value<String> shopSlug;
  final Value<String> scopeKey;
  final Value<int> catalogVersion;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const StorefrontCacheScopesCompanion({
    this.shopSlug = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.catalogVersion = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorefrontCacheScopesCompanion.insert({
    required String shopSlug,
    required String scopeKey,
    required int catalogVersion,
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : shopSlug = Value(shopSlug),
       scopeKey = Value(scopeKey),
       catalogVersion = Value(catalogVersion),
       refreshedAt = Value(refreshedAt);
  static Insertable<StorefrontCacheScopeRow> custom({
    Expression<String>? shopSlug,
    Expression<String>? scopeKey,
    Expression<int>? catalogVersion,
    Expression<DateTime>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopSlug != null) 'shop_slug': shopSlug,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (catalogVersion != null) 'catalog_version': catalogVersion,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorefrontCacheScopesCompanion copyWith({
    Value<String>? shopSlug,
    Value<String>? scopeKey,
    Value<int>? catalogVersion,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return StorefrontCacheScopesCompanion(
      shopSlug: shopSlug ?? this.shopSlug,
      scopeKey: scopeKey ?? this.scopeKey,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopSlug.present) {
      map['shop_slug'] = Variable<String>(shopSlug.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (catalogVersion.present) {
      map['catalog_version'] = Variable<int>(catalogVersion.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<DateTime>(refreshedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorefrontCacheScopesCompanion(')
          ..write('shopSlug: $shopSlug, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StorefrontCacheScopeItemsTable extends StorefrontCacheScopeItems
    with
        TableInfo<
          $StorefrontCacheScopeItemsTable,
          StorefrontCacheScopeItemRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorefrontCacheScopeItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopSlugMeta = const VerificationMeta(
    'shopSlug',
  );
  @override
  late final GeneratedColumn<String> shopSlug = GeneratedColumn<String>(
    'shop_slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 320,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicationIdMeta = const VerificationMeta(
    'publicationId',
  );
  @override
  late final GeneratedColumn<String> publicationId = GeneratedColumn<String>(
    'publication_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    shopSlug,
    scopeKey,
    publicationId,
    ordinal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storefront_cache_scope_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorefrontCacheScopeItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_slug')) {
      context.handle(
        _shopSlugMeta,
        shopSlug.isAcceptableOrUnknown(data['shop_slug']!, _shopSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_shopSlugMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('publication_id')) {
      context.handle(
        _publicationIdMeta,
        publicationId.isAcceptableOrUnknown(
          data['publication_id']!,
          _publicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicationIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopSlug, scopeKey, publicationId};
  @override
  StorefrontCacheScopeItemRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorefrontCacheScopeItemRow(
      shopSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_slug'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      publicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
    );
  }

  @override
  $StorefrontCacheScopeItemsTable createAlias(String alias) {
    return $StorefrontCacheScopeItemsTable(attachedDatabase, alias);
  }
}

class StorefrontCacheScopeItemRow extends DataClass
    implements Insertable<StorefrontCacheScopeItemRow> {
  final String shopSlug;
  final String scopeKey;
  final String publicationId;
  final int ordinal;
  const StorefrontCacheScopeItemRow({
    required this.shopSlug,
    required this.scopeKey,
    required this.publicationId,
    required this.ordinal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_slug'] = Variable<String>(shopSlug);
    map['scope_key'] = Variable<String>(scopeKey);
    map['publication_id'] = Variable<String>(publicationId);
    map['ordinal'] = Variable<int>(ordinal);
    return map;
  }

  StorefrontCacheScopeItemsCompanion toCompanion(bool nullToAbsent) {
    return StorefrontCacheScopeItemsCompanion(
      shopSlug: Value(shopSlug),
      scopeKey: Value(scopeKey),
      publicationId: Value(publicationId),
      ordinal: Value(ordinal),
    );
  }

  factory StorefrontCacheScopeItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorefrontCacheScopeItemRow(
      shopSlug: serializer.fromJson<String>(json['shopSlug']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      publicationId: serializer.fromJson<String>(json['publicationId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopSlug': serializer.toJson<String>(shopSlug),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'publicationId': serializer.toJson<String>(publicationId),
      'ordinal': serializer.toJson<int>(ordinal),
    };
  }

  StorefrontCacheScopeItemRow copyWith({
    String? shopSlug,
    String? scopeKey,
    String? publicationId,
    int? ordinal,
  }) => StorefrontCacheScopeItemRow(
    shopSlug: shopSlug ?? this.shopSlug,
    scopeKey: scopeKey ?? this.scopeKey,
    publicationId: publicationId ?? this.publicationId,
    ordinal: ordinal ?? this.ordinal,
  );
  StorefrontCacheScopeItemRow copyWithCompanion(
    StorefrontCacheScopeItemsCompanion data,
  ) {
    return StorefrontCacheScopeItemRow(
      shopSlug: data.shopSlug.present ? data.shopSlug.value : this.shopSlug,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      publicationId: data.publicationId.present
          ? data.publicationId.value
          : this.publicationId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorefrontCacheScopeItemRow(')
          ..write('shopSlug: $shopSlug, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('publicationId: $publicationId, ')
          ..write('ordinal: $ordinal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shopSlug, scopeKey, publicationId, ordinal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorefrontCacheScopeItemRow &&
          other.shopSlug == this.shopSlug &&
          other.scopeKey == this.scopeKey &&
          other.publicationId == this.publicationId &&
          other.ordinal == this.ordinal);
}

class StorefrontCacheScopeItemsCompanion
    extends UpdateCompanion<StorefrontCacheScopeItemRow> {
  final Value<String> shopSlug;
  final Value<String> scopeKey;
  final Value<String> publicationId;
  final Value<int> ordinal;
  final Value<int> rowid;
  const StorefrontCacheScopeItemsCompanion({
    this.shopSlug = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.publicationId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorefrontCacheScopeItemsCompanion.insert({
    required String shopSlug,
    required String scopeKey,
    required String publicationId,
    required int ordinal,
    this.rowid = const Value.absent(),
  }) : shopSlug = Value(shopSlug),
       scopeKey = Value(scopeKey),
       publicationId = Value(publicationId),
       ordinal = Value(ordinal);
  static Insertable<StorefrontCacheScopeItemRow> custom({
    Expression<String>? shopSlug,
    Expression<String>? scopeKey,
    Expression<String>? publicationId,
    Expression<int>? ordinal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopSlug != null) 'shop_slug': shopSlug,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (publicationId != null) 'publication_id': publicationId,
      if (ordinal != null) 'ordinal': ordinal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorefrontCacheScopeItemsCompanion copyWith({
    Value<String>? shopSlug,
    Value<String>? scopeKey,
    Value<String>? publicationId,
    Value<int>? ordinal,
    Value<int>? rowid,
  }) {
    return StorefrontCacheScopeItemsCompanion(
      shopSlug: shopSlug ?? this.shopSlug,
      scopeKey: scopeKey ?? this.scopeKey,
      publicationId: publicationId ?? this.publicationId,
      ordinal: ordinal ?? this.ordinal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopSlug.present) {
      map['shop_slug'] = Variable<String>(shopSlug.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (publicationId.present) {
      map['publication_id'] = Variable<String>(publicationId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorefrontCacheScopeItemsCompanion(')
          ..write('shopSlug: $shopSlug, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('publicationId: $publicationId, ')
          ..write('ordinal: $ordinal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StorefrontFavoritesTable extends StorefrontFavorites
    with TableInfo<$StorefrontFavoritesTable, StorefrontFavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorefrontFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shopSlugMeta = const VerificationMeta(
    'shopSlug',
  );
  @override
  late final GeneratedColumn<String> shopSlug = GeneratedColumn<String>(
    'shop_slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 63,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicationIdMeta = const VerificationMeta(
    'publicationId',
  );
  @override
  late final GeneratedColumn<String> publicationId = GeneratedColumn<String>(
    'publication_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    shopSlug,
    publicationId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storefront_favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorefrontFavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shop_slug')) {
      context.handle(
        _shopSlugMeta,
        shopSlug.isAcceptableOrUnknown(data['shop_slug']!, _shopSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_shopSlugMeta);
    }
    if (data.containsKey('publication_id')) {
      context.handle(
        _publicationIdMeta,
        publicationId.isAcceptableOrUnknown(
          data['publication_id']!,
          _publicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicationIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shopSlug, publicationId};
  @override
  StorefrontFavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorefrontFavoriteRow(
      shopSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_slug'],
      )!,
      publicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StorefrontFavoritesTable createAlias(String alias) {
    return $StorefrontFavoritesTable(attachedDatabase, alias);
  }
}

class StorefrontFavoriteRow extends DataClass
    implements Insertable<StorefrontFavoriteRow> {
  final String shopSlug;
  final String publicationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StorefrontFavoriteRow({
    required this.shopSlug,
    required this.publicationId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shop_slug'] = Variable<String>(shopSlug);
    map['publication_id'] = Variable<String>(publicationId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StorefrontFavoritesCompanion toCompanion(bool nullToAbsent) {
    return StorefrontFavoritesCompanion(
      shopSlug: Value(shopSlug),
      publicationId: Value(publicationId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StorefrontFavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorefrontFavoriteRow(
      shopSlug: serializer.fromJson<String>(json['shopSlug']),
      publicationId: serializer.fromJson<String>(json['publicationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shopSlug': serializer.toJson<String>(shopSlug),
      'publicationId': serializer.toJson<String>(publicationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StorefrontFavoriteRow copyWith({
    String? shopSlug,
    String? publicationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StorefrontFavoriteRow(
    shopSlug: shopSlug ?? this.shopSlug,
    publicationId: publicationId ?? this.publicationId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StorefrontFavoriteRow copyWithCompanion(StorefrontFavoritesCompanion data) {
    return StorefrontFavoriteRow(
      shopSlug: data.shopSlug.present ? data.shopSlug.value : this.shopSlug,
      publicationId: data.publicationId.present
          ? data.publicationId.value
          : this.publicationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorefrontFavoriteRow(')
          ..write('shopSlug: $shopSlug, ')
          ..write('publicationId: $publicationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(shopSlug, publicationId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorefrontFavoriteRow &&
          other.shopSlug == this.shopSlug &&
          other.publicationId == this.publicationId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StorefrontFavoritesCompanion
    extends UpdateCompanion<StorefrontFavoriteRow> {
  final Value<String> shopSlug;
  final Value<String> publicationId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StorefrontFavoritesCompanion({
    this.shopSlug = const Value.absent(),
    this.publicationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorefrontFavoritesCompanion.insert({
    required String shopSlug,
    required String publicationId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : shopSlug = Value(shopSlug),
       publicationId = Value(publicationId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StorefrontFavoriteRow> custom({
    Expression<String>? shopSlug,
    Expression<String>? publicationId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shopSlug != null) 'shop_slug': shopSlug,
      if (publicationId != null) 'publication_id': publicationId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorefrontFavoritesCompanion copyWith({
    Value<String>? shopSlug,
    Value<String>? publicationId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StorefrontFavoritesCompanion(
      shopSlug: shopSlug ?? this.shopSlug,
      publicationId: publicationId ?? this.publicationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shopSlug.present) {
      map['shop_slug'] = Variable<String>(shopSlug.value);
    }
    if (publicationId.present) {
      map['publication_id'] = Variable<String>(publicationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorefrontFavoritesCompanion(')
          ..write('shopSlug: $shopSlug, ')
          ..write('publicationId: $publicationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$StorefrontCacheDatabase extends GeneratedDatabase {
  _$StorefrontCacheDatabase(QueryExecutor e) : super(e);
  late final $StorefrontCacheMetadataTable storefrontCacheMetadata =
      $StorefrontCacheMetadataTable(this);
  late final $CachedStorefrontCategoriesTable cachedStorefrontCategories =
      $CachedStorefrontCategoriesTable(this);
  late final $CachedStorefrontProductsTable cachedStorefrontProducts =
      $CachedStorefrontProductsTable(this);
  late final $CachedStorefrontDetailsTable cachedStorefrontDetails =
      $CachedStorefrontDetailsTable(this);
  late final $StorefrontCacheScopesTable storefrontCacheScopes =
      $StorefrontCacheScopesTable(this);
  late final $StorefrontCacheScopeItemsTable storefrontCacheScopeItems =
      $StorefrontCacheScopeItemsTable(this);
  late final $StorefrontFavoritesTable storefrontFavorites =
      $StorefrontFavoritesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storefrontCacheMetadata,
    cachedStorefrontCategories,
    cachedStorefrontProducts,
    cachedStorefrontDetails,
    storefrontCacheScopes,
    storefrontCacheScopeItems,
    storefrontFavorites,
  ];
}
