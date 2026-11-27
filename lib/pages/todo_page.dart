// ============================================================================
// TO-DO HARIAN — halaman tugas bergaya planner (referensi: header berwarna,
// strip tanggal, daftar tugas berjam, alur "pilih aktivitas").
//
// Palet tetap palet app (krem + mint + teal tua), bukan gradien ungu.
// Fitur yang dipertahankan: pengelompokan waktu, tab Hari ini/Terjadwal/
// Selesai, swipe-to-delete + Urungkan, bonus XP, pengingat notifikasi sistem
// (otomatis aktif saat jam dipilih), validasi XP (clamp) & tanggal lampau.
// ============================================================================

import 'package:flutter/material.dart';

import '../services/todo_notifications.dart';
import '../store.dart';
import '../widgets.dart';
import '../widgets/custom_alarm_card.dart';
import 'notif_settings_sheet.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Token palet "Hari" (krem + mint, independen dari Star/*Themes).
// ---------------------------------------------------------------------------
class TodoPal {
  static const canvas = Paper.canvas;
  static const card = Paper.card;
  static const mint = Paper.mint;
  static const mintDeep = Paper.mintDeep;
  static const header = Paper.header;
  static const mintSoft = Paper.mintSoft;
  static const mintBorder = Color(0xff4A6B5A);
  static const ink = Paper.ink;
  static const sec = Paper.sec;
  static const ter = Paper.ter;
  static const coral = Paper.coral;
  static const coralSoft = Paper.coralSoft;
  static const amber = Paper.amber;
  static const amberSoft = Paper.amberSoft;
  static const overlay = Color(0xff454B54);
  static const hair = Paper.hair;
  static const field = Paper.field;
}

// ---------------------------------------------------------------------------
// Util tanggal & jam (top-level: dipakai halaman, editor, dan halaman Study).
// ---------------------------------------------------------------------------
String dKey(DateTime n) =>
    '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';

String todoTodayKey() => dKey(DateTime.now());

const kTodoBulan = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
const kTodoHari = [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const kTodoHariPendek = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// "Hari ini", "Besok", "Kamis, 24 Okt".
String dateLabel(String key) {
  final t = todoTodayKey();
  final tomorrow = dKey(DateTime.now().add(const Duration(days: 1)));
  if (key.isEmpty || key == t) return 'Hari ini';
  if (key == tomorrow) return 'Besok';
  try {
    final n = DateTime(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(5, 7)),
      int.parse(key.substring(8, 10)),
    );
    return '${kTodoHari[n.weekday]}, ${n.day} ${kTodoBulan[n.month]}';
  } catch (_) {
    return key;
  }
}

/// "Hari ini", "Kemarin", atau "22 Okt".
String dateLabelShort(String key) {
  final t = todoTodayKey();
  final yest = dKey(DateTime.now().subtract(const Duration(days: 1)));
  if (key == t) return 'Hari ini';
  if (key == yest) return 'Kemarin';
  try {
    final n = DateTime(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(5, 7)),
      int.parse(key.substring(8, 10)),
    );
    return '${n.day} ${kTodoBulan[n.month]}';
  } catch (_) {
    return key;
  }
}

String timeLabel(int t) {
  if (t < 0) return '';
  return '${(t ~/ 60).toString().padLeft(2, '0')}.${(t % 60).toString().padLeft(2, '0')}';
}

String zoneOf(int t) {
  if (t < 0) return 'Tanpa jam';
  if (t < 12 * 60) return 'Pagi';
  if (t < 15 * 60) return 'Siang';
  if (t < 18 * 60) return 'Sore';
  return 'Malam';
}

// ---------------------------------------------------------------------------
// Aktivitas (kategori) — dipakai halaman & editor.
// ---------------------------------------------------------------------------
const kTodoCats = ['Pekerjaan', 'Pribadi', 'Belajar', 'Kesehatan'];

IconData todoCatIcon(String cat) => switch (cat) {
  'Pekerjaan' => Icons.work_rounded,
  'Belajar' => Icons.school_rounded,
  'Kesehatan' => Icons.favorite_rounded,
  _ => Icons.person_rounded,
};

