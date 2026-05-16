import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

enum OrderState { idle, loading, success, error }

class OrderController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  OrderState _state = OrderState.idle;
  String? _errorMessage;
  List<OrderModel> _orders = [];

  OrderState get state => _state;
  String? get errorMessage => _errorMessage;
  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _state == OrderState.loading;

  /// Fetch all orders for the current customer
  Future<void> fetchOrders(String customerId) async {
    try {
      _state = OrderState.loading;
      notifyListeners();

      final response = await _supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      _orders = (response as List)
          .map((map) => OrderModel.fromMap(map as Map<String, dynamic>))
          .toList();

      _state = OrderState.idle;
    } catch (e) {
      _state = OrderState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Create a new order (insert to Supabase + log to console)
  Future<bool> createOrder(OrderModel order) async {
    try {
      _state = OrderState.loading;
      _errorMessage = null;
      notifyListeners();

      // ── Log to console (debug) ──────────────────────────
      log('═══════════════════════════════════════');
      log('📦  NEW ORDER CREATED');
      log('  Customer ID   : ${order.customerId}');
      log('  Item Name     : ${order.itemName}');
      log('  Destination   : ${order.destinationAddress}');
      log('  Pickup Address: ${order.pickupAddress}');
      log('  Pickup LatLng : ${order.pickupLat}, ${order.pickupLng}');
      log('  Scheduled At  : ${order.scheduledPickup}');
      log('  Status        : ${order.status}');
      log('═══════════════════════════════════════');

      // ── Insert to Supabase ──────────────────────────────
      await _supabase.from('orders').insert(order.toMap());

      // Refresh list
      await fetchOrders(order.customerId);

      _state = OrderState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = OrderState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void resetState() {
    _state = OrderState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}