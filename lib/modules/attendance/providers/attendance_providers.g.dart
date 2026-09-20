// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shiftDefaultsRepository)
final shiftDefaultsRepositoryProvider = ShiftDefaultsRepositoryProvider._();

final class ShiftDefaultsRepositoryProvider
    extends
        $FunctionalProvider<
          ShiftDefaultsRepository,
          ShiftDefaultsRepository,
          ShiftDefaultsRepository
        >
    with $Provider<ShiftDefaultsRepository> {
  ShiftDefaultsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftDefaultsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftDefaultsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShiftDefaultsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShiftDefaultsRepository create(Ref ref) {
    return shiftDefaultsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShiftDefaultsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShiftDefaultsRepository>(value),
    );
  }
}

String _$shiftDefaultsRepositoryHash() =>
    r'4a64dc3d7059dd6d3920bd98992d708cce5df8ce';

@ProviderFor(statusTypeRepository)
final statusTypeRepositoryProvider = StatusTypeRepositoryProvider._();

final class StatusTypeRepositoryProvider
    extends
        $FunctionalProvider<
          StatusTypeRepository,
          StatusTypeRepository,
          StatusTypeRepository
        >
    with $Provider<StatusTypeRepository> {
  StatusTypeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statusTypeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statusTypeRepositoryHash();

  @$internal
  @override
  $ProviderElement<StatusTypeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatusTypeRepository create(Ref ref) {
    return statusTypeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatusTypeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatusTypeRepository>(value),
    );
  }
}

String _$statusTypeRepositoryHash() =>
    r'6b4c33b55ec91abf711041ebbda9fdb85647bf8e';

@ProviderFor(attendanceRepository)
final attendanceRepositoryProvider = AttendanceRepositoryProvider._();

final class AttendanceRepositoryProvider
    extends
        $FunctionalProvider<
          AttendanceRepository,
          AttendanceRepository,
          AttendanceRepository
        >
    with $Provider<AttendanceRepository> {
  AttendanceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceRepositoryHash();

  @$internal
  @override
  $ProviderElement<AttendanceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AttendanceRepository create(Ref ref) {
    return attendanceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttendanceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttendanceRepository>(value),
    );
  }
}

String _$attendanceRepositoryHash() =>
    r'490d9d3c8f7d23475d5f4e78cf55eedb81cfcf54';

@ProviderFor(currentShiftDefaults)
final currentShiftDefaultsProvider = CurrentShiftDefaultsProvider._();

final class CurrentShiftDefaultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShiftDefaults>,
          ShiftDefaults,
          FutureOr<ShiftDefaults>
        >
    with $FutureModifier<ShiftDefaults>, $FutureProvider<ShiftDefaults> {
  CurrentShiftDefaultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentShiftDefaultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentShiftDefaultsHash();

  @$internal
  @override
  $FutureProviderElement<ShiftDefaults> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShiftDefaults> create(Ref ref) {
    return currentShiftDefaults(ref);
  }
}

String _$currentShiftDefaultsHash() =>
    r'0be10e5b35c7908d4e3cf3b145f60c30f2896cb2';

@ProviderFor(shiftDefaultsHistory)
final shiftDefaultsHistoryProvider = ShiftDefaultsHistoryProvider._();

final class ShiftDefaultsHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShiftDefaults>>,
          List<ShiftDefaults>,
          FutureOr<List<ShiftDefaults>>
        >
    with
        $FutureModifier<List<ShiftDefaults>>,
        $FutureProvider<List<ShiftDefaults>> {
  ShiftDefaultsHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftDefaultsHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftDefaultsHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<ShiftDefaults>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShiftDefaults>> create(Ref ref) {
    return shiftDefaultsHistory(ref);
  }
}

String _$shiftDefaultsHistoryHash() =>
    r'0183589609e427af6803eeea9abaf8e13492fcdc';

@ProviderFor(statusTypes)
final statusTypesProvider = StatusTypesProvider._();

final class StatusTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StatusType>>,
          List<StatusType>,
          FutureOr<List<StatusType>>
        >
    with $FutureModifier<List<StatusType>>, $FutureProvider<List<StatusType>> {
  StatusTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statusTypesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statusTypesHash();

  @$internal
  @override
  $FutureProviderElement<List<StatusType>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StatusType>> create(Ref ref) {
    return statusTypes(ref);
  }
}

