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
import '../../models/order_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

/// Default hardcoded pickup: Surabaya city center
const _defaultPickup = LatLng(-7.2575, 112.7521);
const _defaultPickupAddress = 'Jl. Tunjungan No.1, Surabaya, Jawa Timur';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _pickupAddressCtrl =
      TextEditingController(text: _defaultPickupAddress);

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _mapExpanded = true;

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _destinationCtrl.dispose();
    _pickupAddressCtrl.dispose();
    super.dispose();
  }

  // ── DateTime Picker ──────────────────────────────────────

  Future<void> _pickDateTime() async {
    // 1. Pick Date
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Pilih Tanggal Pickup',
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );

    if (date == null || !mounted) return;

    // 2. Pick Time
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Pilih Jam Pickup',
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );

    if (time == null || !mounted) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: const Color(0xFF0052CC),
            ),
      ),
      child: child!,
    );
  }

  String get _formattedDateTime {
    if (_selectedDate == null || _selectedTime == null) {
      return 'Pilih Jadwal Pickup';
    }
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return DateFormat("EEEE, dd MMMM yyyy – HH:mm", 'id_ID').format(dt);
  }

  bool get _hasDateTime =>
      _selectedDate != null && _selectedTime != null;

  // ── Submit ────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasDateTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Pilih jadwal pickup terlebih dahulu', isError: true),
      );
      return;
    }

    final user = context.read<AuthController>().currentUser!;
    final scheduledPickup = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final order = OrderModel(
      customerId: user.id,
      itemName: _itemNameCtrl.text.trim(),
      destinationAddress: _destinationCtrl.text.trim(),
      pickupLat: _defaultPickup.latitude,
      pickupLng: _defaultPickup.longitude,
      pickupAddress: _pickupAddressCtrl.text.trim(),
      scheduledPickup: scheduledPickup,
    );

    final success =
        await context.read<OrderController>().createOrder(order);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Order berhasil dibuat! 🎉', isError: false),
      );
      Navigator.pop(context);
    } else {
      final err = context.read<OrderController>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(err ?? 'Gagal membuat order', isError: true),
      );
    }
  }

  SnackBar _snackBar(String message, {required bool isError}) => SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF00875A),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      );

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final orderCtrl = context.watch<OrderController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buat Pesanan Baru',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section: Peta Pickup ──────────────────────
              _FormSection(
                icon: Icons.location_on_rounded,
                iconColor: colorScheme.primary,
                title: 'Titik Penjemputan',
                child: Column(
                  children: [
                    // Expandable map
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _mapExpanded ? 200 : 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _mapExpanded
                            ? _PickupMapPreview(isDark: isDark)
                            : const SizedBox(),
                      ),
                    ),
                    if (_mapExpanded) const Gap(10),
                    // Toggle map
                    GestureDetector(
                      onTap: () =>
                          setState(() => _mapExpanded = !_mapExpanded),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mapExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.map_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const Gap(4),
                          Text(
                            _mapExpanded ? 'Sembunyikan Peta' : 'Tampilkan Peta',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    // Pickup address field
                    TextFormField(
                      controller: _pickupAddressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Penjemputan',
                        prefixIcon:
                            Icon(Icons.my_location_rounded),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Alamat penjemputan wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),

              const Gap(20),

              // ── Section: Detail Barang ─────────────────────
              _FormSection(
                icon: Icons.inventory_2_rounded,
                iconColor: const Color(0xFFFF6B35),
                title: 'Detail Barang',
                child: TextFormField(
                  controller: _itemNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    hintText: 'Contoh: Laptop, Dokumen, Paket Kecil',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Nama barang wajib diisi'
                      : null,
                ),
              ),

              const Gap(20),

              // ── Section: Tujuan ───────────────────────────
              _FormSection(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFF00875A),
                title: 'Alamat Tujuan',
                child: TextFormField(
                  controller: _destinationCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Tujuan Lengkap',
                    hintText: 'Jl. Contoh No.123, Kota, Provinsi',
                    prefixIcon: Icon(Icons.place_rounded),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Alamat tujuan wajib diisi'
                      : null,
                ),
              ),

              const Gap(20),

              // ── Section: Jadwal Pickup ────────────────────
              _FormSection(
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFF6554C0),
                title: 'Jadwal Pickup',
                child: _DateTimePickerField(
                  isDark: isDark,
                  colorScheme: colorScheme,
                  hasDateTime: _hasDateTime,
                  formattedDateTime: _formattedDateTime,
                  onTap: _pickDateTime,
                ),
              ),

              const Gap(32),

              // ── Submit Button ─────────────────────────────
              ElevatedButton(
                onPressed: orderCtrl.isLoading ? null : _submit,
                child: orderCtrl.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 20),
                          const Gap(10),
                          Text(
                            'Buat Pesanan',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ],
                      ),
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable sub-widgets ──────────────────────────────────

class _FormSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _FormSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const Gap(10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Gap(14),
          child,
        ],
      ),
    );
  }
}

class _PickupMapPreview extends StatelessWidget {
  final bool isDark;

  const _PickupMapPreview({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    return FlutterMap(
      options: const MapOptions(
        initialCenter: _defaultPickup,
        initialZoom: 14,
        interactionOptions: InteractionOptions(
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
              point: _defaultPickup,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x440052CC),
                        blurRadius: 8,
                        spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.my_location_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateTimePickerField extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final bool hasDateTime;
  final String formattedDateTime;
  final VoidCallback onTap;

  const _DateTimePickerField({
    required this.isDark,
    required this.colorScheme,
    required this.hasDateTime,
    required this.formattedDateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E2E)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDateTime
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: hasDateTime ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6554C0).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Color(0xFF6554C0), size: 20),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Pickup',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const Gap(2),
                  Text(
                    formattedDateTime,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: hasDateTime
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: hasDateTime
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}