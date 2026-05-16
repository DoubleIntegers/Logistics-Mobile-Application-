import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/delivery_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/delivery_task_model.dart';
import 'delivery_detail_screen.dart';
import 'qr_scanner_screen.dart';
import 'widget/sop_audio_sheet.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openGlobalScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onDetected: (code) {
            final ctrl = context.read<DeliveryController>();
            final matched = ctrl.onQrScanned(code);
            if (!mounted) return;

            if (matched != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        DeliveryDetailScreen(task: matched)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('QR tidak dikenali: $code',
                    style: GoogleFonts.plusJakartaSans()),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
              ));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final delivery = context.watch<DeliveryController>();
    final user = auth.currentUser!;
    final colorScheme = Theme.of(context).colorScheme;

    final active = delivery.activeTasks;
    final completed = delivery.completedTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Panel',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800)),
        actions: [
          Consumer<ThemeController>(
            builder: (ctx, themeCtrl, _) => IconButton(
              icon: Icon(themeCtrl.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded),
              onPressed: themeCtrl.toggle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: auth.logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              GoogleFonts.plusJakartaSans(),
          indicatorColor: colorScheme.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 16),
                  const Gap(6),
                  Text('Aktif (${active.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16),
                  const Gap(6),
                  Text('Selesai (${completed.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- MULAI PASTE DI SINI ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Tombol Bantuan/SOP ──────────────────────
          FloatingActionButton(
            heroTag: 'sop_btn',
            mini: true,
            onPressed: () => showSopAudioSheet(context), // Pastikan fungsi ini sudah kamu buat dari prompt audio
            backgroundColor: const Color(0xFF6554C0),
            foregroundColor: Colors.white,
            tooltip: 'Panduan SOP',
            child: const Icon(Icons.headphones_rounded),
          ),
          const Gap(12),
          // ── Tombol Scan (existing) ──────────────────
          FloatingActionButton.extended(
            heroTag: 'scan_btn',
            onPressed: _openGlobalScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              'Scan Resi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
          ),
        ],
      ),
      // --- AKHIR PASTE ---

      body: Column(
        children: [
          // Stats row
          _StatsRow(
              active: active.length,
              completed: completed.length,
              name: user.name),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(
                    tasks: active,
                    emptyIcon: Icons.local_shipping_rounded,
                    emptyMsg: 'Tidak ada pengiriman aktif'),
                _TaskList(
                    tasks: completed,
                    emptyIcon: Icons.done_all_rounded,
                    emptyMsg: 'Belum ada pengiriman selesai'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int active;
  final int completed;
  final String name;

  const _StatsRow(
      {required this.active,
      required this.completed,
      required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35),
            const Color(0xFFFF8C42)
          ],
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
                Text('Halo, $name 🚛',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const Gap(4),
                Text('Semangat mengantarkan hari ini!',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          _StatChip(label: 'Aktif', value: '$active',
              icon: Icons.local_shipping_rounded),
          const Gap(10),
          _StatChip(label: 'Selesai', value: '$completed',
              icon: Icons.check_circle_rounded),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const Gap(2),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<DeliveryTaskModel> tasks;
  final IconData emptyIcon;
  final String emptyMsg;

  const _TaskList(
      {required this.tasks,
      required this.emptyIcon,
      required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon,
                size: 52,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.25)),
            const Gap(12),
            Text(emptyMsg,
                style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (ctx, i) => _TaskCard(task: tasks[i]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DeliveryTaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDelivered = task.status == DeliveryStatus.delivered;
    final color = isDelivered
        ? const Color(0xFF00875A)
        : const Color(0xFF0052CC);

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DeliveryDetailScreen(task: task)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDelivered
                      ? Icons.verified_rounded
                      : Icons.local_shipping_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.itemName,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const Gap(2),
                    Text(task.customerName,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6))),
                    const Gap(4),
                    Row(
                      children: [
                        Icon(Icons.qr_code_2,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4)),
                        const Gap(4),
                        Text(task.receiptCode,
                            style: GoogleFonts.firaCode(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.45))),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}