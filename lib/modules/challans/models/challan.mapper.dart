// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'challan.dart';

class ChallanMapper extends ClassMapperBase<Challan> {
  ChallanMapper._();

  static ChallanMapper? _instance;
  static ChallanMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChallanMapper._());
      ChallanDirectionMapper.ensureInitialized();
      ChallanItemMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Challan';

  static String _$id(Challan v) => v.id;
  static const Field<Challan, String> _f$id = Field('id', _$id);
  static ChallanDirection _$direction(Challan v) => v.direction;
  static const Field<Challan, ChallanDirection> _f$direction = Field(
    'direction',
    _$direction,
  );
  static int _$financialYear(Challan v) => v.financialYear;
  static const Field<Challan, int> _f$financialYear = Field(
    'financialYear',
    _$financialYear,
    key: r'financial_year',
  );
  static int _$number(Challan v) => v.number;
  static const Field<Challan, int> _f$number = Field('number', _$number);
  static DateTime _$challanDate(Challan v) => v.challanDate;
  static const Field<Challan, DateTime> _f$challanDate = Field(
    'challanDate',
    _$challanDate,
    key: r'challan_date',
  );
  static String _$handledByName(Challan v) => v.handledByName;
  static const Field<Challan, String> _f$handledByName = Field(
    'handledByName',
    _$handledByName,
    key: r'handled_by_name',
  );
  static String? _$vehicleNumber(Challan v) => v.vehicleNumber;
  static const Field<Challan, String> _f$vehicleNumber = Field(
    'vehicleNumber',
    _$vehicleNumber,
    key: r'vehicle_number',
    opt: true,
  );
  static int? _$declaredValue(Challan v) => v.declaredValue;
  static const Field<Challan, int> _f$declaredValue = Field(
    'declaredValue',
    _$declaredValue,
    key: r'declared_value',
    opt: true,
  );
  static String? _$notes(Challan v) => v.notes;
  static const Field<Challan, String> _f$notes = Field(
    'notes',
    _$notes,
    opt: true,
  );
  static String? _$billNumber(Challan v) => v.billNumber;
  static const Field<Challan, String> _f$billNumber = Field(
    'billNumber',
    _$billNumber,
    key: r'bill_number',
    opt: true,
  );
  static DateTime? _$receivedOn(Challan v) => v.receivedOn;
  static const Field<Challan, DateTime> _f$receivedOn = Field(
    'receivedOn',
    _$receivedOn,
    key: r'received_on',
    opt: true,
  );
  static bool _$digitallySigned(Challan v) => v.digitallySigned;
  static const Field<Challan, bool> _f$digitallySigned = Field(
    'digitallySigned',
    _$digitallySigned,
    key: r'digitally_signed',
  );
  static DateTime? _$cancelledAt(Challan v) => v.cancelledAt;
  static const Field<Challan, DateTime> _f$cancelledAt = Field(
    'cancelledAt',
    _$cancelledAt,
    key: r'cancelled_at',
    opt: true,
  );
  static String? _$cancelReason(Challan v) => v.cancelReason;
  static const Field<Challan, String> _f$cancelReason = Field(
    'cancelReason',
    _$cancelReason,
    key: r'cancel_reason',
    opt: true,
  );
  static DateTime _$createdAt(Challan v) => v.createdAt;
  static const Field<Challan, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
    key: r'created_at',
  );
  static DateTime _$updatedAt(Challan v) => v.updatedAt;
  static const Field<Challan, DateTime> _f$updatedAt = Field(
    'updatedAt',
    _$updatedAt,
    key: r'updated_at',
  );
  static String _$clientId(Challan v) => v.clientId;
  static const Field<Challan, String> _f$clientId = Field(
    'clientId',
    _$clientId,
    key: r'client_id',
  );
  static String _$clientName(Challan v) => v.clientName;
  static const Field<Challan, String> _f$clientName = Field(
    'clientName',
    _$clientName,
    key: r'client_name',
  );
  static String _$addressId(Challan v) => v.addressId;
  static const Field<Challan, String> _f$addressId = Field(
    'addressId',
    _$addressId,
    key: r'address_id',
  );
  static String _$addressLabel(Challan v) => v.addressLabel;
  static const Field<Challan, String> _f$addressLabel = Field(
    'addressLabel',
    _$addressLabel,
    key: r'address_label',
  );
  static int _$addressVersion(Challan v) => v.addressVersion;
  static const Field<Challan, int> _f$addressVersion = Field(
    'addressVersion',
    _$addressVersion,
    key: r'address_version',
  );
  static int _$latestAddressVersion(Challan v) => v.latestAddressVersion;
  static const Field<Challan, int> _f$latestAddressVersion = Field(
    'latestAddressVersion',
    _$latestAddressVersion,
    key: r'latest_address_version',
  );
  static String _$nameOnChallan(Challan v) => v.nameOnChallan;
  static const Field<Challan, String> _f$nameOnChallan = Field(
    'nameOnChallan',
    _$nameOnChallan,
    key: r'name_on_challan',
  );
  static String _$address(Challan v) => v.address;
  static const Field<Challan, String> _f$address = Field('address', _$address);
  static String _$stateCode(Challan v) => v.stateCode;
  static const Field<Challan, String> _f$stateCode = Field(
    'stateCode',
    _$stateCode,
    key: r'state_code',
  );
  static String _$stateName(Challan v) => v.stateName;
  static const Field<Challan, String> _f$stateName = Field(
    'stateName',
    _$stateName,
    key: r'state_name',
  );
  static String? _$gstin(Challan v) => v.gstin;
  static const Field<Challan, String> _f$gstin = Field(
    'gstin',
    _$gstin,
    opt: true,
  );
  static int _$itemCount(Challan v) => v.itemCount;
  static const Field<Challan, int> _f$itemCount = Field(
    'itemCount',
    _$itemCount,
    key: r'item_count',
  );
  static int _$totalQuantity(Challan v) => v.totalQuantity;
  static const Field<Challan, int> _f$totalQuantity = Field(
    'totalQuantity',
    _$totalQuantity,
    key: r'total_quantity',
  );
  static String? _$firstItem(Challan v) => v.firstItem;
  static const Field<Challan, String> _f$firstItem = Field(
    'firstItem',
    _$firstItem,
    key: r'first_item',
    opt: true,
  );
  static String? _$reversesChallanId(Challan v) => v.reversesChallanId;
  static const Field<Challan, String> _f$reversesChallanId = Field(
    'reversesChallanId',
    _$reversesChallanId,
    key: r'reverses_challan_id',
    opt: true,
  );
  static int? _$reversesNumber(Challan v) => v.reversesNumber;
  static const Field<Challan, int> _f$reversesNumber = Field(
    'reversesNumber',
    _$reversesNumber,
    key: r'reverses_number',
    opt: true,
  );
  static int? _$reversesFinancialYear(Challan v) => v.reversesFinancialYear;
  static const Field<Challan, int> _f$reversesFinancialYear = Field(
    'reversesFinancialYear',
    _$reversesFinancialYear,
    key: r'reverses_financial_year',
    opt: true,
  );
  static String? _$returnedByChallanId(Challan v) => v.returnedByChallanId;
  static const Field<Challan, String> _f$returnedByChallanId = Field(
    'returnedByChallanId',
    _$returnedByChallanId,
    key: r'returned_by_challan_id',
    opt: true,
  );
  static int? _$returnedByNumber(Challan v) => v.returnedByNumber;
  static const Field<Challan, int> _f$returnedByNumber = Field(
    'returnedByNumber',
    _$returnedByNumber,
    key: r'returned_by_number',
    opt: true,
  );
  static int? _$returnedByFinancialYear(Challan v) => v.returnedByFinancialYear;
  static const Field<Challan, int> _f$returnedByFinancialYear = Field(
    'returnedByFinancialYear',
    _$returnedByFinancialYear,
    key: r'returned_by_financial_year',
    opt: true,
  );
  static List<ChallanItem> _$items(Challan v) => v.items;
  static const Field<Challan, List<ChallanItem>> _f$items = Field(
    'items',
    _$items,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<Challan> fields = const {
    #id: _f$id,
    #direction: _f$direction,
    #financialYear: _f$financialYear,
    #number: _f$number,
    #challanDate: _f$challanDate,
    #handledByName: _f$handledByName,
    #vehicleNumber: _f$vehicleNumber,
    #declaredValue: _f$declaredValue,
    #notes: _f$notes,
    #billNumber: _f$billNumber,
    #receivedOn: _f$receivedOn,
    #digitallySigned: _f$digitallySigned,
    #cancelledAt: _f$cancelledAt,
    #cancelReason: _f$cancelReason,
    #createdAt: _f$createdAt,
    #updatedAt: _f$updatedAt,
    #clientId: _f$clientId,
    #clientName: _f$clientName,
    #addressId: _f$addressId,
    #addressLabel: _f$addressLabel,
    #addressVersion: _f$addressVersion,
    #latestAddressVersion: _f$latestAddressVersion,
    #nameOnChallan: _f$nameOnChallan,
    #address: _f$address,
    #stateCode: _f$stateCode,
    #stateName: _f$stateName,
    #gstin: _f$gstin,
    #itemCount: _f$itemCount,
    #totalQuantity: _f$totalQuantity,
    #firstItem: _f$firstItem,
    #reversesChallanId: _f$reversesChallanId,
    #reversesNumber: _f$reversesNumber,
    #reversesFinancialYear: _f$reversesFinancialYear,
    #returnedByChallanId: _f$returnedByChallanId,
    #returnedByNumber: _f$returnedByNumber,
    #returnedByFinancialYear: _f$returnedByFinancialYear,
    #items: _f$items,
  };

  static Challan _instantiate(DecodingData data) {
    return Challan(
      id: data.dec(_f$id),
      direction: data.dec(_f$direction),
      financialYear: data.dec(_f$financialYear),
      number: data.dec(_f$number),
      challanDate: data.dec(_f$challanDate),
      handledByName: data.dec(_f$handledByName),
      vehicleNumber: data.dec(_f$vehicleNumber),
      declaredValue: data.dec(_f$declaredValue),
      notes: data.dec(_f$notes),
      billNumber: data.dec(_f$billNumber),
      receivedOn: data.dec(_f$receivedOn),
      digitallySigned: data.dec(_f$digitallySigned),
      cancelledAt: data.dec(_f$cancelledAt),
      cancelReason: data.dec(_f$cancelReason),
      createdAt: data.dec(_f$createdAt),
      updatedAt: data.dec(_f$updatedAt),
      clientId: data.dec(_f$clientId),
      clientName: data.dec(_f$clientName),
      addressId: data.dec(_f$addressId),
      addressLabel: data.dec(_f$addressLabel),
      addressVersion: data.dec(_f$addressVersion),
      latestAddressVersion: data.dec(_f$latestAddressVersion),
      nameOnChallan: data.dec(_f$nameOnChallan),
      address: data.dec(_f$address),
      stateCode: data.dec(_f$stateCode),
      stateName: data.dec(_f$stateName),
      gstin: data.dec(_f$gstin),
      itemCount: data.dec(_f$itemCount),
      totalQuantity: data.dec(_f$totalQuantity),
      firstItem: data.dec(_f$firstItem),
      reversesChallanId: data.dec(_f$reversesChallanId),
      reversesNumber: data.dec(_f$reversesNumber),
      reversesFinancialYear: data.dec(_f$reversesFinancialYear),
      returnedByChallanId: data.dec(_f$returnedByChallanId),
      returnedByNumber: data.dec(_f$returnedByNumber),
      returnedByFinancialYear: data.dec(_f$returnedByFinancialYear),
      items: data.dec(_f$items),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Challan fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Challan>(map);
  }

  static Challan fromJson(String json) {
    return ensureInitialized().decodeJson<Challan>(json);
  }
}

mixin ChallanMappable {
  String toJson() {
    return ChallanMapper.ensureInitialized().encodeJson<Challan>(
      this as Challan,
    );
  }

  Map<String, dynamic> toMap() {
    return ChallanMapper.ensureInitialized().encodeMap<Challan>(
      this as Challan,
    );
  }

  ChallanCopyWith<Challan, Challan, Challan> get copyWith =>
      _ChallanCopyWithImpl<Challan, Challan>(
        this as Challan,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChallanMapper.ensureInitialized().stringifyValue(this as Challan);
  }

  @override
  bool operator ==(Object other) {
    return ChallanMapper.ensureInitialized().equalsValue(
      this as Challan,
      other,
    );
  }

  @override
  int get hashCode {
    return ChallanMapper.ensureInitialized().hashValue(this as Challan);
  }
}

extension ChallanValueCopy<$R, $Out> on ObjectCopyWith<$R, Challan, $Out> {
  ChallanCopyWith<$R, Challan, $Out> get $asChallan =>
      $base.as((v, t, t2) => _ChallanCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChallanCopyWith<$R, $In extends Challan, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ChallanItem,
    ChallanItemCopyWith<$R, ChallanItem, ChallanItem>
  >
  get items;
  $R call({
    String? id,
    ChallanDirection? direction,
    int? financialYear,
    int? number,
    DateTime? challanDate,
    String? handledByName,
    String? vehicleNumber,
    int? declaredValue,
    String? notes,
    String? billNumber,
    DateTime? receivedOn,
    bool? digitallySigned,
    DateTime? cancelledAt,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientId,
    String? clientName,
    String? addressId,
    String? addressLabel,
    int? addressVersion,
    int? latestAddressVersion,
    String? nameOnChallan,
    String? address,
    String? stateCode,
    String? stateName,
    String? gstin,
    int? itemCount,
    int? totalQuantity,
    String? firstItem,
    String? reversesChallanId,
    int? reversesNumber,
    int? reversesFinancialYear,
    String? returnedByChallanId,
    int? returnedByNumber,
    int? returnedByFinancialYear,
    List<ChallanItem>? items,
  });
  ChallanCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChallanCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Challan, $Out>
    implements ChallanCopyWith<$R, Challan, $Out> {
  _ChallanCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Challan> $mapper =
      ChallanMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ChallanItem,
    ChallanItemCopyWith<$R, ChallanItem, ChallanItem>
  >
  get items => ListCopyWith(
    $value.items,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(items: v),
  );
  @override
  $R call({
    String? id,
    ChallanDirection? direction,
    int? financialYear,
    int? number,
    DateTime? challanDate,
    String? handledByName,
    Object? vehicleNumber = $none,
    Object? declaredValue = $none,
    Object? notes = $none,
    Object? billNumber = $none,
    Object? receivedOn = $none,
    bool? digitallySigned,
    Object? cancelledAt = $none,
    Object? cancelReason = $none,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientId,
    String? clientName,
    String? addressId,
    String? addressLabel,
    int? addressVersion,
    int? latestAddressVersion,
    String? nameOnChallan,
    String? address,
    String? stateCode,
    String? stateName,
    Object? gstin = $none,
    int? itemCount,
    int? totalQuantity,
    Object? firstItem = $none,
    Object? reversesChallanId = $none,
    Object? reversesNumber = $none,
    Object? reversesFinancialYear = $none,
    Object? returnedByChallanId = $none,
    Object? returnedByNumber = $none,
    Object? returnedByFinancialYear = $none,
    List<ChallanItem>? items,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (direction != null) #direction: direction,
      if (financialYear != null) #financialYear: financialYear,
      if (number != null) #number: number,
      if (challanDate != null) #challanDate: challanDate,
      if (handledByName != null) #handledByName: handledByName,
      if (vehicleNumber != $none) #vehicleNumber: vehicleNumber,
      if (declaredValue != $none) #declaredValue: declaredValue,
      if (notes != $none) #notes: notes,
      if (billNumber != $none) #billNumber: billNumber,
      if (receivedOn != $none) #receivedOn: receivedOn,
      if (digitallySigned != null) #digitallySigned: digitallySigned,
      if (cancelledAt != $none) #cancelledAt: cancelledAt,
      if (cancelReason != $none) #cancelReason: cancelReason,
      if (createdAt != null) #createdAt: createdAt,
      if (updatedAt != null) #updatedAt: updatedAt,
      if (clientId != null) #clientId: clientId,
      if (clientName != null) #clientName: clientName,
      if (addressId != null) #addressId: addressId,
      if (addressLabel != null) #addressLabel: addressLabel,
      if (addressVersion != null) #addressVersion: addressVersion,
      if (latestAddressVersion != null)
        #latestAddressVersion: latestAddressVersion,
      if (nameOnChallan != null) #nameOnChallan: nameOnChallan,
      if (address != null) #address: address,
      if (stateCode != null) #stateCode: stateCode,
      if (stateName != null) #stateName: stateName,
      if (gstin != $none) #gstin: gstin,
      if (itemCount != null) #itemCount: itemCount,
      if (totalQuantity != null) #totalQuantity: totalQuantity,
      if (firstItem != $none) #firstItem: firstItem,
      if (reversesChallanId != $none) #reversesChallanId: reversesChallanId,
      if (reversesNumber != $none) #reversesNumber: reversesNumber,
      if (reversesFinancialYear != $none)
        #reversesFinancialYear: reversesFinancialYear,
      if (returnedByChallanId != $none)
        #returnedByChallanId: returnedByChallanId,
      if (returnedByNumber != $none) #returnedByNumber: returnedByNumber,
      if (returnedByFinancialYear != $none)
        #returnedByFinancialYear: returnedByFinancialYear,
      if (items != null) #items: items,
    }),
  );
  @override
  Challan $make(CopyWithData data) => Challan(
    id: data.get(#id, or: $value.id),
    direction: data.get(#direction, or: $value.direction),
    financialYear: data.get(#financialYear, or: $value.financialYear),
    number: data.get(#number, or: $value.number),
    challanDate: data.get(#challanDate, or: $value.challanDate),
    handledByName: data.get(#handledByName, or: $value.handledByName),
    vehicleNumber: data.get(#vehicleNumber, or: $value.vehicleNumber),
    declaredValue: data.get(#declaredValue, or: $value.declaredValue),
    notes: data.get(#notes, or: $value.notes),
    billNumber: data.get(#billNumber, or: $value.billNumber),
    receivedOn: data.get(#receivedOn, or: $value.receivedOn),
    digitallySigned: data.get(#digitallySigned, or: $value.digitallySigned),
    cancelledAt: data.get(#cancelledAt, or: $value.cancelledAt),
    cancelReason: data.get(#cancelReason, or: $value.cancelReason),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    updatedAt: data.get(#updatedAt, or: $value.updatedAt),
    clientId: data.get(#clientId, or: $value.clientId),
    clientName: data.get(#clientName, or: $value.clientName),
    addressId: data.get(#addressId, or: $value.addressId),
    addressLabel: data.get(#addressLabel, or: $value.addressLabel),
    addressVersion: data.get(#addressVersion, or: $value.addressVersion),
    latestAddressVersion: data.get(
      #latestAddressVersion,
      or: $value.latestAddressVersion,
    ),
    nameOnChallan: data.get(#nameOnChallan, or: $value.nameOnChallan),
    address: data.get(#address, or: $value.address),
    stateCode: data.get(#stateCode, or: $value.stateCode),
    stateName: data.get(#stateName, or: $value.stateName),
    gstin: data.get(#gstin, or: $value.gstin),
    itemCount: data.get(#itemCount, or: $value.itemCount),
    totalQuantity: data.get(#totalQuantity, or: $value.totalQuantity),
    firstItem: data.get(#firstItem, or: $value.firstItem),
    reversesChallanId: data.get(
      #reversesChallanId,
      or: $value.reversesChallanId,
    ),
    reversesNumber: data.get(#reversesNumber, or: $value.reversesNumber),
    reversesFinancialYear: data.get(
      #reversesFinancialYear,
      or: $value.reversesFinancialYear,
    ),
    returnedByChallanId: data.get(
      #returnedByChallanId,
      or: $value.returnedByChallanId,
    ),
    returnedByNumber: data.get(#returnedByNumber, or: $value.returnedByNumber),
    returnedByFinancialYear: data.get(
      #returnedByFinancialYear,
      or: $value.returnedByFinancialYear,
    ),
    items: data.get(#items, or: $value.items),
  );

  @override
  ChallanCopyWith<$R2, Challan, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ChallanCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

