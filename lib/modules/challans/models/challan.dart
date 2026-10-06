import 'package:dart_mappable/dart_mappable.dart';

import '../financial_year.dart';
import 'challan_direction.dart';
import 'challan_item.dart';

part 'challan.mapper.dart';

/// A challan as read from the `challans.challan_overview` view: the challan,
/// the client details it prints, its item totals, and the challan linked to
/// it by a cancellation.
@MappableClass()
class Challan with ChallanMappable {
  const Challan({
    required this.id,
    required this.direction,
    required this.financialYear,
    required this.number,
    required this.challanDate,
    required this.handledByName,
    this.vehicleNumber,
    this.declaredValue,
    this.notes,
    this.billNumber,
    this.receivedOn,
    required this.digitallySigned,
    this.cancelledAt,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    required this.clientId,
    required this.clientName,
    required this.addressId,
    required this.addressLabel,
    required this.addressVersion,
    required this.latestAddressVersion,
    required this.nameOnChallan,
    required this.address,
    required this.stateCode,
    required this.stateName,
    this.gstin,
    required this.itemCount,
    required this.totalQuantity,
    this.firstItem,
    this.reversesChallanId,
    this.reversesNumber,
    this.reversesFinancialYear,
    this.returnedByChallanId,
    this.returnedByNumber,
    this.returnedByFinancialYear,
    this.items = const [],
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'direction')
  final ChallanDirection direction;
  @MappableField(key: 'financial_year')
  final int financialYear;
  @MappableField(key: 'number')
  final int number;
  @MappableField(key: 'challan_date')
  final DateTime challanDate;

  /// Who delivered it (outward) or received it (inward).
  @MappableField(key: 'handled_by_name')
  final String handledByName;
  @MappableField(key: 'vehicle_number')
  final String? vehicleNumber;

  /// Whole rupees; printed as "does not exceed ₹…" when set.
  @MappableField(key: 'declared_value')
  final int? declaredValue;
  @MappableField(key: 'notes')
  final String? notes;

  // Outward follow-ups.
  @MappableField(key: 'bill_number')
  final String? billNumber;
  @MappableField(key: 'received_on')
  final DateTime? receivedOn;
  @MappableField(key: 'digitally_signed')
  final bool digitallySigned;

  @MappableField(key: 'cancelled_at')
  final DateTime? cancelledAt;
  @MappableField(key: 'cancel_reason')
  final String? cancelReason;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
  @MappableField(key: 'updated_at')
  final DateTime updatedAt;

  // The client and the exact address version printed.
  @MappableField(key: 'client_id')
  final String clientId;
  @MappableField(key: 'client_name')
  final String clientName;
  @MappableField(key: 'address_id')
  final String addressId;
  @MappableField(key: 'address_label')
  final String addressLabel;
  @MappableField(key: 'address_version')
  final int addressVersion;
  @MappableField(key: 'latest_address_version')
  final int latestAddressVersion;
  @MappableField(key: 'name_on_challan')
  final String nameOnChallan;
  @MappableField(key: 'address')
  final String address;
  @MappableField(key: 'state_code')
  final String stateCode;
  @MappableField(key: 'state_name')
  final String stateName;
  @MappableField(key: 'gstin')
  final String? gstin;

  @MappableField(key: 'item_count')
  final int itemCount;
  @MappableField(key: 'total_quantity')
  final int totalQuantity;
  @MappableField(key: 'first_item')
  final String? firstItem;

  /// On an inward challan made by cancelling an outward one: that one.
  @MappableField(key: 'reverses_challan_id')
  final String? reversesChallanId;
  @MappableField(key: 'reverses_number')
  final int? reversesNumber;
  @MappableField(key: 'reverses_financial_year')
  final int? reversesFinancialYear;

  /// On a cancelled outward challan: the inward one that brought it back.
  @MappableField(key: 'returned_by_challan_id')
  final String? returnedByChallanId;
  @MappableField(key: 'returned_by_number')
  final int? returnedByNumber;
  @MappableField(key: 'returned_by_financial_year')
  final int? returnedByFinancialYear;

  /// Not a column of the view: filled in only when one challan is fetched.
  @MappableField(key: 'items')
  final List<ChallanItem> items;

  bool get isCancelled => cancelledAt != null;
  bool get isOutward => direction == ChallanDirection.outward;

  /// The client's address has been edited since this challan was made.
  bool get hasNewerAddress => latestAddressVersion > addressVersion;

  /// "12 / 2026-27".
  String get numberLabel => challanNumberLabel(number, financialYear);

  /// "Dell laptop", "Dell laptop and 3 more".
  String get itemsSummary {
    final first = firstItem ?? '';
    if (itemCount <= 1) return first;
    return '$first and ${itemCount - 1} more';
  }
}
