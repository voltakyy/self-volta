// Rekam Aktivitas GPS: lari, jalan kaki, sepeda.
//
// Isi file:
// * [AktivitasCard]         — kartu di halaman Latihan (mulai / lanjutkan /
//                              ringkasan minggu / aktivitas terakhir)
// * [RekamAktivitasPage]    — layar rekam (durasi, jarak, pace, rute langsung)
// * [AktivitasDetailPage]   — ringkasan setelah selesai (Simpan / Buang) dan
//                              detail aktivitas tersimpan (split per km)
// * [RiwayatAktivitasPage]  — daftar semua aktivitas per bulan
// * [RouteView]             — gambar rute offline + peta OSM opsional
//
// Desain mengikuti docs/ui-guidelines.md: token Star/Paper, aksen pilar
// Workout (amber), Manrope, angka tabular, target sentuh ≥48dp, tanpa
// emoji, tema terang (pengecualian gelap hanya layar alarm).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../services/activity_math.dart';
import '../services/activity_recorder.dart';
import '../services/location_service.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

const _tab = [FontFeature.tabularFigures()];

IconData activityIcon(ActivityType t) => switch (t) {
  ActivityType.run => Icons.directions_run_rounded,
  ActivityType.walk => Icons.directions_walk_rounded,
  ActivityType.ride => Icons.directions_bike_rounded,
};

const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String _two(int v) => v.toString().padLeft(2, '0');

/// "Rabu, 18 Nov 2026 · 16.42"
String activityDateLabel(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1].substring(0, 3)} '
    '${d.year} · ${_two(d.hour)}.${_two(d.minute)}';

/// Pace atau kecepatan sesuai jenis aktivitas.
({String value, String unit, String label}) paceOf(
  ActivityType t,
  double meters,
  int sec,
) => t.usesSpeed
    ? (
        value: ActivityMath.speed(meters, sec),
        unit: 'km/jam',
        label: 'Kecepatan',
      )
    : (value: ActivityMath.pace(meters, sec), unit: '/km', label: 'Pace');

// ===========================================================================
// KARTU DI HALAMAN LATIHAN
// ===========================================================================

class AktivitasCard extends StatefulWidget {
  const AktivitasCard({super.key});

  @override
  State<AktivitasCard> createState() => _AktivitasCardState();
}

