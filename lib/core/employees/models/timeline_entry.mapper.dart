// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'timeline_entry.dart';

class TimelineEntryMapper extends ClassMapperBase<TimelineEntry> {
  TimelineEntryMapper._();

  static TimelineEntryMapper? _instance;
  static TimelineEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TimelineEntryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'TimelineEntry';

  static String _$id(TimelineEntry v) => v.id;
  static const Field<TimelineEntry, String> _f$id = Field('id', _$id);
  static String _$employeeId(TimelineEntry v) => v.employeeId;
  static const Field<TimelineEntry, String> _f$employeeId = Field(
    'employeeId',
    _$employeeId,
    key: r'employee_id',
  );
  static DateTime _$entryDate(TimelineEntry v) => v.entryDate;
  static const Field<TimelineEntry, DateTime> _f$entryDate = Field(
    'entryDate',
    _$entryDate,
    key: r'entry_date',
  );
  static String _$kind(TimelineEntry v) => v.kind;
  static const Field<TimelineEntry, String> _f$kind = Field('kind', _$kind);
  static String _$label(TimelineEntry v) => v.label;
  static const Field<TimelineEntry, String> _f$label = Field('label', _$label);
  static String? _$note(TimelineEntry v) => v.note;
  static const Field<TimelineEntry, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );
  static double? _$amount(TimelineEntry v) => v.amount;
  static const Field<TimelineEntry, double> _f$amount = Field(
    'amount',
    _$amount,
    opt: true,
  );

  @override
  final MappableFields<TimelineEntry> fields = const {
    #id: _f$id,
    #employeeId: _f$employeeId,
    #entryDate: _f$entryDate,
    #kind: _f$kind,
    #label: _f$label,
    #note: _f$note,
    #amount: _f$amount,
  };

  static TimelineEntry _instantiate(DecodingData data) {
    return TimelineEntry(
      id: data.dec(_f$id),
      employeeId: data.dec(_f$employeeId),
      entryDate: data.dec(_f$entryDate),
      kind: data.dec(_f$kind),
      label: data.dec(_f$label),
      note: data.dec(_f$note),
      amount: data.dec(_f$amount),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TimelineEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TimelineEntry>(map);
  }

  static TimelineEntry fromJson(String json) {
    return ensureInitialized().decodeJson<TimelineEntry>(json);
  }
}

mixin TimelineEntryMappable {
  String toJson() {
    return TimelineEntryMapper.ensureInitialized().encodeJson<TimelineEntry>(
      this as TimelineEntry,
    );
  }

  Map<String, dynamic> toMap() {
    return TimelineEntryMapper.ensureInitialized().encodeMap<TimelineEntry>(
      this as TimelineEntry,
    );
  }

  TimelineEntryCopyWith<TimelineEntry, TimelineEntry, TimelineEntry>
  get copyWith => _TimelineEntryCopyWithImpl<TimelineEntry, TimelineEntry>(
    this as TimelineEntry,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return TimelineEntryMapper.ensureInitialized().stringifyValue(
      this as TimelineEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return TimelineEntryMapper.ensureInitialized().equalsValue(
      this as TimelineEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return TimelineEntryMapper.ensureInitialized().hashValue(
      this as TimelineEntry,
    );
  }
}

extension TimelineEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TimelineEntry, $Out> {
  TimelineEntryCopyWith<$R, TimelineEntry, $Out> get $asTimelineEntry =>
      $base.as((v, t, t2) => _TimelineEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TimelineEntryCopyWith<$R, $In extends TimelineEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? employeeId,
    DateTime? entryDate,
    String? kind,
    String? label,
    String? note,
    double? amount,
  });
  TimelineEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TimelineEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TimelineEntry, $Out>
    implements TimelineEntryCopyWith<$R, TimelineEntry, $Out> {
  _TimelineEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TimelineEntry> $mapper =
      TimelineEntryMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? employeeId,
    DateTime? entryDate,
    String? kind,
    String? label,
    Object? note = $none,
    Object? amount = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (employeeId != null) #employeeId: employeeId,
      if (entryDate != null) #entryDate: entryDate,
      if (kind != null) #kind: kind,
      if (label != null) #label: label,
      if (note != $none) #note: note,
      if (amount != $none) #amount: amount,
    }),
  );
  @override
  TimelineEntry $make(CopyWithData data) => TimelineEntry(
    id: data.get(#id, or: $value.id),
    employeeId: data.get(#employeeId, or: $value.employeeId),
    entryDate: data.get(#entryDate, or: $value.entryDate),
    kind: data.get(#kind, or: $value.kind),
    label: data.get(#label, or: $value.label),
    note: data.get(#note, or: $value.note),
    amount: data.get(#amount, or: $value.amount),
  );

  @override
  TimelineEntryCopyWith<$R2, TimelineEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TimelineEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

