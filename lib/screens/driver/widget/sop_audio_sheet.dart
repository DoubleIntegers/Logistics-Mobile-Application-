import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/audio_service.dart';

/// Daftar SOP audio (gunakan URL publik sebagai contoh)
const _sopTracks = [
  _SopTrack(
    title: 'SOP Prosedur Pengiriman',
    subtitle: 'Panduan lengkap pengantaran paket',
    duration: '02:30',
    // Sample audio MP3 dari internet (CC0 / public domain)
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    icon: Icons.local_shipping_rounded,
    color: Color(0xFF0052CC),
  ),
  _SopTrack(
    title: 'SOP Handling Paket Fragile',
    subtitle: 'Cara menangani barang pecah belah',
    duration: '01:45',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFFFF6B35),
  ),
  _SopTrack(
    title: 'SOP Bukti Pengiriman',
    subtitle: 'Cara foto bukti yang benar',
    duration: '01:15',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    icon: Icons.photo_camera_rounded,
    color: Color(0xFF00875A),
  ),
];

class _SopTrack {
  final String title;
  final String subtitle;
  final String duration;
  final String url;
  final IconData icon;
  final Color color;

  const _SopTrack({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.url,
    required this.icon,
    required this.color,
  });
}

void showSopAudioSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => AudioService(),
      child: const _SopSheetContent(),
    ),
  );
}

class _SopSheetContent extends StatefulWidget {
  const _SopSheetContent();

  @override
  State<_SopSheetContent> createState() => _SopSheetContentState();
}

class _SopSheetContentState extends State<_SopSheetContent> {
  int _activeIndex = -1;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A2E)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(
          children: [
            // ── Handle ────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052CC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.headphones_rounded,
                        color: Color(0xFF0052CC), size: 22),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Panduan SOP Audio',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        Text('Standar Operasional Prosedur Driver',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: colorScheme.onSurface
                                    .withOpacity(0.5))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () async {
                      await audio.stop();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Track List ────────────────────────────────
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: _sopTracks.length,
                separatorBuilder: (_, __) => const Gap(10),
                itemBuilder: (_, i) {
                  final track = _sopTracks[i];
                  final isActive = _activeIndex == i;
                  return _TrackTile(
                    track: track,
                    isActive: isActive,
                    audio: audio,
                    onTap: () async {
                      if (!isActive) {
                        setState(() => _activeIndex = i);
                        await audio.stop();
                        await audio.load(track.url);
                        await audio.play();
                      } else {
                        await audio.togglePlayPause();
                      }
                    },
                  );
                },
              ),
            ),

            // ── Player Controls (shown when active) ──────
            if (_activeIndex >= 0)
              _PlayerControls(
                audio: audio,
                track: _sopTracks[_activeIndex],
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final _SopTrack track;
  final bool isActive;
  final AudioService audio;
  final VoidCallback onTap;

  const _TrackTile({
    required this.track,
    required this.isActive,
    required this.audio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isActive
            ? track.color.withOpacity(0.08)
            : (isDark
                ? const Color(0xFF242436)
                : const Color(0xFFF8F9FA)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? track.color.withOpacity(0.4)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Track icon / play state indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: track.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isActive && audio.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: track.color,
                        ),
                      )
                    : isActive && audio.isPlaying
                        ? _WaveformIcon(color: track.color)
                        : Icon(track.icon,
                            color: track.color, size: 22),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isActive ? track.color : null)),
                    const Gap(3),
                    Text(track.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.55)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(track.duration,
                  style: GoogleFonts.firaCode(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4))),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformIcon extends StatefulWidget {
  final Color color;
  const _WaveformIcon({required this.color});

  @override
  State<_WaveformIcon> createState() => _WaveformIconState();
}

class _WaveformIconState extends State<_WaveformIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _WaveformPainter(
              progress: _ctrl.value, color: widget.color),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const bars = 4;
    final barWidth = size.width / (bars * 2 - 1);

    for (int i = 0; i < bars; i++) {
      final phase = (progress + i * 0.25) % 1.0;
      final barHeight =
          (sin(phase * 2 * pi) * 0.5 + 0.5) * size.height * 0.75 +
              size.height * 0.1;
      final x = i * barWidth * 2 + barWidth / 2;
      final y = (size.height - barHeight) / 2;

      canvas.drawLine(
          Offset(x, y), Offset(x, y + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress;
}

class _PlayerControls extends StatelessWidget {
  final AudioService audio;
  final _SopTrack track;
  final bool isDark;

  const _PlayerControls({
    required this.audio,
    required this.track,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121E) : Colors.grey.shade50,
        border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Track info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: track.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(track.icon, color: track.color, size: 16),
              ),
              const Gap(10),
              Expanded(
                child: Text(track.title,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              // Volume
              IconButton(
                icon: Icon(
                  audio.volume > 0.5
                      ? Icons.volume_up_rounded
                      : audio.volume > 0
                          ? Icons.volume_down_rounded
                          : Icons.volume_off_rounded,
                  size: 20,
                ),
                onPressed: () => audio.setVolume(
                    audio.volume > 0 ? 0.0 : 1.0),
              ),
            ],
          ),

          const Gap(12),

          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: track.color,
              inactiveTrackColor: track.color.withOpacity(0.2),
              thumbColor: track.color,
              overlayColor: track.color.withOpacity(0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: audio.progress,
              onChanged: (v) => audio.seekByFraction(v),
            ),
          ),

          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(audio.positionLabel,
                    style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5))),
                Text(audio.durationLabel,
                    style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5))),
              ],
            ),
          ),

          const Gap(8),

          // Play/Pause + Stop controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind 10s
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                onPressed: () => audio.seek(Duration(
                    milliseconds: max(
                        0,
                        audio.position.inMilliseconds -
                            10000))),
              ),

              const Gap(8),

              // Play / Pause main button
              GestureDetector(
                onTap: audio.isLoading
                    ? null
                    : audio.togglePlayPause,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: track.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: track.color.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2)
                    ],
                  ),
                  child: audio.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white),
                        )
                      : Icon(
                          audio.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),

              const Gap(8),

              // Forward 10s
              IconButton(
                icon: const Icon(Icons.forward_10_rounded),
                onPressed: () => audio.seek(Duration(
                    milliseconds: min(
                        audio.duration.inMilliseconds,
                        audio.position.inMilliseconds +
                            10000))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}