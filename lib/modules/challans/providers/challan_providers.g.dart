// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challan_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(challanRepository)
final challanRepositoryProvider = ChallanRepositoryProvider._();

final class ChallanRepositoryProvider
    extends
        $FunctionalProvider<
          ChallanRepository,
          ChallanRepository,
          ChallanRepository
        >
    with $Provider<ChallanRepository> {
  ChallanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challanRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challanRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChallanRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChallanRepository create(Ref ref) {
    return challanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChallanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChallanRepository>(value),
    );
  }
}

String _$challanRepositoryHash() => r'493e9c33de6d2b9179a6a23a27a6e94848e6cabb';

/// Goes up by one after any challan change; everything that shows challans
/// watches it, so one [ChallansRevision.bump] refreshes all of it. They also
/// watch the clients revision, since challans show client details.

@ProviderFor(ChallansRevision)
final challansRevisionProvider = ChallansRevisionProvider._();

/// Goes up by one after any challan change; everything that shows challans
/// watches it, so one [ChallansRevision.bump] refreshes all of it. They also
/// watch the clients revision, since challans show client details.
final class ChallansRevisionProvider
    extends $NotifierProvider<ChallansRevision, int> {
  /// Goes up by one after any challan change; everything that shows challans
  /// watches it, so one [ChallansRevision.bump] refreshes all of it. They also
  /// watch the clients revision, since challans show client details.
  ChallansRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challansRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challansRevisionHash();

  @$internal
  @override
  ChallansRevision create() => ChallansRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$challansRevisionHash() => r'1ef728d86ad26ff797f0c22546d55a51f7514eac';

/// Goes up by one after any challan change; everything that shows challans
/// watches it, so one [ChallansRevision.bump] refreshes all of it. They also
/// watch the clients revision, since challans show client details.

abstract class _$ChallansRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Outward or Inward, as picked on the list. Kept while the app runs, so
/// coming back to the tab shows the same list.

@ProviderFor(SelectedDirection)
final selectedDirectionProvider = SelectedDirectionProvider._();

/// Outward or Inward, as picked on the list. Kept while the app runs, so
/// coming back to the tab shows the same list.
final class SelectedDirectionProvider
    extends $NotifierProvider<SelectedDirection, ChallanDirection> {
  /// Outward or Inward, as picked on the list. Kept while the app runs, so
  /// coming back to the tab shows the same list.
  SelectedDirectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDirectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDirectionHash();

  @$internal
  @override
  SelectedDirection create() => SelectedDirection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChallanDirection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChallanDirection>(value),
    );
  }
}

String _$selectedDirectionHash() => r'7e72e662e34aa1efe375a635baeff723df1010c7';

/// Outward or Inward, as picked on the list. Kept while the app runs, so
/// coming back to the tab shows the same list.

