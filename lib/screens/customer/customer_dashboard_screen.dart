import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../core/theme/app_theme.dart';
import 'create_order_screen.dart';

/// Hardcoded default pickup location — Surabaya, East Java
const _defaultPickup = LatLng(-7.2575, 112.7521);

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Fetch orders after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        context.read<OrderController>().fetchOrders(user.id);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final orders = context.watch<OrderController>();
    final user = auth.currentUser!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LogiTrack',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          Consumer<ThemeController>(
            builder: (context, themeCtrl, _) => IconButton(
              icon: Icon(themeCtrl.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded),
              onPressed: themeCtrl.toggle,
              tooltip: 'Toggle tema',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Buat Order',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => orders.fetchOrders(user.id),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting Banner ──────────────────────────
              _GreetingBanner(name: user.name, colorScheme: colorScheme),

              // ── Map Section ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.location_on_rounded,
                      label: 'Titik Penjemputan Default',
                      color: colorScheme.primary,
                    ),
                    const Gap(12),
                    _MapWidget(
                      isDark: isDark,
                      mapController: _mapController,
                      pickupPoint: _defaultPickup,
                    ),
                    const Gap(6),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.5)),
                        const Gap(6),
                        Text(
                          'Surabaya, Jawa Timur (-7.2575, 112.7521)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Recent Orders ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionTitle(
                  icon: Icons.receipt_long_rounded,
                  label: 'Order Terbaru',
                  color: colorScheme.secondary,
                ),
              ),
              const Gap(12),
              _OrderList(
                isLoading: orders.isLoading,
                orders: orders.orders,
              ),
              const Gap(100), // FAB clearance
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────

class _GreetingBanner extends StatelessWidget {
  final String name;
  final ColorScheme colorScheme;

  const _GreetingBanner({required this.name, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 17
            ? 'Selamat Siang'
            : 'Selamat Malam';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: Colors.white70),
                ),
                const Gap(2),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionTitle(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const Gap(8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MapWidget extends StatelessWidget {
  final bool isDark;
  final MapController mapController;
  final LatLng pickupPoint;

  const _MapWidget({
    required this.isDark,
    required this.mapController,
    required this.pickupPoint,
  });

  @override
  Widget build(BuildContext context) {
    // Dark mode uses a dark tile variant from OpenStreetMap-compatible provider
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: pickupPoint,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c'],
              tileProvider: CancellableNetworkTileProvider(),
              userAgentPackageName: 'com.example.logitrack',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pickupPoint,
                  width: 48,
                  height: 48,
                  child: const _PulseMarker(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scaleAnim = Tween(begin: 0.6, end: 1.4).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacityAnim = Tween(begin: 0.8, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0052CC)
                    .withOpacity(_opacityAnim.value),
              ),
            ),
          ),
        ),
        // Core dot
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF0052CC),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x440052CC),
                  blurRadius: 8,
                  spreadRadius: 2)
            ],
          ),
          child: const Icon(Icons.circle, color: Colors.white, size: 8),
        ),
      ],
    );
  }
}

class _OrderList extends StatelessWidget {
  final bool isLoading;
  final List orders;

  const _OrderList({required this.isLoading, required this.orders});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator()));
    }

    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(Icons.inbox_rounded,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3)),
              const Gap(12),
              Text(
                'Belum ada order',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5)),
              ),
              const Gap(4),
              Text(
                'Tekan "Buat Order" untuk memulai',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;

  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'on_delivery':
        return const Color(0xFF0052CC);
      case 'delivered':
        return const Color(0xFF00875A);
      default:
        return const Color(0xFFFF6B35);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'on_delivery':
        return 'Dalam Perjalanan';
      case 'delivered':
        return 'Terkirim';
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.inventory_2_rounded,
                  color: statusColor, size: 22),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.itemName,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const Gap(2),
                  Text(
                    order.destinationAddress,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                        .format(order.scheduledPickup),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45)),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                _statusLabel(order.status),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}