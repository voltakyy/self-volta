import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store.dart';
import 'theme.dart';
export 'data.dart' show rp;

/// Getaran sentuh halus khas iOS. Dibungkus aman agar tidak pernah
/// melempar di widget-test (tanpa plugin platform) maupun HP tanpa motor.
void iosTapBuzz() {
  Future(() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  });
}

/// Getaran selebrasi (triumph) saat menyelesaikan target / streak.
void triumphBuzz() {
  Future(() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  });
}

class AppIcon extends StatelessWidget {
  final IconData icon;
  final Color cat;
  final double size;
  const AppIcon(this.icon, this.cat, {super.key, this.size = 40});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      // Ikon duduk di dalam sumur cekung kecil.
      decoration: Neu.well(r: size * .32),
      child: Icon(icon, color: cat, size: size * .5),
    );
  }
}

/// Logo SELF VOLTA bergaya "Kinetic Volt": squircle gelap premium dengan
/// huruf V miring bergradien cyan→amber dan glow tipis. Dipakai di AppBar,
/// drawer, dan profil — satu glow per elemen.
class VLogo extends StatelessWidget {
  final double size;
  final double fontSize;
  const VLogo({super.key, this.size = 26, this.fontSize = 15});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(math.min(14, size * .42)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        border: Border.all(color: const Color(0x3338BDF8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: .30),
            blurRadius: size * .52,
            spreadRadius: size * .03,
          ),
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: .16),
            blurRadius: size * .34,
            offset: Offset(0, size * .10),
          ),
        ],
      ),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38BDF8), Color(0xFF22D3EE), Color(0xFFF59E0B)],
          stops: [0, .42, 1],
        ).createShader(rect),
        child: Transform.translate(
          offset: Offset(0, -size * .015),
          child: Text(
            'V',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: fontSize,
              height: 1.0,
              letterSpacing: -1.2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pembungkus tap "menonjol" (StarChart: animate interactive moments).
/// Ditekan → mengecil ke 0.94; dilepas → memantul balik melewati 1.0
/// (elastic) lalu settle. Satu-satunya sumber onTap adalah InkWell di dalam
/// (status highlight → animasi skala), jadi callback TIDAK pernah double-fire
/// — aman untuk toggle seperti centang makan / favorit.
class PopTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  const PopTap({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });
  @override
  State<PopTap> createState() => _PopTapState();
}

class _PopTapState extends State<PopTap> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1.0,
    lowerBound: 0.9,
    upperBound: 1.06,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() => _c.animateTo(
    0.98,
    duration: const Duration(milliseconds: 80),
    curve: Curves.easeOut,
  );
  void _up() => _c.animateTo(
    1.0,
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOut,
  );

  void _handleTap() {
    iosTapBuzz();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(scale: _c.value, child: child),
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          onTap: _handleTap,
          onHighlightChanged: (h) => h ? _down() : _up(),
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Judul halaman gaya iOS: tipis, kiri, tanpa kartu/glow.
/// Murni visual — tidak ada aksi navigasi (ExcludeSemantics).
class SecHead extends StatelessWidget {
  final String page;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const SecHead(
    this.page,
    this.icon,
    this.title,
    this.subtitle, {
    super.key,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = accOf(page);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(icon, size: 19, color: c),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.pageTitle),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppText.secondary.copyWith(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  const SoftCard({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.color,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding,
      // Blok utama = timbul. Baris di dalamnya tetap datar.
      decoration: Neu.raised(r: 22, d: 6, color: color),
      child: child,
    );
  }
}

class HRow extends StatelessWidget {
  final IconData icon;
  final String page;
  final String title;
  final String subtitle;
  const HRow(this.icon, this.page, this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, accOf(page), size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.25,
                  color: Star.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11.5,
                  height: 1.35,
                  color: Star.mut,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color page;
  final bool dark;
  const Pill(
    this.text, {
    super.key,
    this.page = Colors.transparent,
    this.dark = false,
  });
  @override
  Widget build(BuildContext context) {
    // Chip status: cekung tipis (tint aksen), atau isian aksen bila `dark`.
    final c = page == Colors.transparent ? Star.nebula : page;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? c
            : Color.alphaBlend(c.withValues(alpha: .12), Star.sunken),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: dark ? Star.onAccent : c,
        ),
      ),
    );
  }
}

class GradBar extends StatelessWidget {
  final double pct;
  final Color c1;
  final Color c2;
  final double height;
  const GradBar(this.pct, {super.key, Color? c1, Color? c2, this.height = 12})
    : c1 = c1 ?? Star.star,
      c2 = c2 ?? Star.star;
  @override
  Widget build(BuildContext context) {
    // Jalur cekung sejati + isian aksen datar.
    final r = height / 2;
    return NeuWell(
      radius: r,
      depth: height >= 10 ? 2.5 : 1.6,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: (pct.clamp(0, 100)) / 100,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c1,
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trek progres tersegmentasi (bukan gradien): jumlah segmen tetap supaya
/// perbandingan antar kartu terbaca cepat. Dipakai Beranda, Latihan, Air,
/// dan Uang agar bahasa visual progres sama di seluruh aplikasi.
class SegmentTrack extends StatelessWidget {
  final int count;
  final int active;
  final Color color;
  final double gap;
  final double height;

  const SegmentTrack({
    super.key,
    required this.count,
    required this.active,
    required this.color,
    this.gap = 3,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: i < active ? color : Star.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (i < count - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class RowItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Override line-height (mis. Keuangan pakai 1.7). Default ikut global.
  final double? lh;
  const RowItem(
    this.leading,
    this.title,
    this.subtitle, {
    super.key,
    this.trailing,
    this.onTap,
    this.lh,
  });
  @override
  Widget build(BuildContext context) {
    return PopTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Star.lineSoft)),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.5,
                        height: lh ?? 1.45,
                        color: CustomColors.mut,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class BigStat extends StatelessWidget {
  final String label;
  final String value;
  final Color cat;
  final Widget? icon;
  const BigStat(this.label, this.value, this.cat, {super.key, this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: Neu.raised(r: 18, d: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ?icon,
              if (icon != null) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CustomColors.mut,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Star.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class DecoWave extends StatelessWidget {
  final Color color;
  const DecoWave(this.color, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CustomPaint(painter: _WavePainter(color)),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final n = 600.0;
    for (double x = 0; x <= size.width; x += 1) {
      final y =
          size.height / 2 +
          (size.height / 2) * 0.9 * (x % (n / 2) < n / 4 ? 1 : -1) * 0.6;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color;
}

class EmptyHint extends StatelessWidget {
  final String text;
  const EmptyHint(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: CustomColors.mut, fontSize: 13),
      ),
    );
  }
}

/// Kartu info: ikon tinted + judul + isi lega (body 14/1.55).
/// Standar baca nyaman untuk semua blok deskripsi aplikasi.
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String page;
  final String title;
  final String body;
  final String? foot;
  const InfoCard({
    super.key,
    required this.icon,
    required this.page,
    required this.title,
    required this.body,
    this.foot,
  });
  @override
  Widget build(BuildContext context) {
    final c = accOf(page);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: Neu.raised(r: 22, d: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, c, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.cardTitle.copyWith(color: CustomColors.ink),
                ),
                const SizedBox(height: 8),
                Text(body, style: AppText.body),
                if (foot != null && foot!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(foot!, style: AppText.secondary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Label kecil uppercase dengan garis rambut horizontal di kanan.
class _RuleLabel extends StatelessWidget {
  final String text;
  const _RuleLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0.9,
              color: Star.star,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Divider(height: 1, thickness: 1, color: Star.line),
        ),
      ],
    );
  }
}

/// Catatan pinggir: penjelas yang menempel pada konten — datar, tanpa kartu,
/// tanpa ikon hias, tanpa bayangan. Label uppercase ditutup garis rambut
/// horizontal; body rata dengan konten, bukan menjorok seperti kutipan.
class MarginNote extends StatelessWidget {
  final String body;
  final String? label;
  final Widget? child;

  const MarginNote(this.body, {super.key, this.label, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[_RuleLabel(label!), const SizedBox(height: 6)],
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.55,
              color: Star.ink.withValues(alpha: 0.78),
            ),
          ),
          if (child != null) ...[const SizedBox(height: 8), child!],
        ],
      ),
    );
  }
}

class _RecipeStep {
  final String? section;
  final String text;
  const _RecipeStep(this.section, this.text);
}

/// Langkah masak sebagai daftar bernomor — bukan paragraf. Tag [MC] / [PL]
/// di data lama dipakai sebagai label metode (Magic Com / Panci listrik).
class RecipeSteps extends StatelessWidget {
  final String text;
  final String? label;

  const RecipeSteps(this.text, {super.key, this.label = 'Langkah masak'});

  @override
  Widget build(BuildContext context) {
    final steps = _parseRecipeSteps(text);
    if (steps.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final section = step.section;
      final isNewSection =
          section != null && (i == 0 || steps[i - 1].section != section);
      if (isNewSection) {
        if (i > 0) children.add(const SizedBox(height: 10));
        children.add(
          Text(
            section.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0.9,
              color: Star.mut,
            ),
          ),
        );
        children.add(const SizedBox(height: 6));
      }
      children.add(_RecipeStepRow(index: i + 1, text: step.text));
      if (i < steps.length - 1) children.add(const SizedBox(height: 8));
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[_RuleLabel(label!), const SizedBox(height: 8)],
          ...children,
        ],
      ),
    );
  }
}

class _RecipeStepRow extends StatelessWidget {
  final int index;
  final String text;

  const _RecipeStepRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: 0.2,
                color: Star.star,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: Star.ink.withValues(alpha: 0.82),
            ),
          ),
        ),
      ],
    );
  }
}