abstract class _$SelectedDirection extends $Notifier<ChallanDirection> {
  ChallanDirection build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChallanDirection, ChallanDirection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChallanDirection, ChallanDirection>,
              ChallanDirection,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The list's challans: this financial year's and last year's, newest first,
/// so the list never starts empty on 1 April. Anything older is found with
/// the search page.

@ProviderFor(recentChallans)
final recentChallansProvider = RecentChallansFamily._();

/// The list's challans: this financial year's and last year's, newest first,
/// so the list never starts empty on 1 April. Anything older is found with
/// the search page.

final class RecentChallansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Challan>>,
          List<Challan>,
          FutureOr<List<Challan>>
        >
    with $FutureModifier<List<Challan>>, $FutureProvider<List<Challan>> {
  /// The list's challans: this financial year's and last year's, newest first,
  /// so the list never starts empty on 1 April. Anything older is found with
  /// the search page.
  RecentChallansProvider._({
    required RecentChallansFamily super.from,
    required ChallanDirection super.argument,
  }) : super(
         retry: null,
         name: r'recentChallansProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentChallansHash();

  @override
  String toString() {
    return r'recentChallansProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Challan>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Challan>> create(Ref ref) {
    final argument = this.argument as ChallanDirection;
    return recentChallans(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentChallansProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentChallansHash() => r'ac2c335b6b79c7c32be3e877f616af8fc8baf4f5';

/// The list's challans: this financial year's and last year's, newest first,
/// so the list never starts empty on 1 April. Anything older is found with
/// the search page.

final class RecentChallansFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Challan>>, ChallanDirection> {
  RecentChallansFamily._()
    : super(
        retry: null,
        name: r'recentChallansProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The list's challans: this financial year's and last year's, newest first,
  /// so the list never starts empty on 1 April. Anything older is found with
  /// the search page.

  RecentChallansProvider call(ChallanDirection direction) =>
      RecentChallansProvider._(argument: direction, from: this);

  @override
  String toString() => r'recentChallansProvider';
}

@ProviderFor(challan)
final challanProvider = ChallanFamily._();

final class ChallanProvider
    extends $FunctionalProvider<AsyncValue<Challan>, Challan, FutureOr<Challan>>
    with $FutureModifier<Challan>, $FutureProvider<Challan> {
  ChallanProvider._({
    required ChallanFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'challanProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$challanHash();

  @override
  String toString() {
    return r'challanProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Challan> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Challan> create(Ref ref) {
    final argument = this.argument as String;
    return challan(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallanProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$challanHash() => r'323f5fc93f49df35b71629a06aeb921bd8b437c6';

final class ChallanFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Challan>, String> {
  ChallanFamily._()
    : super(
        retry: null,
        name: r'challanProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChallanProvider call(String challanId) =>
      ChallanProvider._(argument: challanId, from: this);

  @override
  String toString() => r'challanProvider';
}

@ProviderFor(clientChallans)
final clientChallansProvider = ClientChallansFamily._();

final class ClientChallansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Challan>>,
          List<Challan>,
          FutureOr<List<Challan>>
        >
    with $FutureModifier<List<Challan>>, $FutureProvider<List<Challan>> {
  ClientChallansProvider._({
    required ClientChallansFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clientChallansProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clientChallansHash();

  @override
  String toString() {
    return r'clientChallansProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Challan>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Challan>> create(Ref ref) {
    final argument = this.argument as String;
    return clientChallans(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientChallansProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clientChallansHash() => r'e8f8104b7393a90b7e67fd5707085fa84563e8fb';

final class ClientChallansFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Challan>>, String> {
  ClientChallansFamily._()
    : super(
        retry: null,
        name: r'clientChallansProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClientChallansProvider call(String clientId) =>
      ClientChallansProvider._(argument: clientId, from: this);

  @override
  String toString() => r'clientChallansProvider';
}

@ProviderFor(challanHistory)
final challanHistoryProvider = ChallanHistoryFamily._();

final class ChallanHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChallanEvent>>,
          List<ChallanEvent>,
          FutureOr<List<ChallanEvent>>
        >
    with
        $FutureModifier<List<ChallanEvent>>,
        $FutureProvider<List<ChallanEvent>> {
  ChallanHistoryProvider._({
    required ChallanHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'challanHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$challanHistoryHash();

  @override
  String toString() {
    return r'challanHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ChallanEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChallanEvent>> create(Ref ref) {
    final argument = this.argument as String;
    return challanHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallanHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$challanHistoryHash() => r'6c1d487b2dbdad1a6c30c5cde3deef1215cdedb9';

final class ChallanHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ChallanEvent>>, String> {
  ChallanHistoryFamily._()
    : super(
        retry: null,
        name: r'challanHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChallanHistoryProvider call(String challanId) =>
      ChallanHistoryProvider._(argument: challanId, from: this);

  @override
  String toString() => r'challanHistoryProvider';
}

@ProviderFor(handledByNames)
final handledByNamesProvider = HandledByNamesProvider._();

final class HandledByNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  HandledByNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'handledByNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$handledByNamesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return handledByNames(ref);
  }
}

String _$handledByNamesHash() => r'a6df42af3c7e2882d5c3e36d47d3447d1e315422';

@ProviderFor(itemUnits)
final itemUnitsProvider = ItemUnitsProvider._();

final class ItemUnitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  ItemUnitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itemUnitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itemUnitsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return itemUnits(ref);
  }
}

String _$itemUnitsHash() => r'e2a754d01f2dd4b9652fe08d128811e88203656e';

/// Results for the search page; refreshed after any challan change.

@ProviderFor(challanSearch)
final challanSearchProvider = ChallanSearchFamily._();

/// Results for the search page; refreshed after any challan change.

final class ChallanSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Challan>>,
          List<Challan>,
          FutureOr<List<Challan>>
        >
    with $FutureModifier<List<Challan>>, $FutureProvider<List<Challan>> {
  /// Results for the search page; refreshed after any challan change.
  ChallanSearchProvider._({
    required ChallanSearchFamily super.from,
    required ChallanSearchFilters super.argument,
  }) : super(
         retry: null,
         name: r'challanSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$challanSearchHash();

  @override
  String toString() {
    return r'challanSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Challan>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Challan>> create(Ref ref) {
    final argument = this.argument as ChallanSearchFilters;
    return challanSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChallanSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$challanSearchHash() => r'2ee8a41f19fa9a25e2b7c095bc642e0a97977732';

/// Results for the search page; refreshed after any challan change.

final class ChallanSearchFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Challan>>,
          ChallanSearchFilters
        > {
  ChallanSearchFamily._()
    : super(
        retry: null,
        name: r'challanSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Results for the search page; refreshed after any challan change.

  ChallanSearchProvider call(ChallanSearchFilters filters) =>
      ChallanSearchProvider._(argument: filters, from: this);

  @override
  String toString() => r'challanSearchProvider';
}

/// The PDF's font and CANCELLED stamp, loaded once.

@ProviderFor(challanPdfAssets)
final challanPdfAssetsProvider = ChallanPdfAssetsProvider._();

/// The PDF's font and CANCELLED stamp, loaded once.

final class ChallanPdfAssetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChallanPdfAssets>,
          ChallanPdfAssets,
          FutureOr<ChallanPdfAssets>
        >
    with $FutureModifier<ChallanPdfAssets>, $FutureProvider<ChallanPdfAssets> {
  /// The PDF's font and CANCELLED stamp, loaded once.
  ChallanPdfAssetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challanPdfAssetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challanPdfAssetsHash();

  @$internal
  @override
  $FutureProviderElement<ChallanPdfAssets> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChallanPdfAssets> create(Ref ref) {
    return challanPdfAssets(ref);
  }
}

String _$challanPdfAssetsHash() => r'd710d3bffbdf09001f96928032d46dad73c24218';
