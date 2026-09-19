// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'app_session.dart';

class AppRoleMapper extends EnumMapper<AppRole> {
  AppRoleMapper._();

  static AppRoleMapper? _instance;
  static AppRoleMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AppRoleMapper._());
    }
    return _instance!;
  }

  static AppRole fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  AppRole decode(dynamic value) {
    switch (value) {
      case r'superadmin':
        return AppRole.superadmin;
      case r'admin':
        return AppRole.admin;
      case r'employee':
        return AppRole.employee;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(AppRole self) {
    switch (self) {
      case AppRole.superadmin:
        return r'superadmin';
      case AppRole.admin:
        return r'admin';
      case AppRole.employee:
        return r'employee';
    }
  }
}

extension AppRoleMapperExtension on AppRole {
  String toValue() {
    AppRoleMapper.ensureInitialized();
    return MapperContainer.globals.toValue<AppRole>(this) as String;
  }
}

class AppSessionMapper extends ClassMapperBase<AppSession> {
  AppSessionMapper._();

  static AppSessionMapper? _instance;
  static AppSessionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AppSessionMapper._());
      AppRoleMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'AppSession';

  static String _$userId(AppSession v) => v.userId;
  static const Field<AppSession, String> _f$userId = Field('userId', _$userId);
  static String _$email(AppSession v) => v.email;
  static const Field<AppSession, String> _f$email = Field('email', _$email);
  static AppRole? _$role(AppSession v) => v.role;
  static const Field<AppSession, AppRole> _f$role = Field('role', _$role);
  static Set<String> _$moduleAccess(AppSession v) => v.moduleAccess;
  static const Field<AppSession, Set<String>> _f$moduleAccess = Field(
    'moduleAccess',
    _$moduleAccess,
  );

  @override
  final MappableFields<AppSession> fields = const {
    #userId: _f$userId,
    #email: _f$email,
    #role: _f$role,
    #moduleAccess: _f$moduleAccess,
  };

  static AppSession _instantiate(DecodingData data) {
    return AppSession(
      userId: data.dec(_f$userId),
      email: data.dec(_f$email),
      role: data.dec(_f$role),
      moduleAccess: data.dec(_f$moduleAccess),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AppSession fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AppSession>(map);
  }

  static AppSession fromJson(String json) {
    return ensureInitialized().decodeJson<AppSession>(json);
  }
}

mixin AppSessionMappable {
  String toJson() {
    return AppSessionMapper.ensureInitialized().encodeJson<AppSession>(
      this as AppSession,
    );
  }

  Map<String, dynamic> toMap() {
    return AppSessionMapper.ensureInitialized().encodeMap<AppSession>(
      this as AppSession,
    );
  }

  AppSessionCopyWith<AppSession, AppSession, AppSession> get copyWith =>
      _AppSessionCopyWithImpl<AppSession, AppSession>(
        this as AppSession,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AppSessionMapper.ensureInitialized().stringifyValue(
      this as AppSession,
    );
  }

  @override
  bool operator ==(Object other) {
    return AppSessionMapper.ensureInitialized().equalsValue(
      this as AppSession,
      other,
    );
  }

  @override
  int get hashCode {
    return AppSessionMapper.ensureInitialized().hashValue(this as AppSession);
  }
}

extension AppSessionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, AppSession, $Out> {
  AppSessionCopyWith<$R, AppSession, $Out> get $asAppSession =>
      $base.as((v, t, t2) => _AppSessionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AppSessionCopyWith<$R, $In extends AppSession, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? userId,
    String? email,
    AppRole? role,
    Set<String>? moduleAccess,
  });
  AppSessionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AppSessionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AppSession, $Out>
    implements AppSessionCopyWith<$R, AppSession, $Out> {
  _AppSessionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AppSession> $mapper =
      AppSessionMapper.ensureInitialized();
  @override
  $R call({
    String? userId,
    String? email,
    Object? role = $none,
    Set<String>? moduleAccess,
  }) => $apply(
    FieldCopyWithData({
      if (userId != null) #userId: userId,
      if (email != null) #email: email,
      if (role != $none) #role: role,
      if (moduleAccess != null) #moduleAccess: moduleAccess,
    }),
  );
  @override
  AppSession $make(CopyWithData data) => AppSession(
    userId: data.get(#userId, or: $value.userId),
    email: data.get(#email, or: $value.email),
    role: data.get(#role, or: $value.role),
    moduleAccess: data.get(#moduleAccess, or: $value.moduleAccess),
  );

  @override
  AppSessionCopyWith<$R2, AppSession, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _AppSessionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