class TodoPage extends StatefulWidget {
  final ValueChanged<String> onNavigate;
  const TodoPage({super.key, required this.onNavigate});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

enum _Sort { waktu, prioritas, judul }

class _TodoPageState extends State<TodoPage> {
  int _tab = 0; // 0 Hari Ini | 1 Terjadwal | 2 Selesai
  String _day = todoTodayKey(); // tanggal yang dilihat pada tab Hari ini
  String _cat = 'Semua';
  _Sort _sort = _Sort.waktu;

  static const _tabs = ['Hari ini', 'Terjadwal', 'Selesai'];
  static const _zaman = ['Pagi', 'Siang', 'Sore', 'Malam'];

  // ---- data turunan -------------------------------------------------------
  List<SvTask> _tasksOf(AppState st, String day) =>
      st.todos.where((t) => !t.done && st.dateOf(t) == day).toList();

  void _sortTasks(List<SvTask> l) {
    switch (_sort) {
      case _Sort.prioritas:
        l.sort((a, b) => b.pri.compareTo(a.pri));
      case _Sort.judul:
        l.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case _Sort.waktu:
        l.sort((a, b) {
          if (a.timeMin < 0 && b.timeMin >= 0) return 1;
          if (b.timeMin < 0 && a.timeMin >= 0) return -1;
          return a.timeMin.compareTo(b.timeMin);
        });
    }
  }

