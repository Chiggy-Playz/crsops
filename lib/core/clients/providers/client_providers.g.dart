// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clientRepository)
final clientRepositoryProvider = ClientRepositoryProvider._();

final class ClientRepositoryProvider
    extends
        $FunctionalProvider<
          ClientRepository,
          ClientRepository,
          ClientRepository
        >
    with $Provider<ClientRepository> {
  ClientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientRepositoryHash();

  @$internal
  @override
  $ProviderElement<ClientRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClientRepository create(Ref ref) {
    return clientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientRepository>(value),
    );
  }
}

String _$clientRepositoryHash() => r'6171bd9862012717282c0591b10d1734a361267c';

/// Goes up by one after any change to a client or its addresses. The list,
/// each client, and anything a module shows about clients watch this, so one
/// [ClientsRevision.bump] refreshes all of it.

@ProviderFor(ClientsRevision)
final clientsRevisionProvider = ClientsRevisionProvider._();

/// Goes up by one after any change to a client or its addresses. The list,
/// each client, and anything a module shows about clients watch this, so one
/// [ClientsRevision.bump] refreshes all of it.
final class ClientsRevisionProvider
    extends $NotifierProvider<ClientsRevision, int> {
  /// Goes up by one after any change to a client or its addresses. The list,
  /// each client, and anything a module shows about clients watch this, so one
  /// [ClientsRevision.bump] refreshes all of it.
  ClientsRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientsRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientsRevisionHash();

  @$internal
  @override
  ClientsRevision create() => ClientsRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$clientsRevisionHash() => r'4ac2eb9243922b1eef00d736dc66780e3228c93b';

/// Goes up by one after any change to a client or its addresses. The list,
/// each client, and anything a module shows about clients watch this, so one
/// [ClientsRevision.bump] refreshes all of it.

abstract class _$ClientsRevision extends $Notifier<int> {
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

@ProviderFor(clientList)
final clientListProvider = ClientListProvider._();

final class ClientListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Client>>,
          List<Client>,
          FutureOr<List<Client>>
        >
    with $FutureModifier<List<Client>>, $FutureProvider<List<Client>> {
  ClientListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientListHash();

  @$internal
  @override
  $FutureProviderElement<List<Client>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Client>> create(Ref ref) {
    return clientList(ref);
  }
}

String _$clientListHash() => r'b7118fdd13e54de9f4e4b8ac86e91660600fccee';

@ProviderFor(client)
final clientProvider = ClientFamily._();

final class ClientProvider
    extends $FunctionalProvider<AsyncValue<Client>, Client, FutureOr<Client>>
    with $FutureModifier<Client>, $FutureProvider<Client> {
  ClientProvider._({
    required ClientFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clientProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clientHash();

  @override
  String toString() {
    return r'clientProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Client> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Client> create(Ref ref) {
    final argument = this.argument as String;
    return client(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clientHash() => r'632f71375bd5d65166e9a663e83a3ef317fe497f';

final class ClientFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Client>, String> {
  ClientFamily._()
    : super(
        retry: null,
        name: r'clientProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClientProvider call(String clientId) =>
      ClientProvider._(argument: clientId, from: this);

  @override
  String toString() => r'clientProvider';
}

/// Seeded once by a migration and never edited, so fetched once per session.

@ProviderFor(indianStates)
final indianStatesProvider = IndianStatesProvider._();

/// Seeded once by a migration and never edited, so fetched once per session.

final class IndianStatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IndianState>>,
          List<IndianState>,
          FutureOr<List<IndianState>>
        >
    with
        $FutureModifier<List<IndianState>>,
        $FutureProvider<List<IndianState>> {
  /// Seeded once by a migration and never edited, so fetched once per session.
  IndianStatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indianStatesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indianStatesHash();

  @$internal
  @override
  $FutureProviderElement<List<IndianState>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IndianState>> create(Ref ref) {
    return indianStates(ref);
  }
}

String _$indianStatesHash() => r'dc99435019721307d73cad1f4e75bd6588c1b018';
