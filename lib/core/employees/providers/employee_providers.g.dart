// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(employeeRepository)
final employeeRepositoryProvider = EmployeeRepositoryProvider._();

final class EmployeeRepositoryProvider
    extends
        $FunctionalProvider<
          EmployeeRepository,
          EmployeeRepository,
          EmployeeRepository
        >
    with $Provider<EmployeeRepository> {
  EmployeeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employeeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employeeRepositoryHash();

  @$internal
  @override
  $ProviderElement<EmployeeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmployeeRepository create(Ref ref) {
    return employeeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmployeeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmployeeRepository>(value),
    );
  }
}

String _$employeeRepositoryHash() =>
    r'cecacd62c9dd2bf2a7d017bac53b0abc0dc489fc';

@ProviderFor(employeeEventRepository)
final employeeEventRepositoryProvider = EmployeeEventRepositoryProvider._();

final class EmployeeEventRepositoryProvider
    extends
        $FunctionalProvider<
          EmployeeEventRepository,
          EmployeeEventRepository,
          EmployeeEventRepository
        >
    with $Provider<EmployeeEventRepository> {
  EmployeeEventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employeeEventRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employeeEventRepositoryHash();

  @$internal
  @override
  $ProviderElement<EmployeeEventRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmployeeEventRepository create(Ref ref) {
    return employeeEventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmployeeEventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmployeeEventRepository>(value),
    );
  }
}

String _$employeeEventRepositoryHash() =>
    r'cad1e2785552f0837d1de84e1d2cba3f84baf095';

@ProviderFor(eventTypeRepository)
final eventTypeRepositoryProvider = EventTypeRepositoryProvider._();

final class EventTypeRepositoryProvider
    extends
        $FunctionalProvider<
          EventTypeRepository,
          EventTypeRepository,
          EventTypeRepository
        >
    with $Provider<EventTypeRepository> {
  EventTypeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventTypeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventTypeRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventTypeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EventTypeRepository create(Ref ref) {
    return eventTypeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventTypeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventTypeRepository>(value),
    );
  }
}

String _$eventTypeRepositoryHash() =>
    r'ce7b0ee6c1124340c611e24a3b43491f9ffdc287';

@ProviderFor(employeeList)
final employeeListProvider = EmployeeListProvider._();

final class EmployeeListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Employee>>,
          List<Employee>,
          FutureOr<List<Employee>>
        >
    with $FutureModifier<List<Employee>>, $FutureProvider<List<Employee>> {
  EmployeeListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employeeListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employeeListHash();

  @$internal
  @override
  $FutureProviderElement<List<Employee>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Employee>> create(Ref ref) {
    return employeeList(ref);
  }
}

String _$employeeListHash() => r'1711befb57278647302cd907b13a485c737a488a';

@ProviderFor(employee)
final employeeProvider = EmployeeFamily._();

final class EmployeeProvider
    extends
        $FunctionalProvider<AsyncValue<Employee>, Employee, FutureOr<Employee>>
    with $FutureModifier<Employee>, $FutureProvider<Employee> {
  EmployeeProvider._({
    required EmployeeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'employeeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeeHash();

  @override
  String toString() {
    return r'employeeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Employee> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Employee> create(Ref ref) {
    final argument = this.argument as String;
    return employee(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeeHash() => r'74c88c654d7e66a7c650c73de35d6623f7484765';

final class EmployeeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Employee>, String> {
  EmployeeFamily._()
    : super(
        retry: null,
        name: r'employeeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmployeeProvider call(String employeeId) =>
      EmployeeProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'employeeProvider';
}

@ProviderFor(employeeCurrentStatus)
final employeeCurrentStatusProvider = EmployeeCurrentStatusFamily._();

final class EmployeeCurrentStatusProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  EmployeeCurrentStatusProvider._({
    required EmployeeCurrentStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'employeeCurrentStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeeCurrentStatusHash();

  @override
  String toString() {
    return r'employeeCurrentStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return employeeCurrentStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeCurrentStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeeCurrentStatusHash() =>
    r'1024a823b7b6b2a28993e70cc33f7ab47d06defd';

final class EmployeeCurrentStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  EmployeeCurrentStatusFamily._()
    : super(
        retry: null,
        name: r'employeeCurrentStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmployeeCurrentStatusProvider call(String employeeId) =>
      EmployeeCurrentStatusProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'employeeCurrentStatusProvider';
}

@ProviderFor(employeeTimeline)
final employeeTimelineProvider = EmployeeTimelineFamily._();

final class EmployeeTimelineProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TimelineEntry>>,
          List<TimelineEntry>,
          FutureOr<List<TimelineEntry>>
        >
    with
        $FutureModifier<List<TimelineEntry>>,
        $FutureProvider<List<TimelineEntry>> {
  EmployeeTimelineProvider._({
    required EmployeeTimelineFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'employeeTimelineProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeeTimelineHash();

  @override
  String toString() {
    return r'employeeTimelineProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TimelineEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TimelineEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return employeeTimeline(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeTimelineProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeeTimelineHash() => r'2195df982c7b90ffe59045e425769e9fa65c43ca';

final class EmployeeTimelineFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TimelineEntry>>, String> {
  EmployeeTimelineFamily._()
    : super(
        retry: null,
        name: r'employeeTimelineProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmployeeTimelineProvider call(String employeeId) =>
      EmployeeTimelineProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'employeeTimelineProvider';
}

@ProviderFor(eventTypes)
final eventTypesProvider = EventTypesProvider._();

final class EventTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EventType>>,
          List<EventType>,
          FutureOr<List<EventType>>
        >
    with $FutureModifier<List<EventType>>, $FutureProvider<List<EventType>> {
  EventTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventTypesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventTypesHash();

  @$internal
  @override
  $FutureProviderElement<List<EventType>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EventType>> create(Ref ref) {
    return eventTypes(ref);
  }
}

String _$eventTypesHash() => r'bbb56dbc0ee02e5305dafbe860e714d02e728410';