List<_RecipeStep> _parseRecipeSteps(String raw) {
  final steps = <_RecipeStep>[];
  final marker = RegExp(r'\[(MC|PL)\]');
  final matches = marker.allMatches(raw).toList();

  if (matches.isEmpty) {
    _appendRecipeSteps(steps, null, raw);
    return steps;
  }

  if (matches.first.start > 0) {
    _appendRecipeSteps(steps, null, raw.substring(0, matches.first.start));
  }
  for (var i = 0; i < matches.length; i++) {
    final start = matches[i].end;
    final end = i + 1 < matches.length ? matches[i + 1].start : raw.length;
    final section = matches[i].group(1) == 'MC' ? 'Magic Com' : 'Panci listrik';
    _appendRecipeSteps(steps, section, raw.substring(start, end));
  }
  return steps;
}

void _appendRecipeSteps(List<_RecipeStep> out, String? section, String chunk) {
  var text = chunk.trim();
  if (text.isEmpty) return;

  if (section == null) {
    final colon = text.indexOf(':');
    if (colon > 0 && colon <= 48) {
      final head = text.substring(0, colon).trim();
      if (head.isNotEmpty && !head.contains('.')) {
        section = head;
        text = text.substring(colon + 1).trim();
      }
    }
  }

  for (final sentence in _splitRecipeSentences(text)) {
    final s = sentence.trim();
    if (s.isEmpty) continue;
    // Catatan harga di akhir resep bukan langkah masak.
    if (s.contains('Rp') && !RegExp(r'\d+\s*(mnt|menit)').hasMatch(s)) {
      continue;
    }
    out.add(_RecipeStep(section, s));
  }
}

