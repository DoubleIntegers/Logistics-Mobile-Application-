enum DeliveryStatus { pending, inTransit, delivered, failed }

extension DeliveryStatusExt on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Menunggu';
      case DeliveryStatus.inTransit:
        return 'Dalam Perjalanan';
      case DeliveryStatus.delivered:
        return 'Terkirim';
      case DeliveryStatus.failed:
        return 'Gagal';
    }
  }

  String get value {
    switch (this) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.inTransit:
        return 'in_transit';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.failed:
        return 'failed';
    }
  }
}

DeliveryStatus deliveryStatusFromString(String s) {
  switch (s) {
    case 'in_transit':
      return DeliveryStatus.inTransit;
    case 'delivered':
      return DeliveryStatus.delivered;
    case 'failed':
      return DeliveryStatus.failed;
    default:
      return DeliveryStatus.pending;
  }
}

class DeliveryTaskModel {
  final String id;
  final String orderId;
  final String driverId;
  final String receiptCode; // QR code content
  final String customerName;
  final String destinationAddress;
  final String itemName;
  final DeliveryStatus status;
  final String? proofImageUrl;
  final DateTime? deliveredAt;
  final DateTime createdAt;

  const DeliveryTaskModel({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.receiptCode,
    required this.customerName,
    required this.destinationAddress,
    required this.itemName,
    required this.status,
    this.proofImageUrl,
    this.deliveredAt,
    required this.createdAt,
  });

  DeliveryTaskModel copyWith({
    DeliveryStatus? status,
    String? proofImageUrl,
    DateTime? deliveredAt,
  }) =>
      DeliveryTaskModel(
        id: id,
        orderId: orderId,
        driverId: driverId,
        receiptCode: receiptCode,
        customerName: customerName,
        destinationAddress: destinationAddress,
        itemName: itemName,
        status: status ?? this.status,
        proofImageUrl: proofImageUrl ?? this.proofImageUrl,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        createdAt: createdAt,
      );

  factory DeliveryTaskModel.fromMap(Map<String, dynamic> map) =>
      DeliveryTaskModel(
        id: map['id'],
        orderId: map['order_id'],
        driverId: map['driver_id'],
        receiptCode: map['receipt_code'],
        customerName: map['customer_name'],
        destinationAddress: map['destination_address'],
        itemName: map['item_name'],
        status: deliveryStatusFromString(map['status']),
        proofImageUrl: map['proof_image_url'],
        deliveredAt: map['delivered_at'] != null
            ? DateTime.parse(map['delivered_at'])
            : null,
        createdAt: DateTime.parse(map['created_at']),
      );

  // ── Dummy tasks for testing ──
  static List<DeliveryTaskModel> get dummyList => [
        DeliveryTaskModel(
          id: 'task-001',
          orderId: 'order-001',
          driverId: 'driver-001',
          receiptCode: 'RESI-2024-001',
          customerName: 'Budi Santoso',
          destinationAddress: 'Jl. Ahmad Yani No.45, Sidoarjo, Jawa Timur',
          itemName: 'Laptop Asus ROG',
          status: DeliveryStatus.inTransit,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        DeliveryTaskModel(
          id: 'task-002',
          orderId: 'order-002',
          driverId: 'driver-001',
          receiptCode: 'RESI-2024-002',
          customerName: 'Dewi Rahayu',
          destinationAddress: 'Jl. Raya Waru No.12, Waru, Sidoarjo',
          itemName: 'Paket Dokumen',
          status: DeliveryStatus.inTransit,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        DeliveryTaskModel(
          id: 'task-003',
          orderId: 'order-003',
          driverId: 'driver-001',
          receiptCode: 'RESI-2024-003',
          customerName: 'Andi Wijaya',
          destinationAddress: 'Jl. Diponegoro No.88, Surabaya',
          itemName: 'Sepatu Nike',
          status: DeliveryStatus.delivered,
          proofImageUrl: 'https://via.placeholder.com/300',
          deliveredAt:
              DateTime.now().subtract(const Duration(hours: 1)),
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ];
}