class _AktivitasCardState extends State<AktivitasCard> {
  ActivityType? _picked;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppState.I, ActivityRecorder.I]),
      builder: (context, _) {
        final st = AppState.I;
        final rec = ActivityRecorder.I;
        final type =
            _picked ??
            (st.activities.isNotEmpty
                ? st.activities.first.type
                : ActivityType.run);
        final last = st.activities.isEmpty ? null : st.activities.first;
        return Container(
          key: const Key('aktivitas-card'),
          padding: const EdgeInsets.all(16),
          decoration: Neu.raised(r: 20, d: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(Icons.route_rounded, Star.workout, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekam Lari, Jalan & Sepeda',
                          style: AppText.cardTitle.copyWith(color: Star.ink),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'GPS · rute · pace per km · jalan terus saat layar mati',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            height: 1.35,
                            color: Star.mut,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (rec.isActive)
                _LiveBanner(rec: rec)
              else ...[
                _WeekSummary(st: st),
                const SizedBox(height: 16),
                TypePicker(
                  value: type,
                  onChanged: (t) => setState(() => _picked = t),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  key: const Key('aktivitas-mulai'),
                  icon: Icons.play_arrow_rounded,
                  label: 'Mulai Rekam ${type.shortLabel}',
                  onTap: () {
                    iosTapBuzz();
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => RekamAktivitasPage(initialType: type),
                      ),
                    );
                  },
                ),
              ],
              if (last != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Star.lineSoft),
                const SizedBox(height: 8),
                ActivityRow(activity: last),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('aktivitas-riwayat'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: Star.star,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RiwayatAktivitasPage(),
                      ),
                    ),
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    iconAlignment: IconAlignment.end,
                    label: Text(
                      'Riwayat (${st.activities.length})',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WeekSummary extends StatelessWidget {
  final AppState st;
  const _WeekSummary({required this.st});

  @override
  Widget build(BuildContext context) {
    final week = st.activitiesThisWeek;
    final days = st.weekActivityDays.length;
    final sec = week.fold(0, (s, a) => s + a.movingSec);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: MiniStat(
                label: 'Minggu ini',
                value: ActivityMath.km(st.weekActivityMeters),
                unit: 'km',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MiniStat(
                label: 'Durasi',
                value: ActivityMath.clock(sec),
                unit: '',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MiniStat(label: 'Hari aktif', value: '$days', unit: '/7'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentTrack(count: 7, active: days.clamp(0, 7), color: Star.workout),
      ],
    );
  }
}

class _LiveBanner extends StatelessWidget {
  final ActivityRecorder rec;
  const _LiveBanner({required this.rec});

  @override
  Widget build(BuildContext context) {
    final recording = rec.state == RecState.recording;
    final title = rec.recovered
        ? 'Rekaman ${rec.type.label.toLowerCase()} terputus dipulihkan'
        : recording
        ? 'Sedang merekam ${rec.type.label.toLowerCase()}'
        : 'Rekaman ${rec.type.label.toLowerCase()} dijeda';
    return Container(
      key: const Key('aktivitas-live'),
      padding: const EdgeInsets.all(12),
      decoration: Neu.well(r: 14, color: Star.workoutSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: recording ? Star.error : Paper.amberInk,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Paper.amberInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${ActivityMath.km(rec.distanceM)} km · ${ActivityMath.clock(rec.elapsedSec)}',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Star.ink,
              fontFeatures: _tab,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('aktivitas-buka-rekam'),
            icon: Icons.open_in_full_rounded,
            label: 'Buka Layar Rekam',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RekamAktivitasPage(initialType: rec.type),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// KOMPONEN KECIL
// ===========================================================================

class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: Neu.well(r: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: Star.mut,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Star.ink,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Star.mut,
                      ),
                    ),
                ],
              ),
              style: const TextStyle(fontFamily: 'Manrope', fontFeatures: _tab),
            ),
          ),
        ],
      ),
    );
  }
}

class TypePicker extends StatelessWidget {
  final ActivityType value;
  final ValueChanged<ActivityType>? onChanged;
  const TypePicker({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final t in ActivityType.values) ...[
          if (t != ActivityType.values.first) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              selected: t == value,
              button: true,
              label: t.label,
              child: PopTap(
                key: Key('tipe-${t.name}'),
                onTap: onChanged == null
                    ? null
                    : () {
                        iosTapBuzz();
                        onChanged!(t);
                      },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: t == value ? Star.workoutSoft : Star.fill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: t == value ? Star.workout : Star.line,
                      width: t == value ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activityIcon(t),
                        size: 20,
                        color: t == value ? Paper.amberInk : Star.faint,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          t.shortLabel,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: t == value ? Paper.amberInk : Star.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tombol utama penuh lebar. [filled] = aksen amber; false = gaya tombol
/// sekunder dari guideline (latar Star.fill, border Star.line, teks ink).
class PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final double height;
  const PrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.filled = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Star.onAccent : Star.ink;
    return Semantics(
      button: true,
      label: label,
      child: PopTap(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: filled ? Star.workout : Star.fill,
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: Star.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: filled ? fg : Star.workout, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak statistik besar (layar rekam & detail).
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool estimate;
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.estimate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: Neu.flat(r: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            estimate ? '$label (perkiraan)' : label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: Star.mut,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Star.ink,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Star.mut,
                      ),
                    ),
                ],
              ),
              style: const TextStyle(fontFamily: 'Manrope', fontFeatures: _tab),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid 2 kolom yang tingginya mengikuti isi (aman di text scale 2.0).
class StatGrid extends StatelessWidget {
  final List<Widget> children;
  const StatGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ch in children) SizedBox(width: w, child: ch),
          ],
        );
      },
    );
  }
}