List<String> _splitRecipeSentences(String text) {
  final out = <String>[];
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    buffer.write(ch);
    if (ch == '.' || ch == '!' || ch == '?') {
      final hasNext = i + 1 < text.length;
      final next = hasNext ? text[i + 1] : ' ';
      if (!hasNext || next == ' ' || next == '\n') {
        final sentence = buffer.toString().trim();
        if (sentence.isNotEmpty) out.add(sentence);
        buffer.clear();
      }
    }
  }
  final rest = buffer.toString().trim();
  if (rest.isNotEmpty) out.add(rest);
  return out;
}

/// Poin fakta ringkas: tanda pisah kecil sebagai penanda, bukan ikon centang.
/// Dipakai untuk isi yang bukan urutan langkah — spesifikasi, patokan, isi rak.
class FactList extends StatelessWidget {
  final List<String> items;
  final String? label;

  const FactList(this.items, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[_RuleLabel(label!), const SizedBox(height: 8)],
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _FactRow(items[i]),
          ],
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String text;

  const _FactRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 16,
          child: Padding(
            padding: EdgeInsets.only(top: 0.5),
            child: Text(
              '—',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.55,
                color: Star.star,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: Star.ink.withValues(alpha: 0.82),
            ),
          ),
        ),
      ],
    );
  }
}

