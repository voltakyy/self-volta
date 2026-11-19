// ============================================================================
// JADWAL HARIAN — tampilan baca untuk tugas yang dibuat di To-Do.
//
// Fokus halaman ini adalah keterbacaan: satu hari, urut jam, garis waktu yang
// jelas, penanda "sekarang", dan kartu tugas yang bisa langsung dicentang.
// Tugas tanpa jam dipisah agar tidak mengacaukan timeline. Tugas selesai
// dilipat di bawah supaya jadwal yang belum dikerjakan tetap menonjol.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'todo_page.dart';

class JadwalPage extends StatefulWidget {
  final ValueChanged<String> onNavigate;

  const JadwalPage({super.key, required this.onNavigate});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  String _day = todoTodayKey();
  bool _showDone = false;
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Penanda "sekarang" dan label "lewat" ikut bergerak tanpa perlu
    // meninggalkan halaman.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  DateTime get _selectedDate => DateTime.tryParse(_day) ?? DateTime.now();

  bool get _isToday => _day == todoTodayKey();

  void _goToday() {
    iosTapBuzz();
    setState(() => _day = todoTodayKey());
  }

  void _shiftWeek(int weeks) {
    iosTapBuzz();
    final d = _selectedDate.add(Duration(days: 7 * weeks));
    setState(() => _day = dKey(d));
  }