  /// (label grup, daftar tugas) untuk tab aktif.
  List<(String, List<SvTask>)> _groups(AppState st) {
    if (_tab == 0) {
      final open = _tasksOf(st, _day);
      if (_cat != 'Semua') open.removeWhere((t) => t.cat != _cat);
      _sortTasks(open);

      final out = <(String, List<SvTask>)>[];
      for (final z in _zaman) {
        final l = open
            .where((t) => t.timeMin >= 0 && zoneOf(t.timeMin) == z)
            .toList();
        if (l.isNotEmpty) out.add((z, l));
      }
      final noTime = open.where((t) => t.timeMin < 0).toList();
      if (noTime.isNotEmpty) out.add(('Tanpa jam', noTime));

      final done =
          st.todos.where((t) => t.done && st.dateOf(t) == _day).toList()
            ..sort((a, b) => b.timeMin.compareTo(a.timeMin));
      if (done.isNotEmpty) out.add(('Selesai', done));

      return out;
    }

    if (_tab == 1) {
      final later = <SvTask, String>{};
      final keys = <String>{};
      for (final t in st.todos.where((t) => !t.done)) {
        if (_cat != 'Semua' && t.cat != _cat) continue;
        final k = st.dateOf(t);
        if (k.compareTo(todoTodayKey()) > 0) {
          later[t] = k;
          keys.add(k);
        }
      }
      final sorted = keys.toList()..sort();
      return [
        for (final k in sorted)
          (
            dateLabel(k),
            (later.entries.where((e) => e.value == k).map((e) => e.key).toList()
              ..sort((a, b) => a.timeMin.compareTo(b.timeMin))),
          ),
      ];
    }

    // Tab Selesai: grup by doneAt, terbaru dulu.
    final map = <String, List<SvTask>>{};
    for (final t in st.todos.where((t) => t.done)) {
      if (_cat != 'Semua' && t.cat != _cat) continue;
      (map[t.doneAt.isEmpty ? todoTodayKey() : t.doneAt] ??= []).add(t);
    }
    final ks = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in ks) (dateLabelShort(k), map[k]!)];
  }

  // ---- aksi ---------------------------------------------------------------
  void _onCheck(SvTask t, bool wasDone, AppState st) {
    iosTapBuzz();
    st.toggleTodo(t.id);
    if (!wasDone) {
      triumphBuzz();
      final bonus = t.xp > 0 ? ' (+${t.xp} XP)' : '';
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Tuntas "${t.title}"$bonus'),
            duration: const Duration(milliseconds: 1400),
            behavior: SnackBarBehavior.floating,
            backgroundColor: TodoPal.header,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }

  void _onDelete(SvTask t, AppState st) {
    final idx = st.todos.indexOf(t);
    st.deleteTodo(t.id);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Tugas "${t.title}" dihapus'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Star.star,
          action: SnackBarAction(
            label: 'Urungkan',
            textColor: Star.success,
            onPressed: () => st.restoreTodo(idx, t),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _openEditor({SvTask? existing, String? date}) =>
      showTodoEditor(context, existing: existing, dateKey: date);

  void _cycleSort() {
    iosTapBuzz();
    setState(() {
      _sort = _Sort.values[(_sort.index + 1) % _Sort.values.length];
    });
  }

  // ---- build --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final st = AppState.I;
        final now = DateTime.now();
        final shown = DateTime.tryParse(_day) ?? now;
        final nowMin = now.hour * 60 + now.minute;
        final isToday = _day == todoTodayKey();
        final tasks = _tasksOf(st, _day);
        final doneHere = st.todos
            .where((t) => t.done && st.dateOf(t) == _day)
            .toList();
        final total = tasks.length + doneHere.length;
        final p = total == 0 ? 0.0 : doneHere.length / total;
        final groups = _groups(st);
        final doneCount = st.todosDoneToday.length;

        return Container(
          color: TodoPal.canvas,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  title: isToday ? 'Hari ini' : dateLabel(_day),
                  dateStr:
                      '${kTodoHari[shown.weekday]}, ${shown.day} ${kTodoBulan[shown.month]} ${shown.year}',
                  count: tasks.length,
                  done: doneHere.length,
                  onAdd: () => _openEditor(date: _day),
                  onNotif: () => showNotifSettingsSheet(context),
                  onSchedule: () => widget.onNavigate('jadwal'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _WeekStrip(
                    day: _day,
                    tasksForDay: (k) =>
                        st.todos.where((t) => st.dateOf(t) == k),
                    onPick: (k) {
                      iosTapBuzz();
                      setState(() => _day = k);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _GoalCard(
                    done: doneHere.length,
                    total: total,
                    progress: p,
                    quote: _quote(doneHere.length, total),
                  ),
                ),
              ),
              if (_tab == 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
                    child: _CatStrip(
                      selected: _cat,
                      countOf: (c) => st.todos
                          .where(
                            (t) =>
                                !t.done &&
                                st.dateOf(t) == _day &&
                                (c == 'Semua' || t.cat == c),
                          )
                          .length,
                      onPick: (c) {
                        iosTapBuzz();
                        setState(() => _cat = c);
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tugas saya',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: TodoPal.ink,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _cycleSort,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.swap_vert_rounded,
                                size: 15,
                                color: TodoPal.ter,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                switch (_sort) {
                                  _Sort.waktu => 'Jam',
                                  _Sort.prioritas => 'Prioritas',
                                  _Sort.judul => 'Judul',
                                },
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: TodoPal.ter,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_tab == 0 && doneCount >= 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${groups.fold<int>(0, (s, g) => s + g.$2.length)}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: TodoPal.ter,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _Segment(
                    index: _tab,
                    labels: _tabs,
                    onPick: (i) {
                      iosTapBuzz();
                      setState(() => _tab = i);
                    },
                  ),
                ),
              ),
              if (groups.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _Empty(
                      tab: _tab,
                      day: _day,
                      onCreate: () => _openEditor(date: _day),
                    ),
                  ),
                ),
              for (final (label, list) in groups) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: _GroupHead(label: label, count: list.length),
                  ),
                ),
                SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _TaskCard(
                        task: t,
                        overdue:
                            !t.done &&
                            t.timeMin >= 0 &&
                            t.timeMin < nowMin &&
                            st.dateOf(t) == todoTodayKey(),
                        onCheck: (wasDone) => _onCheck(t, wasDone, st),
                        onOpen: () => _openEditor(existing: t),
                        onDelete: () => _onDelete(t, st),
                        onNotif: () => showNotifSettingsSheet(context),
                      ),
                    );
                  },
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _StudyCta(
                    minutes: st.studyMinutesWeek,
                    sessions: st.studySessionsToday,
                    onTap: () => widget.onNavigate('study'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  static String _quote(int done, int total) {
    if (total == 0) return 'Belum ada tugas — mulai dengan satu langkah kecil.';
    if (done == total) {
      return 'Semua tuntas. Istirahat itu bagian dari rencana.';
    }
    if (done == 0) {
      return 'Tugas pertama paling berat. Mulai dari yang terdekat.';
    }
    if (done * 2 >= total) return 'Separuh jalan. Jaga ritme sampai selesai.';
    return 'Sudah mulai — itu yang membedakan rencana dari wacana.';
  }
}

// ============================================================================
// HEADER BERWARNA + STRIP TANGGAL
// ============================================================================

class _Header extends StatelessWidget {
  final String title, dateStr;
  final int count, done;
  final VoidCallback onAdd;
  final VoidCallback onNotif;
  final VoidCallback onSchedule;

  const _Header({
    required this.title,
    required this.dateStr,
    required this.count,
    required this.done,
    required this.onAdd,
    required this.onNotif,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final notifOk = TodoNotif.ready && TodoNotif.granted;
    return Container(
      decoration: BoxDecoration(
        color: Star.bg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: Neu.shadows(d: 6),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 16, color: Star.mut),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Star.mut,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: const Key('todo-schedule-btn'),
                onTap: () {
                  iosTapBuzz();
                  onSchedule();
                },
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.calendar_view_day_rounded,
                    size: 20,
                    color: Star.ink,
                  ),
                ),
              ),
              InkWell(
                key: const Key('todo-notif-btn'),
                onTap: () {
                  iosTapBuzz();
                  onNotif();
                },
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        notifOk
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        size: 20,
                        color: Star.ink,
                      ),
                      Positioned(
                        right: 8,
                        top: 9,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: notifOk ? Star.success : Star.star,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: Star.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 0
                          ? 'Tidak ada tugas tersisa'
                          : '$count tugas · $done selesai',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.5,
                        color: Star.mut,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PopTap(
                key: const Key('todo-add-header'),
                onTap: onAdd,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Star.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: TodoPal.header),
                      SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: TodoPal.header,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final String day;
  final Iterable<SvTask> Function(String key) tasksForDay;
  final ValueChanged<String> onPick;

  const _WeekStrip({
    required this.day,
    required this.tasksForDay,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Senin..Minggu pada minggu yang sedang dilihat.
    final picked = DateTime.tryParse(day) ?? now;
    final monday = picked.subtract(Duration(days: picked.weekday - 1));
    final todayKey = todoTodayKey();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: Neu.raised(r: 18, d: 5),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _DayCell(
                date: monday.add(Duration(days: i)),
                selected: dKey(monday.add(Duration(days: i))) == day,
                isToday: dKey(monday.add(Duration(days: i))) == todayKey,
                hasTasks: tasksForDay(dKey(monday.add(Duration(days: i))))
                    .isNotEmpty,
                onTap: () => onPick(dKey(monday.add(Duration(days: i)))),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool selected, isToday, hasTasks;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.hasTasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Star.onAccent : TodoPal.sec;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? TodoPal.header : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isToday && !selected
                ? Border.all(color: TodoPal.mintBorder)
                : null,
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${date.day}',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: selected ? Star.onAccent : TodoPal.ink,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasTasks
                      ? (selected ? Star.surface : TodoPal.mint)
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

class _GoalCard extends StatelessWidget {
  final int done, total;
  final double progress;
  final String quote;

  const _GoalCard({
    required this.done,
    required this.total,
    required this.progress,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: Neu.raised(r: 16, d: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: TodoPal.mintSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  size: 16,
                  color: TodoPal.mintDeep,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Target hari ini',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TodoPal.ink,
                  ),
                ),
              ),
              Text(
                '$done / $total',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TodoPal.mintDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Paper.hair,
              valueColor: const AlwaysStoppedAnimation(TodoPal.mint),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            quote,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11.5,
              height: 1.35,
              color: TodoPal.sec,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatStrip extends StatelessWidget {
  final String selected;
  final int Function(String cat) countOf;
  final ValueChanged<String> onPick;

  const _CatStrip({
    required this.selected,
    required this.countOf,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final items = ['Semua', ...kTodoCats];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = items[i];
          final on = selected == c;
          return InkWell(
            onTap: () => onPick(c),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: on ? TodoPal.header : TodoPal.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? TodoPal.header : TodoPal.hair),
              ),
              child: Row(
                children: [
                  if (c != 'Semua') ...[
                    Icon(
                      todoCatIcon(c),
                      size: 14,
                      color: on ? Star.onAccent : TodoPal.sec,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    c,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: on ? Star.onAccent : TodoPal.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${countOf(c)}',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: on ? Star.onAccent70 : TodoPal.ter,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onPick;

  const _Segment({
    required this.index,
    required this.labels,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: Neu.raised(r: 14, d: 4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == i ? TodoPal.mintSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: index == i
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: index == i ? TodoPal.mintDeep : TodoPal.ter,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHead extends StatelessWidget {
  final String label;
  final int count;
  const _GroupHead({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: TodoPal.ter,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: TodoPal.ter,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final int tab;
  final String day;
  final VoidCallback onCreate;
  const _Empty({required this.tab, required this.day, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final copy = switch (tab) {
      0 =>
        day == todoTodayKey()
            ? 'Belum ada tugas untuk hari ini.'
            : 'Tidak ada tugas pada ${dateLabel(day).toLowerCase()}.',
      1 => 'Belum ada tugas menjelang di masa depan.',
      _ => 'Belum ada tugas yang selesai.',
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: Neu.raised(r: 16, d: 5),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: TodoPal.mintSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: TodoPal.mint,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: TodoPal.sec,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: TodoPal.header,
                foregroundColor: Star.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Tugas baru'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// KARTU TUGAS
// ============================================================================

class _TaskCard extends StatelessWidget {
  final SvTask task;
  final bool overdue;
  final ValueChanged<bool> onCheck; // arg = status SEBELUM centang
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onNotif;

  const _TaskCard({
    required this.task,
    required this.overdue,
    required this.onCheck,
    required this.onOpen,
    required this.onDelete,
    required this.onNotif,
  });

  @override
  Widget build(BuildContext context) {
    final t = task;
    final done = t.done;
    final titleStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 13.5,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: done ? Star.mut : TodoPal.ink,
      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: Star.mut,
    );

    // Warna garis aksen kiri berdasarkan kategori/status
    final accentColor = done
        ? TodoPal.hair
        : (overdue
              ? TodoPal.coral
              : switch (t.cat) {
                  'Pekerjaan' => Star.star,
                  'Belajar' => Star.star,
                  'Kesehatan' => TodoPal.coral,
                  _ => TodoPal.mint,
                });

    return Dismissible(
      key: ValueKey('task_${t.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        decoration: BoxDecoration(
          color: TodoPal.coral,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Star.onAccent, size: 22),
      ),
      child: DecoratedBox(
        decoration: Neu.raised(r: 18, d: 4),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Garis aksen kiri – rounded sesuai card corner kiri
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),
                  // Kolom jam.
                  SizedBox(
                    width: 64,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 4, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              t.timeMin < 0 ? '—' : timeLabel(t.timeMin),
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: done
                                    ? Star.mut
                                    : (overdue ? TodoPal.coral : TodoPal.ink),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.timeMin < 0 ? 'tanpa jam' : zoneOf(t.timeMin),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 9.5,
                              color: TodoPal.ter,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Isi.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 11, 4, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: titleStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (t.note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            ExpandableNoteText(
                              text: t.note,
                              maxLines: 2,
                              readMoreColor: TodoPal.mintDeep,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11.5,
                                height: 1.35,
                                color: TodoPal.sec,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _miniChip(
                                t.cat,
                                todoCatIcon(t.cat),
                                TodoPal.mintDeep,
                                TodoPal.mintSoft,
                              ),
                              if (t.pri > 0)
                                _miniChip(
                                  t.pri == 2 ? 'Penting' : 'Sedang',
                                  t.pri == 2
                                      ? Icons.flag_rounded
                                      : Icons.flag_outlined,
                                  t.pri == 2 ? TodoPal.coral : TodoPal.amber,
                                  t.pri == 2
                                      ? TodoPal.coralSoft
                                      : TodoPal.amberSoft,
                                ),
                              if (t.xp > 0)
                                _miniChip(
                                  '+${t.xp} XP',
                                  Icons.bolt_rounded,
                                  TodoPal.mintDeep,
                                  TodoPal.mintSoft,
                                ),
                              if (t.reminder && t.timeMin >= 0 && !t.done)
                                InkWell(
                                  onTap: onNotif,
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.notifications_active_rounded,
                                      size: 13,
                                      color: TodoPal.mintDeep,
                                    ),
                                  ),
                                ),
                              if (overdue && !t.done)
                                _miniChip(
                                  'Telat',
                                  Icons.schedule_rounded,
                                  TodoPal.coral,
                                  TodoPal.coralSoft,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Check target 44dp.
                  InkWell(
                    onTap: () => onCheck(done),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: done ? TodoPal.mint : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: done ? TodoPal.mint : TodoPal.overlay,
                              width: 2,
                            ),
                          ),
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Star.onAccent,
                                  size: 15,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _miniChip(String label, IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: .25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyCta extends StatelessWidget {
  final int minutes, sessions;
  final VoidCallback onTap;
  const _StudyCta({
    required this.minutes,
    required this.sessions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        iosTapBuzz();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: Neu.raised(r: 22, d: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Star.ink.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.timer_rounded, size: 18, color: Star.ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sesi fokus',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Star.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$minutes menit minggu ini · $sessions sesi hari ini',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      color: Star.mut,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Star.mut),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM SHEET EDITOR (buat/ubah tugas)
// ============================================================================

Future<void> showTodoEditor(
  BuildContext context, {
  SvTask? existing,
  String? dateKey,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TodoEditor(existing: existing, dateKey: dateKey),
  );
}

class _TodoEditor extends StatefulWidget {
  final SvTask? existing;
  final String? dateKey;
  const _TodoEditor({this.existing, this.dateKey});

  @override
  State<_TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends State<_TodoEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late final TextEditingController _xp = TextEditingController(
    text: '${widget.existing?.xp ?? 10}',
  );

  late String _cat = widget.existing?.cat ?? 'Pribadi';
  late int _pri = widget.existing?.pri ?? 0;
  late bool _reminder = widget.existing?.reminder ?? true;
  late String _sound = widget.existing?.sound ?? '';
  late String _repeat = widget.existing?.repeat ?? '';
  late bool _alarm = widget.existing?.alarm ?? false;
  late bool _routine = widget.existing?.routine ?? false;
  DateTime? _date;
  int? _timeMin;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _xp.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null && t.timeMin >= 0) _timeMin = t.timeMin;
    final rawDate = t?.date ?? widget.dateKey;
    if (rawDate != null && rawDate.length >= 10) {
      try {
        final d = DateTime(
          int.parse(rawDate.substring(0, 4)),
          int.parse(rawDate.substring(5, 7)),
          int.parse(rawDate.substring(8, 10)),
        );
        if (dKey(d) != todoTodayKey()) _date = d;
      } catch (_) {}
    }
  }

  static const _pris = ['Santai', 'Sedang', 'Penting'];

  InputDecoration _field(String hint, {bool isMultiLine = false}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Star.mut),
    filled: true,
    fillColor: TodoPal.field,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 14,
      vertical: isMultiLine ? 14 : 12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: TodoPal.hair, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: TodoPal.hair, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: TodoPal.header, width: 1.5),
    ),
  );

  void _toast(String copy, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(copy),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Star.error : Star.star,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  static int _dateCmp(DateTime a, DateTime b) => DateTime(
    a.year,
    a.month,
    a.day,
  ).compareTo(DateTime(b.year, b.month, b.day));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme
              .copyWith(primary: TodoPal.header),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _date = dKey(picked) == todoTodayKey() ? null : picked;
        if (_dateCmp(picked, DateTime.now()) < 0) _reminder = false;
      });
    }
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final base = _timeMin ?? -1;
    final picked = await showTimePicker(
      context: context,
      initialTime: base >= 0
          ? TimeOfDay(hour: base ~/ 60, minute: base % 60)
          : TimeOfDay.fromDateTime(now),
    );
    if (picked != null) {
      setState(() {
        _timeMin = picked.hour * 60 + picked.minute;
        // Pengingat otomatis aktif bila jam diisi di hari ini/mendatang.
        if (_date == null || _dateCmp(_date!, DateTime.now()) >= 0) {
          _reminder = true;
        }
      });
    }
  }

  Future<void> _askPermission() async {
    final ok = await TodoNotif.requestPermission();
    setState(() {});
    _toast(
      ok
          ? 'Izin notifikasi diberikan.'
          : 'Izin belum diberikan — pengingat muncul via banner dalam app.',
      error: !ok,
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _toast('Judul tugas wajib diisi.', error: true);
      return;
    }
    final xpVal = int.tryParse(_xp.text.trim()) ?? 0;
    final st = AppState.I;
    final old = widget.existing;
    final task = SvTask(
      id: old?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      note: _note.text.trim(),
      cat: _cat,
      pri: _pri,
      date: _date == null ? '' : dKey(_date!),
      timeMin: _timeMin ?? -1,
      reminder: _reminder && _timeMin != null,
      done: old?.done ?? false,
      sound: _sound,
      repeat: _repeat,
      alarm: _alarm && _timeMin != null,
      routine: _routine,
      seriesId: old?.seriesId ?? 0,
      doneAt: old?.doneAt ?? '',
      xp: xpVal.clamp(0, 10000),
    );
    if (old == null) {
      await st.addTodo(task);
      if (!mounted) return;
      _toast('Tugas ditambahkan.');
    } else {
      await st.updateTodo(task);
      if (!mounted) return;
      _toast('Tugas diperbarui.');
    }
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _delete() async {
    final old = widget.existing;
    if (old == null) return;
    await AppState.I.deleteTodo(old.id);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final counts = <String, int>{
      for (final c in kTodoCats)
        c: AppState.I.todos.where((t) => t.cat == c && !t.done).length,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Star.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Paper.hair,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editing ? 'Ubah tugas' : 'Tugas baru',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: -0.3,
                              color: TodoPal.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            editing
                                ? 'Perubahan langsung tersimpan ke perangkat.'
                                : 'Isi satu langkah kecil yang bisa kamu selesaikan.',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11.5,
                              color: TodoPal.sec,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: TodoPal.sec),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ---- tanggal cepat ----
                _EditorDateStrip(
                  selected: _date,
                  onPick: (d) => setState(() {
                    _date = d == null || dKey(d) == todoTodayKey() ? null : d;
                  }),
                  onCalendar: _pickDate,
                ),
                const SizedBox(height: 16),

                // ---- pilih aktivitas ----
                const Text(
                  'Pilih aktivitas',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: TodoPal.ink,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.7,
                  children: [
                    for (final c in kTodoCats)
                      _ActivityTile(
                        cat: c,
                        count: counts[c] ?? 0,
                        selected: _cat == c,
                        onTap: () {
                          iosTapBuzz();
                          setState(() => _cat = c);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _title,
                  autofocus: !editing,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TodoPal.ink,
                  ),
                  decoration: _field('Nama tugas'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.5,
                    height: 1.4,
                    color: TodoPal.ink,
                  ),
                  decoration: _field('Deskripsi (opsional)', isMultiLine: true),
                ),
                const SizedBox(height: 14),

                _label('Prioritas'),
                Row(
                  children: [
                    for (var i = 0; i < _pris.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _pri = i),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _pri == i
                                  ? TodoPal.mintSoft
                                  : TodoPal.field,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _pri == i
                                    ? TodoPal.mintBorder
                                    : TodoPal.hair,
                              ),
                            ),
                            child: Text(
                              _pris[i],
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _pri == i
                                    ? TodoPal.mintDeep
                                    : TodoPal.sec,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                _label('Jam & pengingat'),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: Neu.well(r: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: TodoPal.mintDeep,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _timeMin == null
                                      ? 'Tanpa jam'
                                      : timeLabel(_timeMin!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: TodoPal.ink,
                                  ),
                                ),
                              ),
                              if (_timeMin != null)
                                InkWell(
                                  onTap: () => setState(() {
                                    _timeMin = null;
                                    _reminder = false;
                                  }),
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: TodoPal.ter,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: Neu.well(r: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 17,
                              color: TodoPal.mintDeep,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Ingatkan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TodoPal.ink,
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch.adaptive(
                                value: _reminder && _timeMin != null,
                                activeThumbColor: Star.onAccent,
                                activeTrackColor: TodoPal.mint,
                                onChanged: _timeMin == null
                                    ? null
                                    : (v) => setState(() => _reminder = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _label('Pengulangan'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in const {
                      '': 'Tidak berulang',
                      'harian': 'Harian',
                      'mingguan': 'Mingguan',
                      'bulanan': 'Bulanan',
                    }.entries)
                      _optionPill(
                        label: r.value,
                        selected: _repeat == r.key,
                        onTap: () => setState(() {
                          _repeat = r.key;
                          if (_repeat.isNotEmpty) _routine = true;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                _label('Alarm & rutinitas'),
                _switchRow(
                  icon: Icons.alarm_rounded,
                  title: 'Alarm layar penuh',
                  subtitle: 'Bangunkan layar terkunci saat jam tiba.',
                  value: _alarm && _timeMin != null,
                  onChanged: _timeMin == null
                      ? null
                      : (v) => setState(() {
                          _alarm = v;
                          if (v) _routine = true;
                        }),
                ),
                const SizedBox(height: 8),
                _switchRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Rutinitas bulanan',
                  subtitle: 'Catat tiap selesai di tracker bulan ini.',
                  value: _routine,
                  onChanged: (v) => setState(() => _routine = v),
                ),
                const SizedBox(height: 14),

                _label('Nada pengingat tugas'),
                Text(
                  _sound.isEmpty
                      ? 'Mengikuti setelan global: ${AppState.I.notifSoundLabel}.'
                      : 'Khusus tugas ini: ${TodoNotif.soundLabel(_sound)}.',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: TodoPal.ter,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _soundPill(
                      key: '',
                      label: 'Ikuti setelan',
                      selected: _sound.isEmpty,
                    ),
                    for (final s in const ['sistem', 'ding', 'chime', 'lembut'])
                      _soundPill(
                        key: s,
                        label: TodoNotif.soundLabel(s),
                        selected: _sound == s,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                _label('Nada alarm kustom'),
                const SizedBox(height: 7),
                const CustomAlarmCard(dense: true),
                const SizedBox(height: 6),
                const Text(
                  'Berlaku untuk semua alarm layar penuh. Notifikasi biasa tetap '
                  'memakai nada pengingat di atas.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10.5,
                    height: 1.4,
                    color: TodoPal.ter,
                  ),
                ),
                const SizedBox(height: 10),

                // Status izin notifikasi (hanya bila perlu).
                if (TodoNotif.ready && !TodoNotif.granted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: _askPermission,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: TodoPal.amberSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: TodoPal.amber,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Izin notifikasi belum aktif — ketuk untuk mengizinkan.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  color: TodoPal.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                _label('Bonus XP'),
                TextField(
                  controller: _xp,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.5,
                    color: TodoPal.ink,
                  ),
                  decoration: _field('10'),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: TodoPal.header,
                      foregroundColor: Star.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(editing ? 'Simpan perubahan' : 'Buat tugas'),
                  ),
                ),
                if (editing) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: TextButton.icon(
                      onPressed: _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: TodoPal.coral,
                        textStyle: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Hapus tugas'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? TodoPal.mintSoft : TodoPal.field,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? TodoPal.mintBorder : TodoPal.hair,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? TodoPal.mintDeep : TodoPal.sec,
          ),
        ),
      ),
    );
  }

  Widget _soundPill({
    required String key,
    required String label,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _sound = key);
        TodoNotif.showTest(sound: key);
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? TodoPal.header : TodoPal.field,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: selected ? TodoPal.header : TodoPal.hair),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.graphic_eq_rounded,
                size: 13,
                color: Star.onAccent,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Star.onAccent : TodoPal.sec,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 3, 4, 3),
      decoration: Neu.well(r: 12),
      child: Row(
        children: [
          Icon(icon, size: 17, color: TodoPal.mintDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: TodoPal.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      height: 1.4,
                      color: TodoPal.ter,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch.adaptive(
              value: value,
              activeThumbColor: Star.onAccent,
              activeTrackColor: TodoPal.mint,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: TodoPal.ter,
      ),
    ),
  );
}

class _EditorDateStrip extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onPick;
  final VoidCallback onCalendar;

  const _EditorDateStrip({
    required this.selected,
    required this.onPick,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _EditorDay(
                label: i == 0
                    ? 'Hari ini'
                    : kTodoHariPendek[today.add(Duration(days: i)).weekday],
                date: today.add(Duration(days: i)),
                selected: i == 0
                    ? selected == null
                    : selected != null &&
                          dKey(selected!) == dKey(today.add(Duration(days: i))),
                onTap: () =>
                    onPick(i == 0 ? null : today.add(Duration(days: i))),
              ),
            ),
          ],
          const SizedBox(width: 6),
          InkWell(
            onTap: onCalendar,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 46,
              height: 52,
              decoration: Neu.well(r: 12),
              child: const Icon(
                Icons.event_rounded,
                size: 18,
                color: TodoPal.mintDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorDay extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  const _EditorDay({
    required this.label,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: selected
            ? BoxDecoration(
                color: TodoPal.header,
                borderRadius: BorderRadius.circular(12),
              )
            : Neu.raised(r: 12, d: 3),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected ? Star.onAccent70 : TodoPal.ter,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${date.day} ${kTodoBulan[date.month]}',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Star.onAccent : TodoPal.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String cat;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.cat,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? TodoPal.mintDeep : TodoPal.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? TodoPal.mintSoft : TodoPal.field,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TodoPal.mintBorder : TodoPal.hair,
          ),
        ),
        child: Row(
          children: [
            Icon(todoCatIcon(cat), size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  Text(
                    '$count tugas',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      color: TodoPal.ter,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: TodoPal.mintDeep,
              ),
          ],
        ),
      ),
    );
  }
}
