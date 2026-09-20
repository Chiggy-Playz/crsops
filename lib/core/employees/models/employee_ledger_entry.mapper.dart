// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'employee_ledger_entry.dart';

class EmployeeLedgerEntryMapper extends ClassMapperBase<EmployeeLedgerEntry> {
  EmployeeLedgerEntryMapper._();

  static EmployeeLedgerEntryMapper? _instance;
  static EmployeeLedgerEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EmployeeLedgerEntryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'EmployeeLedgerEntry';

  static String? _$id(EmployeeLedgerEntry v) => v.id;
  static const Field<EmployeeLedgerEntry, String> _f$id = Field(
    'id',
    _$id,
    opt: true,
  );
  static String _$employeeId(EmployeeLedgerEntry v) => v.employeeId;
  static const Field<EmployeeLedgerEntry, String> _f$employeeId = Field(
    'employeeId',
    _$employeeId,
    key: r'employee_id',
  );
  static DateTime _$entryDate(EmployeeLedgerEntry v) => v.entryDate;
  static const Field<EmployeeLedgerEntry, DateTime> _f$entryDate = Field(
    'entryDate',
    _$entryDate,
    key: r'entry_date',
  );
  static double _$amount(EmployeeLedgerEntry v) => v.amount;
  static const Field<EmployeeLedgerEntry, double> _f$amount = Field(
    'amount',
    _$amount,
  );
  static String _$entryType(EmployeeLedgerEntry v) => v.entryType;
  static const Field<EmployeeLedgerEntry, String> _f$entryType = Field(
    'entryType',
    _$entryType,
    key: r'entry_type',
  );
  static String? _$note(EmployeeLedgerEntry v) => v.note;
  static const Field<EmployeeLedgerEntry, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );
  static String? _$createdBy(EmployeeLedgerEntry v) => v.createdBy;
  static const Field<EmployeeLedgerEntry, String> _f$createdBy = Field(
    'createdBy',
    _$createdBy,
    key: r'created_by',
    opt: true,
  );
  static DateTime? _$createdAt(EmployeeLedgerEntry v) => v.createdAt;
  static const Field<EmployeeLedgerEntry, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
    key: r'created_at',
    opt: true,
  );

  @override
  final MappableFields<EmployeeLedgerEntry> fields = const {
    #id: _f$id,
    #employeeId: _f$employeeId,
    #entryDate: _f$entryDate,
    #amount: _f$amount,
    #entryType: _f$entryType,
    #note: _f$note,
    #createdBy: _f$createdBy,
    #createdAt: _f$createdAt,
  };

  static EmployeeLedgerEntry _instantiate(DecodingData data) {
    return EmployeeLedgerEntry(
      id: data.dec(_f$id),
      employeeId: data.dec(_f$employeeId),
      entryDate: data.dec(_f$entryDate),
      amount: data.dec(_f$amount),
      entryType: data.dec(_f$entryType),
      note: data.dec(_f$note),
      createdBy: data.dec(_f$createdBy),
      createdAt: data.dec(_f$createdAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EmployeeLedgerEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EmployeeLedgerEntry>(map);
  }

  static EmployeeLedgerEntry fromJson(String json) {
    return ensureInitialized().decodeJson<EmployeeLedgerEntry>(json);
  }
}

mixin EmployeeLedgerEntryMappable {
  String toJson() {
    return EmployeeLedgerEntryMapper.ensureInitialized()
        .encodeJson<EmployeeLedgerEntry>(this as EmployeeLedgerEntry);
  }

  Map<String, dynamic> toMap() {
    return EmployeeLedgerEntryMapper.ensureInitialized()
        .encodeMap<EmployeeLedgerEntry>(this as EmployeeLedgerEntry);
  }

  EmployeeLedgerEntryCopyWith<
    EmployeeLedgerEntry,
    EmployeeLedgerEntry,
    EmployeeLedgerEntry
  >
  get copyWith =>
      _EmployeeLedgerEntryCopyWithImpl<
        EmployeeLedgerEntry,
        EmployeeLedgerEntry
      >(this as EmployeeLedgerEntry, $identity, $identity);
  @override
  String toString() {
    return EmployeeLedgerEntryMapper.ensureInitialized().stringifyValue(
      this as EmployeeLedgerEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return EmployeeLedgerEntryMapper.ensureInitialized().equalsValue(
      this as EmployeeLedgerEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return EmployeeLedgerEntryMapper.ensureInitialized().hashValue(
      this as EmployeeLedgerEntry,
    );
  }
}

extension EmployeeLedgerEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EmployeeLedgerEntry, $Out> {
  EmployeeLedgerEntryCopyWith<$R, EmployeeLedgerEntry, $Out>
  get $asEmployeeLedgerEntry => $base.as(
    (v, t, t2) => _EmployeeLedgerEntryCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class EmployeeLedgerEntryCopyWith<
  $R,
  $In extends EmployeeLedgerEntry,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? employeeId,
    DateTime? entryDate,
    double? amount,
    String? entryType,
    String? note,
    String? createdBy,
    DateTime? createdAt,
  });
  EmployeeLedgerEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _EmployeeLedgerEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EmployeeLedgerEntry, $Out>
    implements EmployeeLedgerEntryCopyWith<$R, EmployeeLedgerEntry, $Out> {
  _EmployeeLedgerEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EmployeeLedgerEntry> $mapper =
      EmployeeLedgerEntryMapper.ensureInitialized();
  @override
  $R call({
    Object? id = $none,
    String? employeeId,
    DateTime? entryDate,
    double? amount,
    String? entryType,
    Object? note = $none,
    Object? createdBy = $none,
    Object? createdAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != $none) #id: id,
      if (employeeId != null) #employeeId: employeeId,
      if (entryDate != null) #entryDate: entryDate,
      if (amount != null) #amount: amount,
      if (entryType != null) #entryType: entryType,
      if (note != $none) #note: note,
      if (createdBy != $none) #createdBy: createdBy,
      if (createdAt != $none) #createdAt: createdAt,
    }),
  );
  @override
  EmployeeLedgerEntry $make(CopyWithData data) => EmployeeLedgerEntry(
    id: data.get(#id, or: $value.id),
    employeeId: data.get(#employeeId, or: $value.employeeId),
    entryDate: data.get(#entryDate, or: $value.entryDate),
    amount: data.get(#amount, or: $value.amount),
    entryType: data.get(#entryType, or: $value.entryType),
    note: data.get(#note, or: $value.note),
    createdBy: data.get(#createdBy, or: $value.createdBy),
    createdAt: data.get(#createdAt, or: $value.createdAt),
  );

  @override
  EmployeeLedgerEntryCopyWith<$R2, EmployeeLedgerEntry, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _EmployeeLedgerEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