  Future<void> _pickDate() async {
    iosTapBuzz();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: Star.star),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _day = dKey(picked));
  }

  Future<void> _openEditor({SvTask? existing}) =>
      showTodoEditor(context, existing: existing, dateKey: _day);

  void _toast(String copy) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(copy),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Star.star,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _toggle(SvTask t) {
    iosTapBuzz();
    final wasDone = t.done;
    AppState.I.toggleTodo(t.id);
    if (!wasDone) {
      triumphBuzz();
      final bonus = t.xp > 0 ? ' (+${t.xp} XP)' : '';
      _toast('Tuntas "${t.title}"$bonus');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final st = AppState.I;
        final all = st.todos.where((t) => st.dateOf(t) == _day).toList();
        final open = all.where((t) => !t.done).toList()..sort(_cmpTask);
        final done = all.where((t) => t.done).toList()..sort(_cmpTask);
        final timed = open.where((t) => t.timeMin >= 0).toList();
        final untimed = open.where((t) => t.timeMin < 0).toList();
        final nowMin = _now.hour * 60 + _now.minute;
        final total = all.length;

        return Stack(
          children: [
            ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 118),
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _WeekStrip(
                  day: _day,
                  today: todoTodayKey(),
                  tasksForDay: (k) => st.todos.where((t) => st.dateOf(t) == k),
                  onPick: (k) {
                    iosTapBuzz();
                    setState(() => _day = k);
                  },
                  onPrev: () => _shiftWeek(-1),
                  onNext: () => _shiftWeek(1),
                ),
                const SizedBox(height: 16),
                if (total > 0)
                  _Summary(open: open.length, done: done.length, total: total),
                if (total == 0) ...[
                  const SizedBox(height: 8),
                  _EmptyState(onCreate: () => _openEditor()),
                ] else ...[
                  const SizedBox(height: 18),
                  _SectionHead(
                    title: 'Jadwal hari ini',
                    trailing: '${open.length} tersisa',
                  ),
                  const SizedBox(height: 10),
                  if (timed.isEmpty && untimed.isNotEmpty)
                    _UntimedHint(onAllDone: open.isEmpty)
                  else if (timed.isNotEmpty)
                    _Timeline(
                      tasks: timed,
                      today: _isToday,
                      nowMin: nowMin,
                      onToggle: _toggle,
                      onOpen: (t) => _openEditor(existing: t),
                    ),
                  if (timed.isNotEmpty && open.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Semua tugas berjam sudah selesai.',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11.5,
                          color: Star.mut,
                        ),
                      ),
                    ),
                  if (untimed.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _SectionHead(
                      title: 'Tanpa jam',
                      trailing: '${untimed.length}',
                    ),
                    const SizedBox(height: 8),
                    for (final t in untimed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TaskCard(
                          task: t,
                          overdue: false,
                          onToggle: () => _toggle(t),
                          onOpen: () => _openEditor(existing: t),
                        ),
                      ),
                  ],
                  if (done.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DoneToggle(
                      count: done.length,
                      open: _showDone,
                      onTap: () {
                        iosTapBuzz();
                        setState(() => _showDone = !_showDone);
                      },
                    ),
                    if (_showDone)
                      for (final t in done)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _TaskCard(
                            task: t,
                            overdue: false,
                            onToggle: () => _toggle(t),
                            onOpen: () => _openEditor(existing: t),
                          ),
                        ),
                  ],
                ],
              ],
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Tooltip(
                message: 'Tambah tugas',
                child: InkWell(
                  key: const Key('jadwal-add'),
                  onTap: () {
                    iosTapBuzz();
                    _openEditor();
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Star.star,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Star.star.withValues(alpha: .28),
                          blurRadius: 20,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 28,
                      color: Star.onAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final d = _selectedDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'JADWAL HARIAN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Star.mut,
                ),
              ),
            ),
            IconButton(
              key: const Key('jadwal-calendar'),
              onPressed: _pickDate,
              tooltip: 'Pilih tanggal',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: Star.star,
              ),
            ),
          ],
        ),
        Text(
          '${kTodoHari[d.weekday]} · ${d.day} ${kTodoBulan[d.month]} ${d.year}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Star.ink,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                _isToday
                    ? 'Rencana hari ini, urut jam.'
                    : 'Jadwal tersimpan untuk hari ini.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11.5,
                  color: Star.mut,
                ),
              ),
            ),
            if (!_isToday) ...[
              const SizedBox(width: 8),
              InkWell(
                key: const Key('jadwal-today'),
                onTap: _goToday,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Star.star.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'Hari ini',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static int _cmpTask(SvTask a, SvTask b) {
    if (a.timeMin < 0 && b.timeMin >= 0) return 1;
    if (b.timeMin < 0 && a.timeMin >= 0) return -1;
    final t = a.timeMin.compareTo(b.timeMin);
    if (t != 0) return t;
    final p = b.pri.compareTo(a.pri);
    if (p != 0) return p;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}

// ---------------------------------------------------------------------------
// Strip tanggal (satu minggu, Senin–Minggu)
// ---------------------------------------------------------------------------

class _WeekStrip extends StatelessWidget {
  final String day;
  final String today;
  final Iterable<SvTask> Function(String) tasksForDay;
  final ValueChanged<String> onPick;
  final VoidCallback onPrev, onNext;

  const _WeekStrip({
    required this.day,
    required this.today,
    required this.tasksForDay,
    required this.onPick,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final selected = DateTime.tryParse(day) ?? DateTime.now();
    final monday = DateTime(
      selected.year,
      selected.month,
      selected.day,
    ).subtract(Duration(days: selected.weekday - 1));

    return Row(
      children: [
        _Arrow(
          icon: Icons.chevron_left_rounded,
          onTap: onPrev,
          tooltip: 'Minggu sebelumnya',
        ),
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _DayCell(
              date: monday.add(Duration(days: i)),
              selected: dKey(monday.add(Duration(days: i))) == day,
              today: dKey(monday.add(Duration(days: i))) == today,
              hasTasks: tasksForDay(dKey(monday.add(Duration(days: i))))
                  .isNotEmpty,
              onTap: () => onPick(dKey(monday.add(Duration(days: i)))),
            ),
          ),
        _Arrow(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
          tooltip: 'Minggu berikutnya',
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _Arrow({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: SizedBox(
          width: 24,
          height: 52,
          child: Icon(icon, size: 19, color: Star.faint),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool selected, today, hasTasks;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.selected,
    required this.today,
    required this.hasTasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Star.onAccent : Star.ink;
    final sub = selected
        ? Star.onAccent70
        : today
        ? Star.star
        : Star.mut;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? Star.star : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Star.star
                  : today
                  ? Star.star.withValues(alpha: .45)
                  : Star.lineSoft,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  kTodoHariPendek[date.weekday],
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: sub,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${date.day}',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasTasks
                      ? (selected ? Star.onAccent : Star.star)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ringkasan + bagian
// ---------------------------------------------------------------------------

class _Summary extends StatelessWidget {
  final int open, done, total;

  const _Summary({required this.open, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: Star.fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Star.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  open == 0
                      ? 'Semua beres untuk hari ini'
                      : '$open tugas menunggu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Star.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$done/$total selesai',
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Star.mut,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Star.sunken,
              valueColor: const AlwaysStoppedAnimation<Color>(Star.star),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionHead({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: Star.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          trailing,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Star.faint,
          ),
        ),
      ],
    );
  }
}

class _UntimedHint extends StatelessWidget {
  final bool onAllDone;

  const _UntimedHint({required this.onAllDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        onAllDone
            ? 'Belum ada tugas berjam. Semua tugas hari ini ada di bawah.'
            : 'Belum ada tugas berjam. Tambahkan jam agar muncul di timeline.',
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11.5,
          height: 1.45,
          color: Star.mut,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

class _Timeline extends StatelessWidget {
  final List<SvTask> tasks;
  final bool today;
  final int nowMin;
  final ValueChanged<SvTask> onToggle;
  final ValueChanged<SvTask> onOpen;

  const _Timeline({
    required this.tasks,
    required this.today,
    required this.nowMin,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var nowPlaced = false;
    for (final t in tasks) {
      if (today && !nowPlaced && t.timeMin >= nowMin) {
        rows.add(_NowRow(nowMin: nowMin));
        nowPlaced = true;
      }
      rows.add(
        _TimelineRow(
          task: t,
          overdue: today && t.timeMin < nowMin,
          onToggle: () => onToggle(t),
          onOpen: () => onOpen(t),
        ),
      );
    }
    if (today && !nowPlaced) rows.add(_NowRow(nowMin: nowMin, last: true));

    return Stack(
      children: [
        Positioned(
          left: 54,
          top: 18,
          bottom: 18,
          child: Container(width: 1, color: Star.line),
        ),
        Column(children: rows),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final SvTask task;
  final bool overdue;
  final VoidCallback onToggle, onOpen;

  const _TimelineRow({
    required this.task,
    required this.overdue,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final dot = task.done
        ? Star.success
        : overdue
        ? Star.warning
        : Star.star;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 13, right: 4),
              child: Text(
                timeLabel(task.timeMin),
                maxLines: 1,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: overdue ? Star.warning : Star.mut,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              border: Border.all(color: Star.bg, width: 2.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TaskCard(
              task: task,
              overdue: overdue,
              onToggle: onToggle,
              onOpen: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

class _NowRow extends StatelessWidget {
  final int nowMin;
  final bool last;

  const _NowRow({required this.nowMin, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 12 : 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              timeLabel(nowMin),
              maxLines: 1,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Star.warning,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: Star.warning,
              shape: BoxShape.circle,
              border: Border.all(color: Star.bg, width: 2.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 1,
                    child: ColoredBox(color: Star.star.withValues(alpha: .4)),
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'SEKARANG',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Star.warning,
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

// ---------------------------------------------------------------------------
// Kartu tugas
// ---------------------------------------------------------------------------

class _TaskCard extends StatelessWidget {
  final SvTask task;
  final bool overdue;
  final VoidCallback onToggle, onOpen;

  const _TaskCard({
    required this.task,
    required this.overdue,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    return Material(
      key: Key('jadwal-task-${task.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
          decoration: BoxDecoration(
            color: done ? Star.fill : Star.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: overdue && !done
                  ? Star.warning.withValues(alpha: .35)
                  : Star.lineSoft,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: _CheckDot(
                  key: Key('jadwal-check-${task.id}'),
                  done: done,
                  onTap: onToggle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: done ? Star.faint : Star.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: Star.faint,
                      ),
                    ),
                    if (task.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      ExpandableNoteText(
                        text: task.note.trim(),
                        maxLines: 2,
                        readMoreColor: Star.star,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          height: 1.35,
                          color: Star.mut,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        _Chip(icon: todoCatIcon(task.cat), label: task.cat),
                        if (overdue && !done)
                          const _Chip(
                            icon: Icons.schedule_rounded,
                            label: 'Lewat',
                            color: Star.warning,
                          ),
                        if (task.alarm)
                          const _Chip(
                            icon: Icons.alarm_rounded,
                            label: 'Alarm',
                            color: Star.star,
                          ),
                        if (task.repeat.isNotEmpty)
                          _Chip(
                            icon: Icons.repeat_rounded,
                            label: _repeatLabel(task.repeat),
                          ),
                        if (task.pri == 2)
                          const _Chip(
                            icon: Icons.flag_rounded,
                            label: 'Penting',
                            color: Star.star,
                          ),
                      ],
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

  static String _repeatLabel(String r) => switch (r) {
    'harian' => 'Harian',
    'mingguan' => 'Mingguan',
    'bulanan' => 'Bulanan',
    _ => r,
  };
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, this.color = Star.mut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Star.sunken,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;

  const _CheckDot({super.key, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      customBorder: const CircleBorder(),
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? Star.success : Colors.transparent,
          border: Border.all(
            color: done ? Star.success : Star.faint,
            width: 1.5,
          ),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 16, color: Star.onAccent)
            : null,
      ),
    );
  }
}

class _DoneToggle extends StatelessWidget {
  final int count;
  final bool open;
  final VoidCallback onTap;

  const _DoneToggle({
    required this.count,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Icon(
              open
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              size: 18,
              color: Star.faint,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Selesai · $count',
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Star.mut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Star.fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Star.lineSoft),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Star.star.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              size: 26,
              color: Star.star,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada jadwal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Star.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tugas yang kamu buat di To-Do akan muncul di sini, urut jam.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11.5,
              height: 1.45,
              color: Star.mut,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('jadwal-empty-add'),
            onPressed: onCreate,
            style: OutlinedButton.styleFrom(
              foregroundColor: Star.star,
              side: const BorderSide(color: Star.line),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Tambah tugas'),
          ),
        ],
      ),
    );
  }
}