/// Daftar poin rapi pengganti teks <br>-an: check + baris lega.
class InfoList extends StatelessWidget {
  final List<String> items;
  final Color? check;
  const InfoList(this.items, {super.key, this.check});
  @override
  Widget build(BuildContext context) {
    final cc = check ?? Star.success;
    return Column(
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: cc, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: AppText.body)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Formatter untuk input angka nominal/rupiah dengan pemisah ribuan titik ('.')
/// Mengubah input mentah secara otomatis saat diketik (contoh: 50000 -> 50.000).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static String format(String text) {
    if (text.isEmpty) return '';
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return '';
    return clean.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final rawText = newValue.text;
    final cleanDigits = rawText.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = format(cleanDigits);

    // Hitung posisi kursor yang presisi agar kursor tetap natural saat mengetik/menghapus
    final cursorPosition = newValue.selection.end;
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPosition && i < rawText.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(rawText[i])) {
        digitsBeforeCursor++;
      }
    }

    int newCursorOffset = 0;
    int digitsCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (formatted[i] != '.') {
        digitsCount++;
      }
      if (digitsCount == digitsBeforeCursor) {
        newCursorOffset = i + 1;
        break;
      }
    }

    if (digitsBeforeCursor == 0) {
      newCursorOffset = 0;
    } else if (newCursorOffset == 0 || newCursorOffset > formatted.length) {
      newCursorOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}

// ============================================================================
// VISUAL DATA REPRESENTATION: CONCENTRIC 3-RING ACTIVITY & NUTRITION VISUALIZER
// ============================================================================

class ActivityTriRingWidget extends StatelessWidget {
  final double workoutProgress;
  final double nutritionProgress;
  final double waterProgress;
  final double size;

  const ActivityTriRingWidget({
    super.key,
    required this.workoutProgress,
    required this.nutritionProgress,
    required this.waterProgress,
    this.size = 136,
  });

  @override
  Widget build(BuildContext context) {
    final avgPct =
        (((workoutProgress + nutritionProgress + waterProgress) / 3.0) * 100)
            .round();
    return Row(
      children: [
        // Concentric Rings
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _TriRingPainter(
                  workoutProgress: workoutProgress,
                  nutritionProgress: nutritionProgress,
                  waterProgress: waterProgress,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$avgPct%',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: Paper.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Text(
                    'Tuntas',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Paper.sec,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Legend List with Exact Metrics
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(
                color: Star.star,
                label: 'Latihan',
                pct: (workoutProgress * 100).round(),
                icon: Icons.fitness_center_rounded,
              ),
              const SizedBox(height: 10),
              _legendItem(
                color: Paper.amber,
                textColor: Paper.amberInk,
                label: 'Nutrisi',
                pct: (nutritionProgress * 100).round(),
                icon: Icons.soup_kitchen_rounded,
              ),
              const SizedBox(height: 10),
              _legendItem(
                color: Paper.mint,
                textColor: Paper.mintDeep,
                label: 'Hidrasi',
                pct: (waterProgress * 100).round(),
                icon: Icons.water_drop_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required int pct,
    required IconData icon,
    Color? textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Paper.ink,
            ),
          ),
        ),
        Text(
          '$pct%',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor ?? color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TriRingPainter extends CustomPainter {
  final double workoutProgress;
  final double nutritionProgress;
  final double waterProgress;

  const _TriRingPainter({
    required this.workoutProgress,
    required this.nutritionProgress,
    required this.waterProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    const strokeW = 8.5;
    final r1 = (size.width / 2) - 8;
    final r2 = (size.width / 2) - 21;
    final r3 = (size.width / 2) - 34;

    _drawRing(canvas, center, r1, strokeW, Star.star, workoutProgress);
    _drawRing(canvas, center, r2, strokeW, Paper.amber, nutritionProgress);
    _drawRing(canvas, center, r3, strokeW, Paper.mint, waterProgress);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeW,
    Color color,
    double progress,
  ) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0.01) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;

      final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TriRingPainter oldDelegate) =>
      oldDelegate.workoutProgress != workoutProgress ||
      oldDelegate.nutritionProgress != nutritionProgress ||
      oldDelegate.waterProgress != waterProgress;
}

// ============================================================================
// EPIC GAMIFICATION: FULL-SCREEN CONFETTI & LEVEL-UP CELEBRATION
// ============================================================================

void showEpicCelebrationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required int xpReward,
}) {
  triumphBuzz();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    pageBuilder: (ctx, anim1, anim2) => _EpicCelebrationView(
      title: title,
      message: message,
      xpReward: xpReward,
    ),
  );
}