/// Baris aktivitas (kartu Latihan & riwayat).
class ActivityRow extends StatelessWidget {
  final GpsActivity activity;
  const ActivityRow({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final p = paceOf(a.type, a.distanceM, a.movingSec);
    return PopTap(
      key: Key('aktivitas-row-${a.id}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AktivitasDetailPage(activity: a),
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: RouteThumb(segments: a.segments, type: a.type),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Star.ink,
                    ),
                  ),
                  Text(
                    activityDateLabel(a.start),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: Star.mut,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ActivityMath.clock(a.movingSec)} · ${p.value} ${p.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Star.mut,
                      fontFeatures: _tab,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: ActivityMath.km(a.distanceM),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Star.ink,
                    ),
                  ),
                  const TextSpan(
                    text: ' km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Star.mut,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(fontFamily: 'Manrope', fontFeatures: _tab),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// RUTE
// ===========================================================================

/// Rute di kanvas offline, dengan tombol "Peta" untuk memuat ubin
/// OpenStreetMap di belakangnya bila ada internet. Bila ubin gagal dimuat,
/// garis rute tetap tergambar (PolylineLayer tidak bergantung ubin).
class RouteView extends StatefulWidget {
  final List<List<LatLngLite>> segments;
  final double height;
  final String emptyText;
  const RouteView({
    super.key,
    required this.segments,
    this.height = 220,
    this.emptyText = 'Rute muncul setelah GPS mengunci posisi.',
  });

  @override
  State<RouteView> createState() => _RouteViewState();
}

class _RouteViewState extends State<RouteView> {
  bool _map = false;

  @override
  Widget build(BuildContext context) {
    final pts = [for (final s in widget.segments) ...s];
    final hasRoute = pts.length >= 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Star.sunken,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Star.line),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: !hasRoute
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.satellite_alt_rounded,
                              color: Star.faint,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.emptyText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12.5,
                                color: Star.mut,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _map
                  ? _OsmMap(segments: widget.segments, points: pts)
                  : CustomPaint(
                      painter: RoutePainter(widget.segments, grid: true),
                    ),
            ),
            if (hasRoute)
              Positioned(
                top: 8,
                right: 8,
                child: Tooltip(
                  message: _map ? 'Sembunyikan peta' : 'Tampilkan peta (internet)',
                  child: PopTap(
                    key: const Key('rute-peta'),
                    onTap: () => setState(() => _map = !_map),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        minWidth: 48,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Star.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Star.line),
                        boxShadow: Neu.shadows(d: 4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _map ? Icons.layers_clear_rounded : Icons.map_rounded,
                            size: 18,
                            color: Star.star,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _map ? 'Garis' : 'Peta',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Star.star,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OsmMap extends StatelessWidget {
  final List<List<LatLngLite>> segments;
  final List<LatLngLite> points;
  const _OsmMap({required this.segments, required this.points});

  @override
  Widget build(BuildContext context) {
    ll.LatLng c(LatLngLite p) => ll.LatLng(p.lat, p.lng);
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: [for (final p in points) c(p)],
          padding: const EdgeInsets.all(32),
          maxZoom: 17,
        ),
        backgroundColor: Star.sunken,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.selfvolta.self_volta',
          maxNativeZoom: 19,
        ),
        PolylineLayer(
          polylines: [
            for (final s in segments)
              Polyline(
                points: [for (final p in s) c(p)],
                color: Star.workout,
                strokeWidth: 4,
                borderColor: Star.surface,
                borderStrokeWidth: 2,
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text(
            'OpenStreetMap contributors',
            style: TextStyle(fontFamily: 'Manrope', fontSize: 11),
          ),
          backgroundColor: Star.surface,
        ),
      ],
    );
  }
}

/// Miniatur rute untuk daftar (tanpa grid).
class RouteThumb extends StatelessWidget {
  final List<List<LatLngLite>> segments;
  final ActivityType type;
  const RouteThumb({super.key, required this.segments, required this.type});

  @override
  Widget build(BuildContext context) {
    final has = segments.fold(0, (s, x) => s + x.length) >= 2;
    return Container(
      decoration: Neu.well(r: 12),
      child: has
          ? CustomPaint(painter: RoutePainter(segments, stroke: 2.5, pad: 8))
          : Icon(activityIcon(type), color: Star.faint, size: 24),
    );
  }
}

/// Proyeksi equirectangular sederhana (cukup untuk rute beberapa km).
class RoutePainter extends CustomPainter {
  final List<List<LatLngLite>> segments;
  final bool grid;
  final double stroke;
  final double pad;
  RoutePainter(
    this.segments, {
    this.grid = false,
    this.stroke = 4,
    this.pad = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (grid) {
      final g = Paint()
        ..color = Star.lineSoft
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 24) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
      }
      for (var y = 0.0; y < size.height; y += 24) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
      }
    }
    final all = [for (final s in segments) ...s];
    if (all.isEmpty) return;
    var minLat = all.first.lat, maxLat = minLat;
    var minLng = all.first.lng, maxLng = minLng;
    for (final p in all) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    final k = math.cos(((minLat + maxLat) / 2) * math.pi / 180);
    final spanX = math.max((maxLng - minLng) * k, 1e-6);
    final spanY = math.max(maxLat - minLat, 1e-6);
    final availW = math.max(size.width - pad * 2, 1.0);
    final availH = math.max(size.height - pad * 2, 1.0);
    final scale = math.min(availW / spanX, availH / spanY);
    final offX = (size.width - spanX * scale) / 2;
    final offY = (size.height - spanY * scale) / 2;
    Offset proj(LatLngLite p) => Offset(
      offX + (p.lng - minLng) * k * scale,
      offY + (maxLat - p.lat) * scale,
    );

    final under = Paint()
      ..color = Star.surface
      ..strokeWidth = stroke + 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = Star.workout
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in segments) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(proj(s.first).dx, proj(s.first).dy);
      for (final p in s.skip(1)) {
        final o = proj(p);
        path.lineTo(o.dx, o.dy);
      }
      canvas
        ..drawPath(path, under)
        ..drawPath(path, line);
    }
    void dot(LatLngLite p, Color c) {
      final o = proj(p);
      final r = stroke + 2;
      canvas
        ..drawCircle(o, r + 2, Paint()..color = Star.surface)
        ..drawCircle(o, r, Paint()..color = c);
    }

    dot(all.first, Star.success);
    dot(all.last, Star.ink);
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      !identical(old.segments, segments) ||
      old.segments.length != segments.length;
}

// ===========================================================================
// LAYAR REKAM
// ===========================================================================

class RekamAktivitasPage extends StatefulWidget {
  final ActivityType initialType;
  const RekamAktivitasPage({super.key, this.initialType = ActivityType.run});

