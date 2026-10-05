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

@ProviderFor(employeeLedgerEntryRepository)
final employeeLedgerEntryRepositoryProvider =
    EmployeeLedgerEntryRepositoryProvider._();

final class EmployeeLedgerEntryRepositoryProvider
    extends
        $FunctionalProvider<
          EmployeeLedgerEntryRepository,
          EmployeeLedgerEntryRepository,
          EmployeeLedgerEntryRepository
        >
    with $Provider<EmployeeLedgerEntryRepository> {
  EmployeeLedgerEntryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employeeLedgerEntryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employeeLedgerEntryRepositoryHash();

  @$internal
  @override
  $ProviderElement<EmployeeLedgerEntryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmployeeLedgerEntryRepository create(Ref ref) {
    return employeeLedgerEntryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmployeeLedgerEntryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmployeeLedgerEntryRepository>(
        value,
      ),
    );
  }
}

String _$employeeLedgerEntryRepositoryHash() =>
    r'c8528b85332b5ea705c27d033446c26ce273e61a';

/// Goes up by one whenever an employee's joined/left history changes:
/// creating an employee, or adding, editing or deleting one of their events.
/// Everything derived from that history (employees' status, the timeline,
/// and attendance's who-was-employed-on-which-day data) watches this, so one
/// [EmployeeHistoryRevision.bump] refreshes all of it.

@ProviderFor(EmployeeHistoryRevision)
final employeeHistoryRevisionProvider = EmployeeHistoryRevisionProvider._();

/// Goes up by one whenever an employee's joined/left history changes:
/// creating an employee, or adding, editing or deleting one of their events.
/// Everything derived from that history (employees' status, the timeline,
/// and attendance's who-was-employed-on-which-day data) watches this, so one
/// [EmployeeHistoryRevision.bump] refreshes all of it.
final class EmployeeHistoryRevisionProvider
    extends $NotifierProvider<EmployeeHistoryRevision, int> {
  /// Goes up by one whenever an employee's joined/left history changes:
  /// creating an employee, or adding, editing or deleting one of their events.
  /// Everything derived from that history (employees' status, the timeline,
  /// and attendance's who-was-employed-on-which-day data) watches this, so one
  /// [EmployeeHistoryRevision.bump] refreshes all of it.
  EmployeeHistoryRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employeeHistoryRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employeeHistoryRevisionHash();

  @$internal
  @override
  EmployeeHistoryRevision create() => EmployeeHistoryRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$employeeHistoryRevisionHash() =>
    r'adc1d3af86af95469bc095c226250759cd5ecc73';

/// Goes up by one whenever an employee's joined/left history changes:
/// creating an employee, or adding, editing or deleting one of their events.
/// Everything derived from that history (employees' status, the timeline,
/// and attendance's who-was-employed-on-which-day data) watches this, so one
/// [EmployeeHistoryRevision.bump] refreshes all of it.

abstract class _$EmployeeHistoryRevision extends $Notifier<int> {
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

String _$employeeListHash() => r'bdfc7bea4719fca6e9158725d8e27e0249e09202';

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

String _$employeeHash() => r'a1af668d8eab5a2fb0f7eb39455dff0a26dc5d7d';

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

String _$employeeTimelineHash() => r'1c8c6938fe14f40e07fb653996f8ead18e6d1cdf';

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

@ProviderFor(distinctEntryTypes)
final distinctEntryTypesProvider = DistinctEntryTypesProvider._();

final class DistinctEntryTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  DistinctEntryTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'distinctEntryTypesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$distinctEntryTypesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return distinctEntryTypes(ref);
  }
}

String _$distinctEntryTypesHash() =>
    r'aeaad395555d06b368228759f1c47346b87eda7b';