class _EpicCelebrationView extends StatefulWidget {
  final String title;
  final String message;
  final int xpReward;

  const _EpicCelebrationView({
    required this.title,
    required this.message,
    required this.xpReward,
  });

  @override
  State<_EpicCelebrationView> createState() => _EpicCelebrationViewState();
}

class _EpicCelebrationViewState extends State<_EpicCelebrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final rng = math.Random();
    const colors = [
      Color(0xffE5A910),
      Color(0xff0781D1),
      Color(0xff00B074),
      Color(0xff8A63B0),
      Color(0xffD64545),
      Color(0xff3EA9E8),
    ];
    for (var i = 0; i < 48; i++) {
      _particles.add(
        _ConfettiParticle(
          x: rng.nextDouble(),
          y: rng.nextDouble() * -0.5,
          vx: (rng.nextDouble() - 0.5) * 0.4,
          vy: 0.3 + rng.nextDouble() * 0.7,
          size: 6 + rng.nextDouble() * 8,
          rotation: rng.nextDouble() * math.pi * 2,
          color: colors[rng.nextInt(colors.length)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    final currentLevel = st.level;
    final xpInLvl = st.xpInLevel;

    return Scaffold(
      backgroundColor: const Color(0xD0101215),
      body: Stack(
        children: [
          // Confetti particles canvas
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _ctrl.value,
              ),
            ),
          ),
          // Celebration Card Center
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: Neu.raised(r: 30, d: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Medali: lingkaran timbul + ikon aksen (tanpa emoji/glow).
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: Neu.raised(r: 42, d: 6),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 42,
                        color: Star.star,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Hadiah XP: sumur cekung dengan angka aksen.
                    NeuWell(
                      radius: 100,
                      depth: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      child: Text(
                        '+${widget.xpReward} XP',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Star.star,
                          letterSpacing: 0.4,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Star.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: Star.mut,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gamification Level & XP Progress Card
                    NeuWell(
                      radius: 18,
                      depth: 3,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lv. $currentLevel • ${st.levelTitle}',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Star.ink,
                                ),
                              ),
                              Text(
                                '$xpInLvl / 100 XP',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Star.star,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GradBar(
                            (xpInLvl / 100.0).clamp(0.0, 1.0) * 100,
                            height: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${st.streak} hari berturut-turut aktif',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Star.mut,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: Star.star,
                          foregroundColor: Star.onAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Lanjutkan',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  double x, y, vx, vy, size, rotation;
  Color color;
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final px = (p.x + (p.vx * progress)) % 1.0 * size.width;
      final py = (p.y + (p.vy * progress)) % 1.0 * size.height;
      final paint = Paint()..color = p.color;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + (progress * math.pi * 4));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

// ============================================================================
// FOKUS TUBUH (TARGETED MUSCLE GROUPS) - REFERENSI HOMEPAGE/FITNESS APP
// ============================================================================

class MuscleFocusCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;
  final String timeTag;
  final String exerciseCount;
  final String xpTag;

  const MuscleFocusCard({
    super.key,
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.onTap,
    this.timeTag = '12-15 Mnt',
    this.exerciseCount = '4 Gerakan',
    this.xpTag = '+50 XP',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          iosTapBuzz();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: Neu.raised(r: 22, d: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon Glowing + XP Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Star.star,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Star.onAccent, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Star.star.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Star.star.withValues(alpha: 0.4),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          xpTag,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Paper.amberInk,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: Star.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Star.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),

              // Meta ringkas: satu baris, tanpa ikon hias.
              Text(
                '${exerciseCount.toLowerCase()} · ${timeTag.toLowerCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10.5,
                  color: Star.ink.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // UNMISTAKABLE BUTTON AFFORDANCE (USER PASTI NOTICE TOMBOL INI!)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Star.star,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: Star.onAccent,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Mulai Sesi',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Star.onAccent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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

// ============================================================================
// SISTEM PANDUAN & TUTORIAL INTERAKTIF BERBASIS SPOTLIGHT & ANIMATED ARROW
// ============================================================================

/// Slot aksi bergaris putus-putus di akhir sebuah daftar (pola agenda):
/// satu-satunya tempat "menambah" tanpa membuat kartu baru di dalam kartu.
///
/// Tinggi dipatok supaya ritme baris tidak bergeser saat label berubah,
/// dan teks di dalamnya di-FittedBox agar tetap utuh pada font scale 1.3.
class DashedSlot extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double height;

  const DashedSlot({
    super.key,
    required this.label,
    this.icon = Icons.add_rounded,
    this.onTap,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 10.0;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: const _DashedBorderPainter(
              radius: radius,
              color: Star.overlay,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: Star.mut),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11.5,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Star.mut,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double radius;
  final Color color;

  const _DashedBorderPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0;
    const gap = 4.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.radius != radius || old.color != color;
}

class TutorialStepItem {
  final String title;
  final String category;
  final String description;
  final String tip;
  final IconData icon;
  final Color accentColor;
  final String? featureTag;

  const TutorialStepItem({
    required this.title,
    required this.category,
    required this.description,
    required this.tip,
    required this.icon,
    this.accentColor = Star.star,
    this.featureTag,
  });
}

void showInteractiveSpotlightTutorial(
  BuildContext context, {
  required String tutorialTitle,
  required List<TutorialStepItem> steps,
  VoidCallback? onComplete,
}) {
  iosTapBuzz();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'InteractiveTutorial',
    barrierColor: Colors.black.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) => _InteractiveSpotlightDialog(
      tutorialTitle: tutorialTitle,
      steps: steps,
      onComplete: onComplete,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class TutorialPillButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final Color color;

  const TutorialPillButton({
    super.key,
    required this.onTap,
    this.label = 'Tutorial',
    this.color = Star.star,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          iosTapBuzz();
          onTap();
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_rounded, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveSpotlightDialog extends StatefulWidget {
  final String tutorialTitle;
  final List<TutorialStepItem> steps;
  final VoidCallback? onComplete;

  const _InteractiveSpotlightDialog({
    required this.tutorialTitle,
    required this.steps,
    this.onComplete,
  });

  @override
  State<_InteractiveSpotlightDialog> createState() =>
      _InteractiveSpotlightDialogState();
}

class _InteractiveSpotlightDialogState
    extends State<_InteractiveSpotlightDialog>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _arrowCtrl;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _arrowCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    iosTapBuzz();
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      triumphBuzz();
      Navigator.of(context, rootNavigator: true).pop();
      widget.onComplete?.call();
    }
  }

  void _prevStep() {
    iosTapBuzz();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    final step = widget.steps[_currentStep];
    final progress = (_currentStep + 1) / widget.steps.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Konten Tengah dan Bawah
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                children: [
                  // Header Atas: Badge Judul & Tombol Tutup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: step.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: step.accentColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: step.accentColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.tutorialTitle.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: step.accentColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Star.mut,
                          size: 22,
                        ),
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // SPOTLIGHT PULSING FRAME DENGAN ANIMATED POINTER ARROW
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulseCtrl, _arrowCtrl]),
                    builder: (context, _) {
                      final pulseVal = _pulseCtrl.value;
                      final arrowVal = _arrowCtrl.value;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouncing Pointer Arrow
                          Transform.translate(
                            offset: Offset(0, arrowVal * 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: step.accentColor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: step.accentColor.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'PERHATIKAN BAGIAN INI',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Star.onAccent,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  color: step.accentColor,
                                  size: 34,
                                  shadows: [
                                    Shadow(
                                      color: step.accentColor.withValues(
                                        alpha: 0.8,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Glowing Spotlight Showcase Container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Star.sunken,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: step.accentColor.withValues(
                                  alpha: 0.6 + (0.4 * pulseVal),
                                ),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: step.accentColor.withValues(
                                    alpha: 0.25 + (0.35 * pulseVal),
                                  ),
                                  blurRadius: 20 + (10 * pulseVal),
                                  spreadRadius: 2 + (2 * pulseVal),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: step.accentColor.withValues(
                                      alpha: 0.18,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: step.accentColor.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    step.icon,
                                    color: step.accentColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (step.featureTag != null)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: step.accentColor.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            step.featureTag!,
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: step.accentColor,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        step.title,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Star.ink,
                                        ),
                                      ),
                                      Text(
                                        step.category,
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Star.mut,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // GUIDANCE CARD DENGAN PENJELASAN LENGKAP & STEP CONTROLLER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Star.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Star.overlay),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress Bar & Step Counter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Langkah ${_currentStep + 1} dari ${widget.steps.length}',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: step.accentColor,
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}% Selesai',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Star.mut,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: Star.overlay,
                            valueColor: AlwaysStoppedAnimation(
                              step.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title & Detail Description
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Star.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.description,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            color: Star.ink,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tips praktis: catatan pinggir, bukan kotak berikon.
                        MarginNote(step.tip, label: 'Tips praktis'),
                        const SizedBox(height: 16),

                        // Action Buttons: Lewati, Sebelumnya, Lanjut
                        Row(
                          children: [
                            if (_currentStep > 0)
                              OutlinedButton(
                                onPressed: _prevStep,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Star.ink,
                                  side: const BorderSide(color: Star.overlay),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Kembali',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop(),
                                child: const Text(
                                  'Lewati',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    color: Star.mut,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: step.accentColor,
                                foregroundColor: Star.onAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentStep == widget.steps.length - 1
                                        ? 'Paham & Selesai!'
                                        : 'Lanjut',
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _currentStep == widget.steps.length - 1
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget teks deskripsi tugas/jadwal dengan batas 2 baris awal dan
/// opsi toggle "Selengkapnya" / "Sembunyikan" jika melebihi 2 baris,
/// menjaga tata letak kartu tetap rapi dan tidak meluap (overflow).
class ExpandableNoteText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final Color? readMoreColor;

  const ExpandableNoteText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 2,
    this.readMoreColor,
  });

  @override
  State<ExpandableNoteText> createState() => _ExpandableNoteTextState();
}

class _ExpandableNoteTextState extends State<ExpandableNoteText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : double.infinity;
        final span = TextSpan(text: trimmed, style: widget.style);
        final tp = TextPainter(
          text: span,
          textDirection: Directionality.of(context),
          maxLines: widget.maxLines,
        )..layout(maxWidth: maxWidth);

        final exceeds = tp.didExceedMaxLines;
        final actionColor = widget.readMoreColor ?? Star.star;

        if (!exceeds) {
          return Text(
            trimmed,
            maxLines: widget.maxLines,
            style: widget.style,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trimmed,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: widget.style,
            ),
            const SizedBox(height: 2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                iosTapBuzz();
                setState(() => _expanded = !_expanded);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Sembunyikan' : 'Selengkapnya',
                      style: widget.style.copyWith(
                        fontFamily: 'Manrope',
                        fontSize: (widget.style.fontSize ?? 11) * 0.95,
                        fontWeight: FontWeight.w700,
                        color: actionColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: actionColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