  @override
  State<RekamAktivitasPage> createState() => _RekamAktivitasPageState();
}

class _RekamAktivitasPageState extends State<RekamAktivitasPage> {
  late ActivityType _type = widget.initialType;
  bool _busy = false;

  ActivityRecorder get _rec => ActivityRecorder.I;

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    final gate = await _rec.start(_type);
    if (!mounted) return;
    setState(() => _busy = false);
    if (gate != LocationGate.ok) await _explainGate(gate);
  }

  Future<void> _resume() async {
    if (_busy) return;
    setState(() => _busy = true);
    final gate = await _rec.resume();
    if (!mounted) return;
    setState(() => _busy = false);
    if (gate != LocationGate.ok) await _explainGate(gate);
  }

  Future<void> _finish() async {
    if (_rec.distanceM < 50) {
      final buang = await _confirm(
        title: 'Rekaman terlalu pendek',
        body:
            'Jarak belum sampai 50 m, jadi tidak ada rute untuk disimpan. '
            'Buang rekaman ini?',
        yes: 'Buang',
        no: 'Kembali',
      );
      if (buang != true) return;
      await _rec.discard();
      if (mounted) Navigator.pop(context);
      return;
    }
    final act = await _rec.finish();
    if (act == null || !mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AktivitasDetailPage(activity: act, pending: true),
      ),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String yes,
    required String no,
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Star.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Star.ink,
        ),
      ),
      content: Text(
        body,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13.5,
          height: 1.4,
          color: Star.mut,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(no, style: const TextStyle(color: Star.mut)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            yes,
            style: const TextStyle(
              color: Star.star,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _explainGate(LocationGate g) async {
    final (title, body, action) = switch (g) {
      LocationGate.serviceOff => (
        'GPS mati',
        'Nyalakan Lokasi di HP supaya rute dan jarak bisa direkam.',
        'Buka Pengaturan Lokasi',
      ),
      LocationGate.deniedForever => (
        'Izin lokasi ditolak',
        'Izin lokasi sudah ditolak permanen. Buka pengaturan aplikasi, '
            'pilih Izin > Lokasi > "Izinkan hanya saat aplikasi digunakan".',
        'Buka Pengaturan App',
      ),
      LocationGate.denied => (
        'Butuh izin lokasi',
        'Rekam aktivitas memakai GPS hanya selama kamu merekam. '
            'Data rute tersimpan di HP ini saja.',
        'Coba Lagi',
      ),
      _ => (
        'GPS tidak tersedia',
        'Perangkat ini tidak punya GPS yang bisa dipakai aplikasi.',
        '',
      ),
    };
    final go = await _confirm(
      title: title,
      body: body,
      yes: action.isEmpty ? 'Tutup' : action,
      no: 'Batal',
    );
    if (go != true || action.isEmpty) return;
    switch (g) {
      case LocationGate.serviceOff:
        await LocationService.openLocationSettings();
      case LocationGate.deniedForever:
        await LocationService.openAppSettings();
      case LocationGate.denied:
        _rec.isActive ? await _resume() : await _start();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _rec,
      builder: (context, _) {
        final active = _rec.isActive;
        final type = active ? _rec.type : _type;
        final p = paceOf(type, _rec.distanceM, _rec.movingSec);
        final stateLabel = switch (_rec.state) {
          RecState.idle => 'Siap merekam',
          RecState.recording => 'Merekam',
          RecState.paused => 'Dijeda',
        };
        return Scaffold(
          backgroundColor: Star.bg,
          appBar: AppBar(
            backgroundColor: Star.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: 'Kembali (rekaman tetap berjalan)',
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Star.ink,
                size: 20,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekam ${type.label}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Star.ink,
                  ),
                ),
                Text(
                  stateLabel,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: Star.mut,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SignalPill(signal: _rec.signal),
                          if (_rec.recovered)
                            const _Pill(
                              icon: Icons.history_rounded,
                              text: 'Dipulihkan setelah app tertutup',
                              color: Paper.amberInk,
                              bg: Star.workoutSoft,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: Neu.raised(r: 20, d: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Durasi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                color: Star.mut,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                ActivityMath.clock(_rec.elapsedSec),
                                key: const Key('rekam-durasi'),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 56,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  color: Star.ink,
                                  fontFeatures: _tab,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            StatGrid(
                              children: [
                                StatTile(
                                  key: const Key('rekam-jarak'),
                                  label: 'Jarak',
                                  value: ActivityMath.km(_rec.distanceM),
                                  unit: 'km',
                                ),
                                StatTile(
                                  label: p.label,
                                  value: p.value,
                                  unit: p.unit,
                                ),
                                StatTile(
                                  label: 'Waktu bergerak',
                                  value: ActivityMath.clock(_rec.movingSec),
                                ),
                                StatTile(
                                  label: 'Km tuntas',
                                  value:
                                      '${_rec.track?.splitMarks.length ?? 0}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      RouteView(segments: _rec.track?.route ?? const []),
                      const SizedBox(height: 12),
                      const MarginNote(
                        'Layar boleh dimatikan: notifikasi "SELF VOLTA merekam" '
                        'menandakan GPS masih jalan. Bila HP mematikan app '
                        'diam-diam (mode hemat baterai), rekaman dipulihkan '
                        'saat app dibuka lagi.',
                        label: 'Tips',
                      ),
                    ],
                  ),
                ),
                _Controls(
                  state: _rec.state,
                  type: _type,
                  busy: _busy,
                  onType: (t) => setState(() => _type = t),
                  onStart: _start,
                  onPause: () {
                    iosTapBuzz();
                    _rec.pause();
                  },
                  onResume: _resume,
                  onFinish: _finish,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  final RecState state;
  final ActivityType type;
  final bool busy;
  final ValueChanged<ActivityType> onType;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  const _Controls({
    required this.state,
    required this.type,
    required this.busy,
    required this.onType,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Star.surface,
        border: Border(top: BorderSide(color: Star.line)),
      ),
      child: switch (state) {
        RecState.idle => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TypePicker(value: type, onChanged: onType),
            const SizedBox(height: 12),
            PrimaryButton(
              key: const Key('rekam-mulai'),
              icon: Icons.play_arrow_rounded,
              label: busy ? 'Menyiapkan GPS…' : 'Mulai',
              height: 56,
              onTap: busy ? null : onStart,
            ),
          ],
        ),
        RecState.recording => PrimaryButton(
          key: const Key('rekam-jeda'),
          icon: Icons.pause_rounded,
          label: 'Jeda',
          height: 56,
          onTap: onPause,
        ),
        RecState.paused => Row(
          children: [
            Expanded(
              child: PrimaryButton(
                key: const Key('rekam-lanjut'),
                icon: Icons.play_arrow_rounded,
                label: 'Lanjut',
                height: 56,
                onTap: busy ? null : onResume,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                key: const Key('rekam-selesai'),
                icon: Icons.flag_rounded,
                label: 'Selesai',
                height: 56,
                filled: false,
                onTap: onFinish,
              ),
            ),
          ],
        ),
      },
    );
  }
}

class _SignalPill extends StatelessWidget {
  final GpsSignal signal;
  const _SignalPill({required this.signal});

  @override
  Widget build(BuildContext context) {
    final (text, color, bg) = switch (signal) {
      GpsSignal.off => ('GPS belum aktif', Star.mut, Star.sunken),
      GpsSignal.searching => ('Mencari sinyal GPS…', Paper.amberInk, Star.workoutSoft),
      GpsSignal.weak => ('Sinyal GPS lemah', Paper.amberInk, Star.workoutSoft),
      GpsSignal.good => ('Sinyal GPS baik', Paper.mintDeep, Star.financeSoft),
    };
    return _Pill(
      icon: signal == GpsSignal.good
          ? Icons.gps_fixed_rounded
          : Icons.gps_not_fixed_rounded,
      text: text,
      color: color,
      bg: bg,
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;
  const _Pill({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// DETAIL / RINGKASAN
// ===========================================================================

class AktivitasDetailPage extends StatefulWidget {
  final GpsActivity activity;

  /// True = baru selesai direkam dan BELUM disimpan (tampil Simpan/Buang).
  final bool pending;
  const AktivitasDetailPage({
    super.key,
    required this.activity,
    this.pending = false,
  });

  @override
  State<AktivitasDetailPage> createState() => _AktivitasDetailPageState();
}

class _AktivitasDetailPageState extends State<AktivitasDetailPage> {
  late GpsActivity _a = widget.activity;
  late bool _pending = widget.pending;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final xp = await AppState.I.addActivity(_a);
    if (!mounted) return;
    final msg = xp > 0
        ? 'Tersimpan · +$xp XP'
        : _a.earnsXp
        ? 'Tersimpan · XP ${_a.type.label.toLowerCase()} hari ini sudah diklaim'
        : 'Tersimpan · minimal ${ActivityMath.km(_a.type.xpMinMeters.toDouble())} km untuk XP';
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
    _closeAfterDecision();
  }

  /// Lepas kunci PopScope dulu (rebuild), baru tutup halaman.
  void _closeAfterDecision() {
    setState(() => _pending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _discard() async {
    final ok = await _ask(
      'Buang aktivitas?',
      'Rute dan statistik rekaman ini akan hilang dan tidak bisa dikembalikan.',
      'Buang',
    );
    if (ok == true && mounted) _closeAfterDecision();
  }

  Future<void> _delete() async {
    final ok = await _ask(
      'Hapus aktivitas?',
      '"${_a.name}" dihapus dari riwayat. XP hari ini ikut ditarik bila '
          'tidak ada aktivitas sejenis lain hari ini.',
      'Hapus',
    );
    if (ok != true) return;
    await AppState.I.deleteActivity(_a.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _rename() async {
    final ctl = TextEditingController(text: _a.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Star.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nama aktivitas',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Star.ink,
          ),
        ),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 40,
          style: AppText.input,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Star.mut)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: const Text(
              'Simpan',
              style: TextStyle(color: Star.star, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    ctl.dispose();
    final n = name?.trim() ?? '';
    if (n.isEmpty || n == _a.name) return;
    setState(() => _a = _a.rename(n));
    if (!_pending) await AppState.I.renameActivity(_a.id, n);
  }

  Future<bool?> _ask(String title, String body, String yes) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Star.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Star.ink,
            ),
          ),
          content: Text(
            body,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13.5,
              height: 1.4,
              color: Star.mut,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Star.mut)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                yes,
                style: const TextStyle(
                  color: Star.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final p = paceOf(a.type, a.distanceM, a.movingSec);
    return PopScope(
      canPop: !_pending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_discard());
      },
      child: Scaffold(
        backgroundColor: Star.bg,
        appBar: AppBar(
          backgroundColor: Star.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Kembali',
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Star.ink,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pending ? 'Ringkasan Aktivitas' : a.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Star.ink,
                ),
              ),
              Text(
                activityDateLabel(a.start),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: Star.mut,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              key: const Key('detail-ubah-nama'),
              tooltip: 'Ubah nama',
              icon: const Icon(Icons.edit_rounded, color: Star.faint),
              onPressed: _rename,
            ),
            if (!_pending)
              IconButton(
                key: const Key('detail-hapus'),
                tooltip: 'Hapus aktivitas',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Star.faint,
                ),
                onPressed: _delete,
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (_pending) ...[
                      Row(
                        children: [
                          Icon(
                            activityIcon(a.type),
                            color: Star.workout,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.name,
                              style: AppText.sectionTitle.copyWith(
                                color: Star.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    RouteView(
                      segments: a.segments,
                      height: 240,
                      emptyText: 'Rute tidak terekam (sinyal GPS lemah).',
                    ),
                    const SizedBox(height: 12),
                    StatGrid(
                      children: [
                        StatTile(
                          label: 'Jarak',
                          value: ActivityMath.km(a.distanceM),
                          unit: 'km',
                        ),
                        StatTile(
                          label: 'Waktu bergerak',
                          value: ActivityMath.clock(a.movingSec),
                        ),
                        StatTile(
                          label: '${p.label} rata-rata',
                          value: p.value,
                          unit: p.unit,
                        ),
                        StatTile(
                          label: 'Waktu total',
                          value: ActivityMath.clock(a.elapsedSec),
                        ),
                        StatTile(
                          label: 'Elevasi naik',
                          value: a.elevGainM > 0
                              ? a.elevGainM.round().toString()
                              : '—',
                          unit: a.elevGainM > 0 ? 'm' : '',
                          estimate: true,
                        ),
                        StatTile(
                          label: 'Kalori',
                          value: a.kcal > 0 ? '${a.kcal}' : '—',
                          unit: a.kcal > 0 ? 'kkal' : '',
                          estimate: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SplitsCard(activity: a),
                    const SizedBox(height: 12),
                    MarginNote(
                      'XP ${a.type.label.toLowerCase()}: +${a.type.xpReward} '
                      'sekali per hari bila jarak ≥ '
                      '${ActivityMath.km(a.type.xpMinMeters.toDouble())} km. '
                      'Kalori memakai berat badan di Profil.',
                      label: 'Aturan XP',
                    ),
                  ],
                ),
              ),
              if (_pending)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Star.surface,
                    border: Border(top: BorderSide(color: Star.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('detail-buang'),
                          icon: Icons.delete_outline_rounded,
                          label: 'Buang',
                          filled: false,
                          onTap: _discard,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('detail-simpan'),
                          icon: Icons.check_rounded,
                          label: 'Simpan',
                          onTap: _saving ? null : _save,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitsCard extends StatelessWidget {
  final GpsActivity activity;
  const _SplitsCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final sp = a.splits;
    final fastest = sp.isEmpty ? 0 : sp.reduce(math.min);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HRow(
            Icons.timeline_rounded,
            'workout',
            'Split per km',
            a.type.usesSpeed ? 'Kecepatan tiap km' : 'Pace tiap km',
          ),
          const SizedBox(height: 8),
          if (sp.isEmpty)
            const Text(
              'Split muncul setelah 1 km pertama tuntas.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: Star.mut,
              ),
            )
          else
            for (var i = 0; i < sp.length; i++)
              Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        'Km ${i + 1}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12.5,
                          color: Star.mut,
                          fontFeatures: _tab,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          a.type.usesSpeed
                              ? ActivityMath.speed(1000, sp[i])
                              : ActivityMath.pace(1000, sp[i]),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: sp[i] == fastest ? Paper.amberInk : Star.ink,
                            fontFeatures: _tab,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 8,
                            width: c.maxWidth *
                                (sp[i] <= 0 ? 0 : (fastest / sp[i]))
                                    .clamp(0.08, 1.0),
                            decoration: BoxDecoration(
                              color: sp[i] == fastest
                                  ? Star.workout
                                  : Star.workoutBright.withValues(alpha: .45),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// ===========================================================================
// RIWAYAT
// ===========================================================================

class RiwayatAktivitasPage extends StatefulWidget {
  const RiwayatAktivitasPage({super.key});

  @override
  State<RiwayatAktivitasPage> createState() => _RiwayatAktivitasPageState();
}

class _RiwayatAktivitasPageState extends State<RiwayatAktivitasPage> {
  ActivityType? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Star.bg,
      appBar: AppBar(
        backgroundColor: Star.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Star.ink,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Riwayat Aktivitas',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Star.ink,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final list = [
            for (final a in AppState.I.activities)
              if (_filter == null || a.type == _filter) a,
          ];
          final meters = list.fold(0.0, (s, a) => s + a.distanceM);
          final sec = list.fold(0, (s, a) => s + a.movingSec);
          final children = <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final t in ActivityType.values)
                  _FilterChip(
                    label: t.shortLabel,
                    selected: _filter == t,
                    onTap: () => setState(() => _filter = t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MiniStat(
                    label: 'Total jarak',
                    value: ActivityMath.km(meters),
                    unit: 'km',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MiniStat(
                    label: 'Aktivitas',
                    value: '${list.length}',
                    unit: '',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MiniStat(
                    label: 'Waktu',
                    value: ActivityMath.clock(sec),
                    unit: '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ];
          if (list.isEmpty) {
            children.add(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Belum ada aktivitas. Mulai rekam dari halaman Latihan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.5,
                    color: Star.mut,
                  ),
                ),
              ),
            );
          }
          String? month;
          for (final a in list) {
            final m = '${_bulan[a.start.month - 1]} ${a.start.year}';
            if (m != month) {
              month = m;
              children.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: Text(
                    m,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Star.mut,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              );
            }
            children.add(
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: Neu.raised(r: 16, d: 4),
                child: ActivityRow(activity: a),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: children,
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: PopTap(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Star.workoutSoft : Star.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? Star.workout : Star.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Paper.amberInk : Star.ink,
            ),
          ),
        ),
      ),
    );
  }
}
