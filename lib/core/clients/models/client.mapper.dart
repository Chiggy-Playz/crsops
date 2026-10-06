// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'client.dart';

class ClientMapper extends ClassMapperBase<Client> {
  ClientMapper._();

  static ClientMapper? _instance;
  static ClientMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ClientMapper._());
      ClientAddressMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Client';

  static String _$id(Client v) => v.id;
  static const Field<Client, String> _f$id = Field('id', _$id);
  static String _$name(Client v) => v.name;
  static const Field<Client, String> _f$name = Field('name', _$name);
  static String? _$notes(Client v) => v.notes;
  static const Field<Client, String> _f$notes = Field(
    'notes',
    _$notes,
    opt: true,
  );
  static DateTime? _$archivedAt(Client v) => v.archivedAt;
  static const Field<Client, DateTime> _f$archivedAt = Field(
    'archivedAt',
    _$archivedAt,
    key: r'archived_at',
    opt: true,
  );
  static DateTime _$createdAt(Client v) => v.createdAt;
  static const Field<Client, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
    key: r'created_at',
  );
  static List<ClientAddress> _$addresses(Client v) => v.addresses;
  static const Field<Client, List<ClientAddress>> _f$addresses = Field(
    'addresses',
    _$addresses,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<Client> fields = const {
    #id: _f$id,
    #name: _f$name,
    #notes: _f$notes,
    #archivedAt: _f$archivedAt,
    #createdAt: _f$createdAt,
    #addresses: _f$addresses,
  };

  static Client _instantiate(DecodingData data) {
    return Client(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      notes: data.dec(_f$notes),
      archivedAt: data.dec(_f$archivedAt),
      createdAt: data.dec(_f$createdAt),
      addresses: data.dec(_f$addresses),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Client fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Client>(map);
  }

  static Client fromJson(String json) {
    return ensureInitialized().decodeJson<Client>(json);
  }
}

mixin ClientMappable {
  String toJson() {
    return ClientMapper.ensureInitialized().encodeJson<Client>(this as Client);
  }

  Map<String, dynamic> toMap() {
    return ClientMapper.ensureInitialized().encodeMap<Client>(this as Client);
  }

  ClientCopyWith<Client, Client, Client> get copyWith =>
      _ClientCopyWithImpl<Client, Client>(this as Client, $identity, $identity);
  @override
  String toString() {
    return ClientMapper.ensureInitialized().stringifyValue(this as Client);
  }

  @override
  bool operator ==(Object other) {
    return ClientMapper.ensureInitialized().equalsValue(this as Client, other);
  }

  @override
  int get hashCode {
    return ClientMapper.ensureInitialized().hashValue(this as Client);
  }
}

extension ClientValueCopy<$R, $Out> on ObjectCopyWith<$R, Client, $Out> {
  ClientCopyWith<$R, Client, $Out> get $asClient =>
      $base.as((v, t, t2) => _ClientCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ClientCopyWith<$R, $In extends Client, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ClientAddress,
    ClientAddressCopyWith<$R, ClientAddress, ClientAddress>
  >
  get addresses;
  $R call({
    String? id,
    String? name,
    String? notes,
    DateTime? archivedAt,
    DateTime? createdAt,
    List<ClientAddress>? addresses,
  });
  ClientCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ClientCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Client, $Out>
    implements ClientCopyWith<$R, Client, $Out> {
  _ClientCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Client> $mapper = ClientMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ClientAddress,
    ClientAddressCopyWith<$R, ClientAddress, ClientAddress>
  >
  get addresses => ListCopyWith(
    $value.addresses,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(addresses: v),
  );
  @override
  $R call({
    String? id,
    String? name,
    Object? notes = $none,
    Object? archivedAt = $none,
    DateTime? createdAt,
    List<ClientAddress>? addresses,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (notes != $none) #notes: notes,
      if (archivedAt != $none) #archivedAt: archivedAt,
      if (createdAt != null) #createdAt: createdAt,
      if (addresses != null) #addresses: addresses,
    }),
  );
  @override
  Client $make(CopyWithData data) => Client(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    notes: data.get(#notes, or: $value.notes),
    archivedAt: data.get(#archivedAt, or: $value.archivedAt),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    addresses: data.get(#addresses, or: $value.addresses),
  );

  @override
  ClientCopyWith<$R2, Client, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ClientCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