String _$statusTypesHash() => r'8dd83bf9c2a5de68dfeba13bf7f22d78045f9a6c';

@ProviderFor(effectiveRangeStatus)
final effectiveRangeStatusProvider = EffectiveRangeStatusFamily._();

final class EffectiveRangeStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EffectiveStatusRow>>,
          List<EffectiveStatusRow>,
          FutureOr<List<EffectiveStatusRow>>
        >
    with
        $FutureModifier<List<EffectiveStatusRow>>,
        $FutureProvider<List<EffectiveStatusRow>> {
  EffectiveRangeStatusProvider._({
    required EffectiveRangeStatusFamily super.from,
    required ({DateTime start, DateTime end, String? employeeId})
    super.argument,
  }) : super(
         retry: null,
         name: r'effectiveRangeStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$effectiveRangeStatusHash();

  @override
  String toString() {
    return r'effectiveRangeStatusProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<EffectiveStatusRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EffectiveStatusRow>> create(Ref ref) {
    final argument =
        this.argument as ({DateTime start, DateTime end, String? employeeId});
    return effectiveRangeStatus(
      ref,
      start: argument.start,
      end: argument.end,
      employeeId: argument.employeeId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EffectiveRangeStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$effectiveRangeStatusHash() =>
    r'5bc5049decae828806e9041a5567cd1b6c59e9e2';

final class EffectiveRangeStatusFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<EffectiveStatusRow>>,
          ({DateTime start, DateTime end, String? employeeId})
        > {
  EffectiveRangeStatusFamily._()
    : super(
        retry: null,
        name: r'effectiveRangeStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EffectiveRangeStatusProvider call({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) => EffectiveRangeStatusProvider._(
    argument: (start: start, end: end, employeeId: employeeId),
    from: this,
  );

  @override
  String toString() => r'effectiveRangeStatusProvider';
}

@ProviderFor(recentGaps)
final recentGapsProvider = RecentGapsProvider._();

final class RecentGapsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GapRow>>,
          List<GapRow>,
          FutureOr<List<GapRow>>
        >
    with $FutureModifier<List<GapRow>>, $FutureProvider<List<GapRow>> {
  RecentGapsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentGapsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentGapsHash();

  @$internal
  @override
  $FutureProviderElement<List<GapRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GapRow>> create(Ref ref) {
    return recentGaps(ref);
  }
}

String _$recentGapsHash() => r'0a7de945c876fdda5813c1f1e15f45d8375451fa';

@ProviderFor(derivedFlags)
final derivedFlagsProvider = DerivedFlagsFamily._();

final class DerivedFlagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DerivedFlagsRow>>,
          List<DerivedFlagsRow>,
          FutureOr<List<DerivedFlagsRow>>
        >
    with
        $FutureModifier<List<DerivedFlagsRow>>,
        $FutureProvider<List<DerivedFlagsRow>> {
  DerivedFlagsProvider._({
    required DerivedFlagsFamily super.from,
    required ({DateTime start, DateTime end, String? employeeId})
    super.argument,
  }) : super(
         retry: null,
         name: r'derivedFlagsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$derivedFlagsHash();

  @override
  String toString() {
    return r'derivedFlagsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<DerivedFlagsRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DerivedFlagsRow>> create(Ref ref) {
    final argument =
        this.argument as ({DateTime start, DateTime end, String? employeeId});
    return derivedFlags(
      ref,
      start: argument.start,
      end: argument.end,
      employeeId: argument.employeeId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DerivedFlagsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$derivedFlagsHash() => r'852deb428600f4e4089437a5d11739c1c85e3e70';

final class DerivedFlagsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<DerivedFlagsRow>>,
          ({DateTime start, DateTime end, String? employeeId})
        > {
  DerivedFlagsFamily._()
    : super(
        retry: null,
        name: r'derivedFlagsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DerivedFlagsProvider call({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) => DerivedFlagsProvider._(
    argument: (start: start, end: end, employeeId: employeeId),
    from: this,
  );

  @override
  String toString() => r'derivedFlagsProvider';
}
