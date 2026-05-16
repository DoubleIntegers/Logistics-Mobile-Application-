import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/delivery_controller.dart';
import '../../models/delivery_task_model.dart';
import 'qr_scanner_screen.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final DeliveryTaskModel task;

  const DeliveryDetailScreen({super.key, required this.task});

  @override
  State<DeliveryDetailScreen> createState() =>
      _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  late DeliveryTaskModel _task;
  File? _proofImage;
  bool _qrVerified = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  // ── QR Scanner ─────────────────────────────────────────

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onDetected: _handleQrDetected,
        ),
      ),
    );
  }

  void _handleQrDetected(String code) {
    final ctrl = context.read<DeliveryController>();
    final matched = ctrl.onQrScanned(code);

    if (!mounted) return;

    if (matched != null && matched.id == _task.id) {
      setState(() => _qrVerified = true);
      _showSnack('✅ Resi ${matched.receiptCode} berhasil diverifikasi!',
          isError: false);
    } else if (matched == null) {
      _showSnack(
          '⚠️ QR tidak dikenali: $code',
          isError: true);
    } else {
      _showSnack(
          '⚠️ QR cocok dengan paket lain: ${matched.itemName}',
          isError: true);
    }
  }

  // ── Image Picker ────────────────────────────────────────

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (xFile != null) {
      setState(() => _proofImage = File(xFile.path));
    }
  }

  Future<ImageSource?> _showImageSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            Text(
              'Ambil Foto Bukti',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: const Color(0xFF0052CC),
                    onTap: () =>
                        Navigator.pop(ctx, ImageSource.camera),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: const Color(0xFF6554C0),
                    onTap: () =>
                        Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm Delivery ───────────────────────────────────

  Future<void> _confirmDelivery() async {
    if (!_qrVerified) {
      _showSnack('Scan QR resi terlebih dahulu', isError: true);
      return;
    }
    if (_proofImage == null) {
      _showSnack('Ambil foto bukti pengiriman terlebih dahulu',
          isError: true);
      return;
    }

    final success =
        await context.read<DeliveryController>().confirmDelivery(
              taskId: _task.id,
              imageFile: _proofImage!,
            );

    if (!mounted) return;

    if (success) {
      // Update local task state
      setState(() {
        _task = _task.copyWith(
          status: DeliveryStatus.delivered,
          deliveredAt: DateTime.now(),
        );
      });
      _showSnack('🎉 Pengiriman berhasil dikonfirmasi!',
          isError: false);
    } else {
      final err =
          context.read<DeliveryController>().errorMessage;
      _showSnack(err ?? 'Gagal konfirmasi', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.plusJakartaSans()),
      backgroundColor:
          isError ? Colors.red.shade700 : const Color(0xFF00875A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DeliveryController>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDelivered = _task.status == DeliveryStatus.delivered;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Pengiriman',
          style:
              GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Banner ──────────────────────────────
            _StatusBanner(status: _task.status),
            const Gap(20),

            // ── Info Card ──────────────────────────────────
            _InfoCard(task: _task),
            const Gap(20),

            if (!isDelivered) ...[
              // ── Step 1: QR Scan ────────────────────────
              _StepCard(
                step: 1,
                title: 'Scan QR Resi',
                subtitle: 'Verifikasi paket dengan scan QR',
                isDone: _qrVerified,
                doneLabel:
                    'Resi ${_task.receiptCode} terverifikasi',
                child: ElevatedButton.icon(
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(
                    _qrVerified ? 'Scan Ulang' : 'Scan Resi',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _qrVerified
                        ? const Color(0xFF00875A)
                        : colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const Gap(16),

              // ── Step 2: Foto Bukti ─────────────────────
              _StepCard(
                step: 2,
                title: 'Foto Bukti Pengiriman',
                subtitle: 'Ambil foto saat menyerahkan paket',
                isDone: _proofImage != null,
                doneLabel: 'Foto bukti siap diupload',
                child: Column(
                  children: [
                    // Preview image
                    if (_proofImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _proofImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Gap(12),
                    ],
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(_proofImage != null
                          ? Icons.refresh_rounded
                          : Icons.camera_alt_rounded),
                      label: Text(
                        _proofImage != null
                            ? 'Ganti Foto'
                            : 'Ambil Foto',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _proofImage != null
                            ? const Color(0xFF00875A)
                            : const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // ── Step 3: Upload & Confirm ───────────────
              _StepCard(
                step: 3,
                title: 'Konfirmasi Pengiriman',
                subtitle: 'Upload bukti & ubah status ke Terkirim',
                isDone: false,
                child: ctrl.isUploading
                    ? _UploadProgress(progress: ctrl.uploadProgress)
                    : ElevatedButton.icon(
                        onPressed: (_qrVerified && _proofImage != null)
                            ? _confirmDelivery
                            : null,
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          'Konfirmasi Terkirim',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00875A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor:
                              Colors.grey.shade300,
                        ),
                      ),
              ),
            ] else ...[
              // ── Delivered View ─────────────────────────
              _DeliveredCard(task: _task),
            ],

            const Gap(40),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final DeliveryStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == DeliveryStatus.delivered;
    final color = isDelivered
        ? const Color(0xFF00875A)
        : const Color(0xFF0052CC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered
                  ? Icons.check_circle_rounded
                  : Icons.local_shipping_rounded,
              color: color,
              size: 22,
            ),
          ),
          const Gap(12),
          Text(
            status.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final DeliveryTaskModel task;
  const _InfoCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _InfoRow(
                icon: Icons.qr_code_2_rounded,
                label: 'Kode Resi',
                value: task.receiptCode,
                valueStyle: GoogleFonts.firaCode(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const Divider(height: 20),
            _InfoRow(
                icon: Icons.inventory_2_rounded,
                label: 'Nama Barang',
                value: task.itemName),
            const Divider(height: 20),
            _InfoRow(
                icon: Icons.person_rounded,
                label: 'Penerima',
                value: task.customerName),
            const Divider(height: 20),
            _InfoRow(
                icon: Icons.place_rounded,
                label: 'Alamat Tujuan',
                value: task.destinationAddress),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueStyle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 18,
            color: colorScheme.onSurface.withOpacity(0.5)),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.5)),
              ),
              const Gap(2),
              Text(
                value,
                style: valueStyle ??
                    GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final bool isDone;
  final String? doneLabel;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.doneLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? const Color(0xFF00875A).withOpacity(0.4)
              : colorScheme.outline.withOpacity(0.12),
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF00875A)
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : Text(
                          '$step',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    Text(
                      isDone && doneLabel != null
                          ? doneLabel!
                          : subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDone
                            ? const Color(0xFF00875A)
                            : colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: isDone
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
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

class _UploadProgress extends StatelessWidget {
  final double progress;
  const _UploadProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mengupload bukti...',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7)),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const Gap(10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(
                Color(0xFF00875A)),
          ),
        ),
      ],
    );
  }
}

class _DeliveredCard extends StatelessWidget {
  final DeliveryTaskModel task;
  const _DeliveredCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00875A).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF00875A).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded,
              color: Color(0xFF00875A), size: 48),
          const Gap(12),
          Text(
            'Paket Berhasil Terkirim!',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00875A)),
          ),
          if (task.deliveredAt != null) ...[
            const Gap(6),
            Text(
              'pada ${_fmt(task.deliveredAt!)}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF00875A).withOpacity(0.7)),
            ),
          ],
          if (task.proofImageUrl != null) ...[
            const Gap(16),
            Text('Foto Bukti Pengiriman',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600)),
            const Gap(10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                task.proofImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade100,
                  child: const Center(
                      child: Icon(Icons.broken_image_rounded)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const Gap(8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}