class OrderModel {
  final String? id;
  final String customerId;
  final String itemName;
  final String destinationAddress;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final DateTime scheduledPickup;
  final String status; // 'pending' | 'on_delivery' | 'delivered'
  final DateTime? createdAt;

  const OrderModel({
    this.id,
    required this.customerId,
    required this.itemName,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.scheduledPickup,
    this.status = 'pending',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'customer_id': customerId,
        'item_name': itemName,
        'destination_address': destinationAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'pickup_address': pickupAddress,
        'scheduled_pickup': scheduledPickup.toIso8601String(),
        'status': status,
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'],
        customerId: map['customer_id'],
        itemName: map['item_name'],
        destinationAddress: map['destination_address'],
        pickupLat: (map['pickup_lat'] as num).toDouble(),
        pickupLng: (map['pickup_lng'] as num).toDouble(),
        pickupAddress: map['pickup_address'],
        scheduledPickup: DateTime.parse(map['scheduled_pickup']),
        status: map['status'] ?? 'pending',
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'])
            : null,
      );

  @override
  String toString() =>
      'OrderModel(id: $id, item: $itemName, dest: $destinationAddress, '
      'pickup: $scheduledPickup, status: $status)';
}