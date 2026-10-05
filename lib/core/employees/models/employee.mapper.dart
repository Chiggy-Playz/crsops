// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'employee.dart';

class EmploymentStatusMapper extends EnumMapper<EmploymentStatus> {
  EmploymentStatusMapper._();

  static EmploymentStatusMapper? _instance;
  static EmploymentStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EmploymentStatusMapper._());
    }
    return _instance!;
  }

  static EmploymentStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  EmploymentStatus decode(dynamic value) {
    switch (value) {
      case r'active':
        return EmploymentStatus.active;
      case r'inactive':
        return EmploymentStatus.inactive;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(EmploymentStatus self) {
    switch (self) {
      case EmploymentStatus.active:
        return r'active';
      case EmploymentStatus.inactive:
        return r'inactive';
    }
  }
}

extension EmploymentStatusMapperExtension on EmploymentStatus {
  String toValue() {
    EmploymentStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<EmploymentStatus>(this) as String;
  }
}

class EmployeeMapper extends ClassMapperBase<Employee> {
  EmployeeMapper._();

  static EmployeeMapper? _instance;
  static EmployeeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EmployeeMapper._());
      EmploymentStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Employee';

  static String _$id(Employee v) => v.id;
  static const Field<Employee, String> _f$id = Field('id', _$id);
  static String? _$userId(Employee v) => v.userId;
  static const Field<Employee, String> _f$userId = Field(
    'userId',
    _$userId,
    key: r'user_id',
    opt: true,
  );
  static String _$name(Employee v) => v.name;
  static const Field<Employee, String> _f$name = Field('name', _$name);
  static int _$color(Employee v) => v.color;
  static const Field<Employee, int> _f$color = Field('color', _$color);
  static int? _$salary(Employee v) => v.salary;
  static const Field<Employee, int> _f$salary = Field(
    'salary',
    _$salary,
    opt: true,
  );
  static String? _$notes(Employee v) => v.notes;
  static const Field<Employee, String> _f$notes = Field(
    'notes',
    _$notes,
    opt: true,
  );
  static DateTime _$createdAt(Employee v) => v.createdAt;
  static const Field<Employee, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
    key: r'created_at',
  );
  static EmploymentStatus? _$status(Employee v) => v.status;
  static const Field<Employee, EmploymentStatus> _f$status = Field(
    'status',
    _$status,
    opt: true,
  );

  @override
  final MappableFields<Employee> fields = const {
    #id: _f$id,
    #userId: _f$userId,
    #name: _f$name,
    #color: _f$color,
    #salary: _f$salary,
    #notes: _f$notes,
    #createdAt: _f$createdAt,
    #status: _f$status,
  };

  static Employee _instantiate(DecodingData data) {
    return Employee(
      id: data.dec(_f$id),
      userId: data.dec(_f$userId),
      name: data.dec(_f$name),
      color: data.dec(_f$color),
      salary: data.dec(_f$salary),
      notes: data.dec(_f$notes),
      createdAt: data.dec(_f$createdAt),
      status: data.dec(_f$status),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Employee fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Employee>(map);
  }

  static Employee fromJson(String json) {
    return ensureInitialized().decodeJson<Employee>(json);
  }
}

mixin EmployeeMappable {
  String toJson() {
    return EmployeeMapper.ensureInitialized().encodeJson<Employee>(
      this as Employee,
    );
  }

  Map<String, dynamic> toMap() {
    return EmployeeMapper.ensureInitialized().encodeMap<Employee>(
      this as Employee,
    );
  }

  EmployeeCopyWith<Employee, Employee, Employee> get copyWith =>
      _EmployeeCopyWithImpl<Employee, Employee>(
        this as Employee,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return EmployeeMapper.ensureInitialized().stringifyValue(this as Employee);
  }

  @override
  bool operator ==(Object other) {
    return EmployeeMapper.ensureInitialized().equalsValue(
      this as Employee,
      other,
    );
  }

  @override
  int get hashCode {
    return EmployeeMapper.ensureInitialized().hashValue(this as Employee);
  }
}

extension EmployeeValueCopy<$R, $Out> on ObjectCopyWith<$R, Employee, $Out> {
  EmployeeCopyWith<$R, Employee, $Out> get $asEmployee =>
      $base.as((v, t, t2) => _EmployeeCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class EmployeeCopyWith<$R, $In extends Employee, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? userId,
    String? name,
    int? color,
    int? salary,
    String? notes,
    DateTime? createdAt,
    EmploymentStatus? status,
  });
  EmployeeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _EmployeeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Employee, $Out>
    implements EmployeeCopyWith<$R, Employee, $Out> {
  _EmployeeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Employee> $mapper =
      EmployeeMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    Object? userId = $none,
    String? name,
    int? color,
    Object? salary = $none,
    Object? notes = $none,
    DateTime? createdAt,
    Object? status = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (userId != $none) #userId: userId,
      if (name != null) #name: name,
      if (color != null) #color: color,
      if (salary != $none) #salary: salary,
      if (notes != $none) #notes: notes,
      if (createdAt != null) #createdAt: createdAt,
      if (status != $none) #status: status,
    }),
  );
  @override
  Employee $make(CopyWithData data) => Employee(
    id: data.get(#id, or: $value.id),
    userId: data.get(#userId, or: $value.userId),
    name: data.get(#name, or: $value.name),
    color: data.get(#color, or: $value.color),
    salary: data.get(#salary, or: $value.salary),
    notes: data.get(#notes, or: $value.notes),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    status: data.get(#status, or: $value.status),
  );

  @override
  EmployeeCopyWith<$R2, Employee, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _EmployeeCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

