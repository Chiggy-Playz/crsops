// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'client_address.dart';

class ClientAddressMapper extends ClassMapperBase<ClientAddress> {
  ClientAddressMapper._();

  static ClientAddressMapper? _instance;
  static ClientAddressMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ClientAddressMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ClientAddress';

  static String _$addressId(ClientAddress v) => v.addressId;
  static const Field<ClientAddress, String> _f$addressId = Field(
    'addressId',
    _$addressId,
    key: r'address_id',
  );
  static String _$clientId(ClientAddress v) => v.clientId;
  static const Field<ClientAddress, String> _f$clientId = Field(
    'clientId',
    _$clientId,
    key: r'client_id',
  );
  static String _$label(ClientAddress v) => v.label;
  static const Field<ClientAddress, String> _f$label = Field('label', _$label);
  static DateTime? _$archivedAt(ClientAddress v) => v.archivedAt;
  static const Field<ClientAddress, DateTime> _f$archivedAt = Field(
    'archivedAt',
    _$archivedAt,
    key: r'archived_at',
    opt: true,
  );
  static String _$versionId(ClientAddress v) => v.versionId;
  static const Field<ClientAddress, String> _f$versionId = Field(
    'versionId',
    _$versionId,
    key: r'version_id',
  );
  static int _$version(ClientAddress v) => v.version;
  static const Field<ClientAddress, int> _f$version = Field(
    'version',
    _$version,
  );
  static String _$nameOnChallan(ClientAddress v) => v.nameOnChallan;
  static const Field<ClientAddress, String> _f$nameOnChallan = Field(
    'nameOnChallan',
    _$nameOnChallan,
    key: r'name_on_challan',
  );
  static String _$address(ClientAddress v) => v.address;
  static const Field<ClientAddress, String> _f$address = Field(
    'address',
    _$address,
  );
  static String _$stateCode(ClientAddress v) => v.stateCode;
  static const Field<ClientAddress, String> _f$stateCode = Field(
    'stateCode',
    _$stateCode,
    key: r'state_code',
  );
  static String _$stateName(ClientAddress v) => v.stateName;
  static const Field<ClientAddress, String> _f$stateName = Field(
    'stateName',
    _$stateName,
    key: r'state_name',
  );
  static String? _$gstin(ClientAddress v) => v.gstin;
  static const Field<ClientAddress, String> _f$gstin = Field(
    'gstin',
    _$gstin,
    opt: true,
  );

  @override
  final MappableFields<ClientAddress> fields = const {
    #addressId: _f$addressId,
    #clientId: _f$clientId,
    #label: _f$label,
    #archivedAt: _f$archivedAt,
    #versionId: _f$versionId,
    #version: _f$version,
    #nameOnChallan: _f$nameOnChallan,
    #address: _f$address,
    #stateCode: _f$stateCode,
    #stateName: _f$stateName,
    #gstin: _f$gstin,
  };

  static ClientAddress _instantiate(DecodingData data) {
    return ClientAddress(
      addressId: data.dec(_f$addressId),
      clientId: data.dec(_f$clientId),
      label: data.dec(_f$label),
      archivedAt: data.dec(_f$archivedAt),
      versionId: data.dec(_f$versionId),
      version: data.dec(_f$version),
      nameOnChallan: data.dec(_f$nameOnChallan),
      address: data.dec(_f$address),
      stateCode: data.dec(_f$stateCode),
      stateName: data.dec(_f$stateName),
      gstin: data.dec(_f$gstin),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ClientAddress fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ClientAddress>(map);
  }

  static ClientAddress fromJson(String json) {
    return ensureInitialized().decodeJson<ClientAddress>(json);
  }
}

mixin ClientAddressMappable {
  String toJson() {
    return ClientAddressMapper.ensureInitialized().encodeJson<ClientAddress>(
      this as ClientAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return ClientAddressMapper.ensureInitialized().encodeMap<ClientAddress>(
      this as ClientAddress,
    );
  }

  ClientAddressCopyWith<ClientAddress, ClientAddress, ClientAddress>
  get copyWith => _ClientAddressCopyWithImpl<ClientAddress, ClientAddress>(
    this as ClientAddress,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ClientAddressMapper.ensureInitialized().stringifyValue(
      this as ClientAddress,
    );
  }

  @override
  bool operator ==(Object other) {
    return ClientAddressMapper.ensureInitialized().equalsValue(
      this as ClientAddress,
      other,
    );
  }

  @override
  int get hashCode {
    return ClientAddressMapper.ensureInitialized().hashValue(
      this as ClientAddress,
    );
  }
}

extension ClientAddressValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ClientAddress, $Out> {
  ClientAddressCopyWith<$R, ClientAddress, $Out> get $asClientAddress =>
      $base.as((v, t, t2) => _ClientAddressCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ClientAddressCopyWith<$R, $In extends ClientAddress, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? addressId,
    String? clientId,
    String? label,
    DateTime? archivedAt,
    String? versionId,
    int? version,
    String? nameOnChallan,
    String? address,
    String? stateCode,
    String? stateName,
    String? gstin,
  });
  ClientAddressCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ClientAddressCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ClientAddress, $Out>
    implements ClientAddressCopyWith<$R, ClientAddress, $Out> {
  _ClientAddressCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ClientAddress> $mapper =
      ClientAddressMapper.ensureInitialized();
  @override
  $R call({
    String? addressId,
    String? clientId,
    String? label,
    Object? archivedAt = $none,
    String? versionId,
    int? version,
    String? nameOnChallan,
    String? address,
    String? stateCode,
    String? stateName,
    Object? gstin = $none,
  }) => $apply(
    FieldCopyWithData({
      if (addressId != null) #addressId: addressId,
      if (clientId != null) #clientId: clientId,
      if (label != null) #label: label,
      if (archivedAt != $none) #archivedAt: archivedAt,
      if (versionId != null) #versionId: versionId,
      if (version != null) #version: version,
      if (nameOnChallan != null) #nameOnChallan: nameOnChallan,
      if (address != null) #address: address,
      if (stateCode != null) #stateCode: stateCode,
      if (stateName != null) #stateName: stateName,
      if (gstin != $none) #gstin: gstin,
    }),
  );
  @override
  ClientAddress $make(CopyWithData data) => ClientAddress(
    addressId: data.get(#addressId, or: $value.addressId),
    clientId: data.get(#clientId, or: $value.clientId),
    label: data.get(#label, or: $value.label),
    archivedAt: data.get(#archivedAt, or: $value.archivedAt),
    versionId: data.get(#versionId, or: $value.versionId),
    version: data.get(#version, or: $value.version),
    nameOnChallan: data.get(#nameOnChallan, or: $value.nameOnChallan),
    address: data.get(#address, or: $value.address),
    stateCode: data.get(#stateCode, or: $value.stateCode),
    stateName: data.get(#stateName, or: $value.stateName),
    gstin: data.get(#gstin, or: $value.gstin),
  );

  @override
  ClientAddressCopyWith<$R2, ClientAddress, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ClientAddressCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

