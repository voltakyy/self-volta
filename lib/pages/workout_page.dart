import 'dart:async';

import 'package:flutter/material.dart';

import 'aktivitas_page.dart';
import 'choice_plan_page.dart';
import 'workout_reminder_sheet.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class WorkoutPage extends StatelessWidget {
  final void Function(String)? onNavigate;
  const WorkoutPage({super.key, this.onNavigate});

  void _showWorkoutTutorial(BuildContext context) {
    showInteractiveSpotlightTutorial(
      context,
      tutorialTitle: 'Panduan Latihan Kalistenik',
      steps: const [
        TutorialStepItem(
          title: 'Rutinitas Kalistenik Harian',
          category: 'Program Latihan Mandiri',
          featureTag: 'Siklus 3 Hari Latihan',
          description: 'Program kalistenik tanpa alat terstruktur: Senin (Pull & Push), Rabu (Wide & Legs), Jumat (Upper & Core). Hari lainnya difokuskan untuk mobilitas & pemulihan otot.',
          tip: 'Lakukan sesi latihan di sore hari (16.30) saat suhu inti tubuh dan kekuatan otot berada pada puncaknya.',
          icon: Icons.fitness_center_rounded,
          accentColor: Star.star,
        ),
        TutorialStepItem(
          title: 'Gamifikasi Adil Anti-Grind',
          category: 'Progres Konsistensi',
          featureTag: 'XP Simetris & Terlindungi',
          description: 'Setiap gerakan yang dituntaskan memberi +15 XP. Jika dibatalkan, XP dikurangi secara simetris sehingga bebas dari celah grinding/spam.',
          tip: 'Rutin peregangan dan mobilitas juga memberikan bonus XP harian sekali klaim per hari.',
          icon: Icons.military_tech_rounded,
          accentColor: Star.star,
        ),
        TutorialStepItem(
          title: 'Metronome Tempo & Timer Istirahat',
          category: 'Optimalisasi Repetisi',
          featureTag: 'Time Under Tension',
          description: 'Gunakan metronome audio untuk menjaga tempo repetisi: 2-3 detik fase turun (eksentrik) dan 1 detik fase dorong/tarik untuk hypertrophy maksimal.',
          tip: 'Gunakan rest timer 60 detik antar set agar otot pulih optimal tanpa kehilangan fokus latihan.',
          icon: Icons.timer_rounded,
          accentColor: Star.success,
        ),
        TutorialStepItem(
          title: 'Choice Plan: Kustom Gerakan',
          category: 'Kustomisasi Tingkat Lanjut',
          featureTag: 'Maksimal 3 Set',
          description: 'Ingin memilih variasi gerakan sendiri? Ketuk banner Choice Plan di atas. Kamu bebas menentukan gerakan dengan batasan ilmiah maksimal 3 set per gerakan.',
          tip: 'Saran pelatih: Lebih baik dibanyakin reps nya dan set nya udah tiga aja dalam satu gerakan ini.',
          icon: Icons.tune_rounded,
          accentColor: Star.star,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Themes.workout;
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (_, _) {
        final st = AppState.I;
        final now = DateTime.now();

        // Status Sesi Latihan Hari Ini
        String todayStatus;
        Color todayStatusColor;
        if (now.weekday == 1) {
          todayStatus = 'Hari Latihan: Sesi 1 (Pull & Push)';
          todayStatusColor = Star.workout;
        } else if (now.weekday == 3) {
          todayStatus = 'Hari Latihan: Sesi 2 (Wide & Legs)';
          todayStatusColor = Star.workout;
        } else if (now.weekday == 5) {
          todayStatus = 'Hari Latihan: Sesi 3 (Upper & Core)';
          todayStatusColor = Star.workout;
        } else {
          todayStatus = 'Hari Pemulihan & Mobilitas (Rest Day)';
          todayStatusColor = Star.study;
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            SecHead(
              'workout',
              Icons.fitness_center_rounded,
              'Latihan & Pembentukan Otot',
              'Tanpa alat • Kalistenik • Bebas cedera',
            ),
            // Aksi header dipisah ke baris sendiri: judul panjang butuh
            // lebar penuh agar tidak pecah di tengah kata.
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Row(
                children: [
                  TutorialPillButton(
                    onTap: () => _showWorkoutTutorial(context),
                    label: 'Panduan',
                    color: c.acc,
                  ),
                  const SizedBox(width: 8),
                  PopTap(
                    key: const Key('workout-reminder-btn'),
                    onTap: () => showWorkoutReminderSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: c.acc.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            st.workoutReminderOn
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            size: 14,
                            color: c.acc,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            st.workoutReminderShort,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: c.acc,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // HERO SHORTCUT: CHOICE PLAN (TENTUKAN SENDIRI LATIHAN HARI INI)
            // ============================================================
            _buildChoicePlanHeroCard(context),
            const SizedBox(height: 14),

            // ============================================================
            // REKAM AKTIVITAS GPS (LARI, JALAN KAKI, SEPEDA)
            // ============================================================
            const AktivitasCard(),
            const SizedBox(height: 14),

            // ============================================================
            // 0. WORKOUT VOLUME & STATUS SUMMARY HUB (KOMPLEKS & INFORMATIF)
            // ============================================================
            _buildWorkoutVolumeSummary(st, todayStatus, todayStatusColor),
            const SizedBox(height: 14),

            // ============================================================
            // 1. REST TIMER (JEDA SET INTERAKTIF)
            // ============================================================
            const _WorkoutRestTimer(),
            const SizedBox(height: 14),

            // ============================================================
            // 2. CHECKLIST MINGGU INI (SENIN, RABU, JUMAT)
            // ============================================================
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HRow(
                    Icons.event_available_rounded,
                    'workout',
                    'Program Latihan 3x Seminggu',
                    'Tersimpan otomatis per minggu',
                  ),
                  for (final s in SESSIONS) _SessionCard(s, c),
                  const SizedBox(height: 14),
                  const _DailyResetCard(),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ============================================================
            // 3. SECTION FOKUS TUBUH (2x2 DARK CARDS DENGAN TOMBOL NYATA)
            // ============================================================
            _buildSectionHeader(
              title: 'Fokus Tubuh (Target Otot)',
              subtitle:
                  'Pilih modul & ketuk tombol untuk mulai sesi interaktif',
              icon: Icons.sports_gymnastics_rounded,
            ),
            const SizedBox(height: 12),
            _buildMuscleFocusGrid(context),
            const SizedBox(height: 20),

            // ============================================================
            // 4. SECTION PEREGANGAN & PEMULIHAN
            // ============================================================
            _buildSectionHeader(
              title: 'Peregangan & Pemulihan',
              subtitle: 'Sebelum / sesudah latihan & relaksasi sendi',
              icon: Icons.accessibility_new_rounded,
            ),
            const SizedBox(height: 12),
            _buildStretchingHorizontalList(context),
            const SizedBox(height: 20),

            // ============================================================
            // 5. ATURAN AMAN & NUTRISI OTOT
            // ============================================================
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HRow(
                    Icons.shield_rounded,
                    'workout',
                    'Aturan Aman & Nutrisi Otot',
                    'Kusen beton, handuk tebal, deload teratur',
                  ),
                  const SizedBox(height: 8),
                  const FactList([
                    'Latihan sore 16.30–17.15, minimal 2 jam setelah makan besar.',
                    'Handuk wajib di kusen beton; turun pelan 3 detik, jangan kip.',
                    'Volume rendah, progresi tiap 10–14 hari, deload minggu ke-4.',
                  ]),
                  const SizedBox(height: 12),
                  const MarginNote(
                    'Hari latihan: tambah telur 1 + pisang 100g (±170 kkal) di atas booster harian. Target hari latihan ±2.500 kkal.',
                    label: 'Nutrisi hari latihan',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // HERO SHORTCUT: CHOICE PLAN (RANCANG SENDIRI LATIHAN HARI INI)
  // -------------------------------------------------------------
  Widget _buildChoicePlanHeroCard(BuildContext context) {
    return Container(
      decoration: Neu.raised(r: 22, d: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            iosTapBuzz();
            if (onNavigate != null) {
              onNavigate!('choice_plan');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChoicePlanPage(onNavigate: onNavigate),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Paper.amberInk.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Paper.amberInk.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: Paper.amberInk,
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'CHOICE PLAN • KUSTOM HARIAN',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Paper.amberInk,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Star.mut,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Latihan apa hari ini?',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Star.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bebas atur repetisi mandiri, target durasi jam latihan, asupan nutrisi & rest timer fleksibel (+30s / lewati).',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    color: Star.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _heroChip(
                      Icons.fitness_center_rounded,
                      'Kustom Reps & Set',
                    ),
                    _heroChip(Icons.shield_rounded, 'Maksimal 3 Set'),
                    _heroChip(Icons.timer_rounded, 'Target Jam/Menit'),
                    _heroChip(Icons.monitor_weight_rounded, 'Nutrisi & BMI'),
                    _heroChip(Icons.hourglass_top_rounded, 'Smart Rest Timer'),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: Neu.raised(r: 14, d: 4),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, size: 18, color: Star.star),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Rancang Sesi Choice Plan Sekarang',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Star.star,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Star.ink.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Star.ink),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Star.ink,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 0. WORKOUT VOLUME & STATUS SUMMARY HUB
  // -------------------------------------------------------------
  static Widget _buildWorkoutVolumeSummary(
    AppState st,
    String todayStatus,
    Color statusColor,
  ) {
    int workoutDoneCount = 0;
    st.workoutDone.forEach((k, v) {
      if (v == true) workoutDoneCount++;
    });

    final double weeklyProgress = (workoutDoneCount / 12.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Neu.raised(r: 20, d: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Status Hari Ini
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todayStatus,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$workoutDoneCount Selesai',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar Volume Mingguan
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progres Volume Gerakan Mingguan',
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    color: Star.mut,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(weeklyProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Star.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SegmentTrack(
            count: 12,
            active: workoutDoneCount.clamp(0, 12),
            color: statusColor,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SECTION HEADER
  // -------------------------------------------------------------
  static Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Star.workout, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Star.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: Star.mut,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 3. FOKUS TUBUH (2x2 GRID DARK CARDS DENGAN TOMBOL ACTION NYATA)
  // -------------------------------------------------------------
  static Widget _buildMuscleFocusGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: MuscleFocusCard(
                label: 'Dada',
                subtitle: 'Push-up & Pectoral',
                icon: Icons.fitness_center_rounded,
                timeTag: '12-15 Mnt',
                exerciseCount: '4 Gerakan',
                xpTag: '+50 XP',
                onTap: () {
                  _showInteractiveWorkoutSession(
                    context,
                    title: 'Fokus Otot Dada (Chest)',
                    subtitle: '4 Gerakan • 12 Set • Est. ~120 kkal',
                    icon: Icons.fitness_center_rounded,
                    exercises: [
                      const _ExerciseItem(
                        name: 'Diamond Push-Up',
                        targetMuscle: 'Dada Tengah & Triceps',
                        sets: 3,
                        reps: '8-12 reps',
                        difficulty: 'Menengah',
                        formTips: 'Ibu jari & telunjuk membentuk segitiga di bawah dada. Siku mengarah 45° ke belakang, turun pelan 3 detik lalu dorong kuat.',
                      ),
                      const _ExerciseItem(
                        name: 'Decline Push-Up',
                        targetMuscle: 'Dada Atas (Upper Chest)',
                        sets: 3,
                        reps: '8-12 reps',
                        difficulty: 'Menengah',
                        formTips: 'Kaki di atas kursi/kasur, kunci otot perut seperti papan kayu. Dorong dada menjauh dari lantai tanpa melengkungkan pinggang.',
                      ),
                      const _ExerciseItem(
                        name: 'Push-Up Slow 3s Tempo',
                        targetMuscle: 'Time-Under-Tension Hipertrofi',
                        sets: 3,
                        reps: '10 reps',
                        difficulty: 'Tinggi',
                        formTips: 'Turun perlahan dalam hitungan 3 detik, tahan 0.5 detik di dasar tanpa menyentuh lantai, dorong eksplosif 1 detik.',
                      ),
                      const _ExerciseItem(
                        name: 'Wide Grip Push-Up',
                        targetMuscle: 'Dada Luar (Outer Pectoral)',
                        sets: 3,
                        reps: '10-15 reps',
                        difficulty: 'Pemula',
                        formTips: 'Rentangkan tangan lebih lebar dari bahu. Rasakan regangan serat dada maksimal saat berada di posisi terbawah.',
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MuscleFocusCard(
                label: 'Lengan & Bahu',
                subtitle: 'Pull-up & Deltoid',
                icon: Icons.sports_martial_arts_rounded,
                timeTag: '15-18 Mnt',
                exerciseCount: '4 Gerakan',
                xpTag: '+50 XP',
                onTap: () {
                  _showInteractiveWorkoutSession(
                    context,
                    title: 'Fokus Lengan & Bahu',
                    subtitle: '4 Gerakan • 16 Set • Est. ~140 kkal',
                    icon: Icons.sports_martial_arts_rounded,
                    exercises: [
                      const _ExerciseItem(
                        name: 'Pull-Up Close Grip',
                        targetMuscle: 'Biceps & Punggung Atas',
                        sets: 5,
                        reps: '3-4 reps',
                        difficulty: 'Tinggi',
                        formTips: 'Tangan selebar bahu menghadap ke badan, tarik dagu lewati kusen pintu tanpa mengayun badan.',
                      ),
                      const _ExerciseItem(
                        name: 'Pike Push-Up',
                        targetMuscle: 'Bahu Depan & Trapezius',
                        sets: 3,
                        reps: '6-10 reps',
                        difficulty: 'Menengah',
                        formTips: 'Pinggul dinaikkan membentuk huruf V terbalik, turunkan kepala diagonal ke depan di antara kedua tangan.',
                      ),
                      const _ExerciseItem(
                        name: 'Prone Butterfly',
                        targetMuscle: 'Bahu Belakang & Postur',
                        sets: 3,
                        reps: '10 reps',
                        difficulty: 'Pemula',
                        formTips: 'Tengkurap di lantai, rentangkan tangan ke samping dan putar ke belakang sambil meremas belikat.',
                      ),
                      const _ExerciseItem(
                        name: 'Pull-Up Wide Grip',
                        targetMuscle: 'Sayap (Lats) & Cengkeraman',
                        sets: 5,
                        reps: '3-4 reps',
                        difficulty: 'Tinggi',
                        formTips: 'Pegang kusen lebih lebar dari bahu, fokus menarik siku ke arah pinggul untuk melebarkan sayap.',
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MuscleFocusCard(
                label: 'Bokong & Kaki',
                subtitle: 'Squat & Quadriceps',
                icon: Icons.directions_walk_rounded,
                timeTag: '12-15 Mnt',
                exerciseCount: '4 Gerakan',
                xpTag: '+50 XP',
                onTap: () {
                  _showInteractiveWorkoutSession(
                    context,
                    title: 'Fokus Bokong & Kaki',
                    subtitle: '4 Gerakan • 12 Set • Est. ~150 kkal',
                    icon: Icons.directions_walk_rounded,
                    exercises: [
                      const _ExerciseItem(
                        name: 'Bodyweight Squat',
                        targetMuscle: 'Paha Depan & Stabilitas',
                        sets: 3,
                        reps: '15-20 reps',
                        difficulty: 'Pemula',
                        formTips: 'Kaki selebar bahu, dorong pinggul ke belakang seperti hendak duduk di kursi, lutut tidak melebihi jemari kaki.',
                      ),
                      const _ExerciseItem(
                        name: 'Walking Lunges',
                        targetMuscle: 'Paha Belakang & Gluteus',
                        sets: 3,
                        reps: '10 reps/kaki',
                        difficulty: 'Menengah',
                        formTips: 'Langkah panjang ke depan, turunkan badan tegak hingga kedua lutut membentuk sudut 90 derajat.',
                      ),
                      const _ExerciseItem(
                        name: 'Glute Bridge',
                        targetMuscle: 'Bokong & Postur Panggul',
                        sets: 3,
                        reps: '15 reps',
                        difficulty: 'Pemula',
                        formTips: 'Tidurlah telentang dengan lutut ditekuk. Angkat pinggul tinggi-tinggi dan remas bokong selama 1 detik di atas.',
                      ),
                      const _ExerciseItem(
                        name: 'Calf Raises Tempo',
                        targetMuscle: 'Otot Betis & Keseimbangan',
                        sets: 3,
                        reps: '20 reps',
                        difficulty: 'Pemula',
                        formTips: 'Jinjit setinggi mungkin di ujung kaki, tahan 1 detik di puncak, lalu turun perlahan 2 detik.',
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MuscleFocusCard(
                label: 'Sixpack & Perut',
                subtitle: 'Core & Endurance',
                icon: Icons.view_headline_rounded,
                timeTag: '10-12 Mnt',
                exerciseCount: '4 Gerakan',
                xpTag: '+50 XP',
                onTap: () {
                  _showInteractiveWorkoutSession(
                    context,
                    title: 'Fokus Core & Sixpack',
                    subtitle: '4 Gerakan • 12 Set • Est. ~100 kkal',
                    icon: Icons.view_headline_rounded,
                    exercises: [
                      const _ExerciseItem(
                        name: 'Dead Bug',
                        targetMuscle: 'Core Dalam & Pinggang Aman',
                        sets: 3,
                        reps: '8 reps/sisi',
                        difficulty: 'Pemula',
                        formTips: 'Punggung bawah harus menempel rapat di lantai. Gerakkan tangan kanan dan kaki kiri berlawanan secara bersamaan.',
                      ),
                      const _ExerciseItem(
                        name: 'Bird Dog',
                        targetMuscle: 'Stabilitas Tulang Belakang',
                        sets: 3,
                        reps: '8 reps/sisi',
                        difficulty: 'Pemula',
                        formTips: 'Posisi merangkak, angkat tangan dan kaki diagonal lurus sejajar badan. Tahan 1 detik di ujung gerakan.',
                      ),
                      const _ExerciseItem(
                        name: 'Plank Isometrik',
                        targetMuscle: 'Transversus Abdominis',
                        sets: 3,
                        reps: '30-45 detik',
                        difficulty: 'Menengah',
                        formTips: 'Tumpuan pada siku dan ujung kaki. Kencangkan perut dan bokong, jangan biarkan pinggang melorot ke bawah.',
                      ),
                      const _ExerciseItem(
                        name: 'Hollow Body Hold',
                        targetMuscle: 'Kekuatan Rektus Abdominis',
                        sets: 3,
                        reps: '20-30 detik',
                        difficulty: 'Tinggi',
                        formTips: 'Angkat bahu dan tumit 10 cm dari lantai, bentuk tubuh menyerupai perahu pisang yang melengkung stabil.',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 4. INTERACTIVE WORKOUT SESSION RUNNER (PLAYER LATIHAN KOMPLEKS)
  // -------------------------------------------------------------
  static void _showInteractiveWorkoutSession(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_ExerciseItem> exercises,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _InteractiveWorkoutModal(
          title: title,
          subtitle: subtitle,
          icon: icon,
          exercises: exercises,
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 5. PEREGANGAN HORIZONTAL LIST
  // -------------------------------------------------------------
  static Widget _buildStretchingHorizontalList(BuildContext context) {
    final list = [
      (
        'Peregangan Seluruh Tubuh',
        '5 Menit • Mobilitas sendi',
        Icons.self_improvement_rounded,
        Star.star,
        [
          'Leher memutar pelan searah jarum jam & kebalikan (10x)',
          'Peregangan bahu & lengan di kusen pintu (30s/sisi)',
          'Cat-Cow stretch di lantai untuk kelenturan punggung (10 rep)',
          'Hamstring & betis stretch dengan meluruskan kaki (30s/kaki)',
        ],
      ),
      (
        'Pemanasan Pagi',
        '3 Menit • Aktifkan otot',
        Icons.wb_sunny_rounded,
        Star.star,
        [
          'Arm circles putaran besar bahu (15x)',
          'Jumping jacks ritmis ringan (20x)',
          'Bodyweight half squat untuk lutut (10x)',
          'Peregangan pinggang memutar kiri-kanan (10x)',
        ],
      ),
      (
        'Redakan Ketegangan Bahu',
        '4 Menit • Bahu & leher enteng',
        Icons.front_hand_rounded,
        Star.star,
        [
          'Cross-body shoulder stretch menarik lengan ke dada (25s/sisi)',
          'Overhead triceps stretch siku di belakang kepala (25s/sisi)',
          'Chest opener tangan dikaitkan ke belakang punggung (30s)',
          'Pelemasan leher miring kiri & kanan perlahan (20s/sisi)',
        ],
      ),
      (
        'Peregangan Sebelum Tidur',
        '5 Menit • Tidur lebih nyenyak',
        Icons.bedtime_rounded,
        Star.star,
        [
          'Child’s pose duduk bersimpuh meregangkan tangan (45s)',
          'Reclining spinal twist memutar lutut ke samping (30s/sisi)',
          'Kaki lurus di tembok (Legs-up-the-wall pose 60s)',
          'Tarik napas dalam 4-7-8 untuk menurunkan detak jantung',
        ],
      ),
    ];

    return SizedBox(
      height: 136 + (MediaQuery.textScalerOf(context).scale(1) - 1) * 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, idx) {
          final item = list[idx];
          return _stretchCard(
            context,
            title: item.$1,
            subtitle: item.$2,
            icon: item.$3,
            color: item.$4,
            steps: item.$5,
          );
        },
      ),
    );
  }

  static Widget _stretchCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> steps,
  }) {
    final now = DateTime.now();
    final stretchKey =
        'stretch_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${now.year}_${now.month}_${now.day}';
    final bool isStretchDone = AppState.I.eaten[stretchKey] == true;

    return InkWell(
      onTap: () {
        iosTapBuzz();
        _showRoutineModal(context, title, subtitle, icon, color, steps);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isStretchDone
              ? Star.star.withValues(alpha: 0.08)
              : Star.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isStretchDone
                ? Star.star.withValues(alpha: 0.45)
                : color.withValues(alpha: 0.25),
            width: isStretchDone ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isStretchDone ? Star.star : color).withValues(
                alpha: 0.08,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isStretchDone ? Star.star : color).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isStretchDone ? Icons.check_circle_rounded : icon,
                    color: isStretchDone ? Star.star : color,
                    size: 20,
                  ),
                ),
                if (isStretchDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Star.star.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '✓ Selesai',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Star.star,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isStretchDone ? Star.star : Star.ink,
                height: 1.25,
                decoration: isStretchDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              isStretchDone ? 'Tuntas hari ini (+30 XP)' : subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10.5,
                color: isStretchDone ? Star.star : Star.mut,
                fontWeight: isStretchDone ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showRoutineModal(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<String> steps,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Star.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Star.sunken,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Star.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: Star.mut,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Langkah Gerakan:',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Star.ink,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: Star.ink,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Builder(
              builder: (ctx) {
                final now = DateTime.now();
                final stretchKey =
                    'stretch_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${now.year}_${now.month}_${now.day}';
                final bool isStretchDone = AppState.I.eaten[stretchKey] == true;

                if (isStretchDone) {
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Batalkan Status Selesai?'),
                            content: Text(
                              'Peregangan "$title" sudah dituntaskan hari ini (+30 XP). Batalkan checklist dan kurangi 30 XP?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('Tetap Selesai'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dCtx);
                                  Navigator.pop(context);
                                  iosTapBuzz();
                                  AppState.I.eaten.remove(stretchKey);
                                  AppState.I.removeXp(30);
                                  unawaited(AppState.I.save());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Status "$title" dibatalkan (-30 XP)',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Ya, Batalkan',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Star.onAccent,
                      ),
                      label: const Text('✓ Sudah Selesai Hari Ini (+30 XP)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Star.star,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      AppState.I.eaten[stretchKey] = true;
                      AppState.I.addXp(30);
                      unawaited(AppState.I.save());
                      showEpicCelebrationDialog(
                        context: context,
                        title: 'Peregangan Tuntas!',
                        message: 'Otot lebih rileks, mobilitas sendi terjaga, dan pemulihan tubuh optimal.',
                        xpReward: 30,
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Tandai Selesai (+30 XP)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseItem {
  final String name;
  final String targetMuscle;
  final int sets;
  final String reps;
  final String difficulty;
  final String formTips;

  const _ExerciseItem({
    required this.name,
    required this.targetMuscle,
    required this.sets,
    required this.reps,
    required this.difficulty,
    required this.formTips,
  });
}

// ============================================================================
// INTERACTIVE WORKOUT SESSION RUNNER (MODAL PLAYER DENGAN SET LOGGER & TIMER)
// ============================================================================

class _InteractiveWorkoutModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_ExerciseItem> exercises;

  const _InteractiveWorkoutModal({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.exercises,
  });

  @override
  State<_InteractiveWorkoutModal> createState() =>
      _InteractiveWorkoutModalState();
}

class _InteractiveWorkoutModalState extends State<_InteractiveWorkoutModal> {
  late List<List<bool>> _checkedSets;
  Timer? _restTimer;
  int _restSecondsLeft = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _checkedSets = widget.exercises
        .map((e) => List.filled(e.sets, false))
        .toList();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestCountdown(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSecondsLeft = seconds;
      _isResting = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsLeft <= 1) {
        timer.cancel();
        triumphBuzz();
        if (mounted) {
          setState(() {
            _restSecondsLeft = 0;
            _isResting = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _restSecondsLeft--);
        }
      }
    });
  }

  int get _totalSets => widget.exercises.fold(0, (a, e) => a + e.sets);
  int get _completedSets =>
      _checkedSets.fold(0, (a, list) => a + list.where((c) => c).length);
  double get _progress => _totalSets > 0 ? _completedSets / _totalSets : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Star.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Star.sunken,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header Latihan & Overall Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Star.star,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: Star.onAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Star.ink,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11.5,
                          color: Star.mut,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Star.mut),
                ),
              ],
            ),
          ),

          // Progress Bar Keseluruhan Set
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progres Set: $_completedSets dari $_totalSets Selesai',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Star.mut,
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Star.star,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: Star.sunken,
                    valueColor: const AlwaysStoppedAnimation(Star.star),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Star.sunken),

          // List Gerakan & Checkbox Set Interaktif
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: widget.exercises.length,
              itemBuilder: (context, exIdx) {
                final ex = widget.exercises[exIdx];
                final exerciseSetsDone = _checkedSets[exIdx].every(
                  (s) => s == true,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: exerciseSetsDone
                        ? Star.star.withValues(alpha: 0.06)
                        : Star.bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: exerciseSetsDone
                          ? Star.star.withValues(alpha: 0.3)
                          : Star.sunken,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Gerakan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      ex.name,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Star.ink,
                                      ),
                                    ),
                                    if (exerciseSetsDone) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: Star.star,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Target: ${ex.targetMuscle} • ${ex.reps}',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11,
                                    color: Star.star,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Star.sunken,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ex.difficulty,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Star.mut,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Form Guide (Petunjuk Form)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Star.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 14,
                              color: Star.star,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ex.formTips,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10.5,
                                  color: Star.mut,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row Tombol Set (Logger Interaktif)
                      Row(
                        children: [
                          for (int s = 0; s < ex.sets; s++) ...[
                            Expanded(
                              child: _setCheckButton(
                                setNum: s + 1,
                                reps: ex.reps,
                                isChecked: _checkedSets[exIdx][s],
                                onTap: () {
                                  iosTapBuzz();
                                  final nextVal = !_checkedSets[exIdx][s];
                                  setState(() {
                                    _checkedSets[exIdx][s] = nextVal;
                                  });
                                  if (nextVal) {
                                    // Mulai timer jeda istirahat otomatis 45 detik
                                    _startRestCountdown(45);
                                  }
                                },
                              ),
                            ),
                            if (s < ex.sets - 1) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Floating Rest Timer Bar (Jika Sedang Istirahat Antar-Set)
          if (_isResting && _restSecondsLeft > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Star.star,
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    color: Paper.amberInk,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jeda Istirahat: ${_restSecondsLeft}s',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Star.onAccent,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _startRestCountdown(_restSecondsLeft + 15),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      '+15s',
                      style: TextStyle(
                        color: Paper.amberInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _restTimer?.cancel();
                      setState(() {
                        _restSecondsLeft = 0;
                        _isResting = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(color: Star.onAccent70, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Button: Selesaikan Sesi & Klaim +50 XP
          // (anti-grinding: 1x klaim per hari sebelum reset 00.00)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: Builder(
                builder: (ctx) {
                  final alreadyClaimed = AppState.I.isClaimed('sesi_fokus');
                  return FilledButton.icon(
                    onPressed: alreadyClaimed
                        ? null
                        : () {
                            triumphBuzz();
                            Navigator.pop(context);
                            // Klaim via buku besar XP harian; gagal =
                            // sumber sama sudah diklaim hari ini.
                            final ok = AppState.I.claimXp('sesi_fokus', 50);
                            showEpicCelebrationDialog(
                              context: context,
                              title: 'Latihan Fokus Tuntas!',
                              message: ok
                                  ? 'Target otot terstimulasi maksimal. Minum air dan penuhi nutrisi protein setelah ini!'
                                  : 'Sesi selesai! Bonus XP hari ini sudah diklaim; klaim lagi setelah reset pukul 00.00.',
                              xpReward: ok ? 50 : 0,
                            );
                          },
                    icon: alreadyClaimed
                        ? const Icon(Icons.check_circle_rounded, size: 20)
                        : const Icon(Icons.emoji_events_rounded, size: 20),
                    label: Text(
                      alreadyClaimed
                          ? 'Bonus hari ini sudah diklaim — reset 00.00'
                          : _completedSets >= _totalSets
                          ? 'Latihan 100% Selesai • Klaim +50 XP'
                          : 'Selesaikan Sesi Latihan (+50 XP)',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: alreadyClaimed
                          ? Star.sunken
                          : _completedSets >= _totalSets
                          ? Star.star
                          : Star.star,
                      foregroundColor: alreadyClaimed
                          ? Star.mut
                          : Star.onAccent,
                      disabledBackgroundColor: Star.sunken,
                      disabledForegroundColor: Star.mut,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setCheckButton({
    required int setNum,
    required String reps,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isChecked
            ? BoxDecoration(
                color: Star.star,
                borderRadius: BorderRadius.circular(10),
              )
            : Neu.raised(r: 10, d: 3),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isChecked
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 14,
                  color: isChecked ? Star.onAccent : Star.mut,
                ),
                const SizedBox(width: 4),
                Text(
                  'Set $setNum',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isChecked ? Star.onAccent : Star.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              reps,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 9.5,
                color: isChecked
                    ? Star.onAccent.withValues(alpha: 0.85)
                    : Star.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rest Timer Interaktif untuk Latihan Beban / Kalistenik
class _WorkoutRestTimer extends StatefulWidget {
  const _WorkoutRestTimer();

  @override
  State<_WorkoutRestTimer> createState() => _WorkoutRestTimerState();
}

class _WorkoutRestTimerState extends State<_WorkoutRestTimer> {
  Timer? _timer;
  int _secondsLeft = 60;
  int _initialSeconds = 60;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setTimer(int seconds) {
    iosTapBuzz();
    _timer?.cancel();
    setState(() {
      _secondsLeft = seconds;
      _initialSeconds = seconds;
      _isRunning = false;
    });
  }

  void _toggleTimer() {
    iosTapBuzz();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft <= 1) {
          timer.cancel();
          iosTapBuzz();
          setState(() {
            _secondsLeft = 0;
            _isRunning = false;
          });
        } else {
          setState(() => _secondsLeft--);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Themes.workout;
    final progress = _initialSeconds > 0 ? _secondsLeft / _initialSeconds : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Neu.raised(r: 20, d: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.acc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.timer_rounded, color: c.acc, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rest Timer Antar-Set',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Star.ink,
                            ),
                          ),
                          Text(
                            'Jeda istirahat hipertrofi otot',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10.5,
                              color: Star.mut,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Preset Interval Pills
              Row(
                children: [
                  for (final s in [30, 60, 90])
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: InkWell(
                        onTap: () => _setTimer(s),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _initialSeconds == s
                                ? c.acc
                                : Star.sunken.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${s}s',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _initialSeconds == s
                                  ? Star.onAccent
                                  : Star.mut,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Timer Countdown Bar & Play/Pause
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isRunning ? 'Waktu Istirahat' : 'Siap Mulai',
                            maxLines: 2,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: Star.mut,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_secondsLeft}s',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _secondsLeft == 0 ? Star.mut : c.acc,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Star.sunken,
                        valueColor: AlwaysStoppedAnimation(c.acc),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(_isRunning ? 'Jeda' : 'Mulai'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.acc,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class _SessionCard extends StatelessWidget {
  final ({String id, String t, List<String> ex}) s;
  final Cat c;
  const _SessionCard(this.s, this.c);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (_, _) {
        final st = AppState.I;
        final total = s.ex.length;
        var done = 0;
        for (var i = 0; i < s.ex.length; i++) {
          if (st.workoutDone['${s.id}_$i'] == true) done++;
        }
        final all = total > 0 && done == total;

        return Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: Neu.raised(r: 14, d: 4),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: all
                    ? Star.star.withValues(alpha: 0.15)
                    : c.acc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                all ? Icons.check_circle_rounded : Icons.fitness_center_rounded,
                color: all ? Star.star : c.acc,
                size: 20,
              ),
            ),
            title: Text(
              s.t,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Star.ink,
              ),
            ),
            subtitle: Text(
              '$done/$total gerakan selesai',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                color: all ? Star.star : Star.mut,
                fontWeight: all ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            children: [
              for (var i = 0; i < s.ex.length; i++)
                _ExerciseCheckItem(
                  sessionId: s.id,
                  index: i,
                  name: s.ex[i],
                  c: c,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseCheckItem extends StatelessWidget {
  final String sessionId;
  final int index;
  final String name;
  final Cat c;
  const _ExerciseCheckItem({
    required this.sessionId,
    required this.index,
    required this.name,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final key = '${sessionId}_$index';
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (_, _) {
        final isDone = AppState.I.workoutDone[key] == true;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: () {
              if (isDone) {
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Batalkan Gerakan Ini?'),
                    content: Text(
                      'Gerakan "$name" sudah tuntas (+15 XP). Batalkan checklist dan kurangi 15 XP?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: const Text('Tetap Selesai'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dCtx);
                          iosTapBuzz();
                          AppState.I.toggleWork(key);
                          AppState.I.removeXp(15);
                        },
                        child: const Text(
                          'Ya, Batalkan',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                iosTapBuzz();
                AppState.I.toggleWork(key);
                AppState.I.addXp(15);
                triumphBuzz();
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Gerakan "$name" tuntas! (+15 XP)'),
                    duration: const Duration(milliseconds: 1200),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Star.star,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDone ? Star.star.withValues(alpha: 0.08) : Star.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDone
                      ? Star.star.withValues(alpha: 0.35)
                      : Star.sunken,
                  width: isDone ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: isDone ? Star.star : Star.mut,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDone ? Star.mut : Star.ink,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Star.star.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Sudah Diceklis',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Star.star,
                              ),
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
      },
    );
  }
}

// ============================================================================
// KARTU PROGRES HARIAN + TOMBOL HAPUS PROGRES (anti-grinding)
// - Centang latihan berlaku untuk hari yang sedang berjalan.
// - Pukul 00.00 semua centang & kuota klaim XP direset otomatis.
// - Hapus progres = bersihkan centang; XP & kuota tetap terkunci
//   sampai reset otomatis (tidak bisa dipakai farm XP).
// ============================================================================
class _DailyResetCard extends StatefulWidget {
  const _DailyResetCard();

  @override
  State<_DailyResetCard> createState() => _DailyResetCardState();
}

class _DailyResetCardState extends State<_DailyResetCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Titik pengecekan ketika app terbuka di halaman ini (lintas tengah
    // malam), untuk jaga-jaga bila timer shell tidak berjalan.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      if (AppState.I.rolloverIfNewDay()) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tengah malam — progres latihan direset otomatis dan kuota XP harian terbuka lagi.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Star.star,
          ),
        );
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Teks hitungan mundur menuju reset 00.00.
  String _countdown() {
    final now = DateTime.now();
    final midnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final left = midnight.difference(now);
    final h = left.inHours;
    final m = left.inMinutes % 60;
    if (h <= 0) return 'reset dalam $m menit';
    return 'reset dalam $h jam $m menit';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final st = AppState.I;
        // Hitung gerakan yang tuntas hari ini (guard non-centang
        // `choice_plan_finished_*` dikecualikan supaya angka jujur).
        final checked = st.workoutDone.entries
            .where((e) => e.value && !e.key.startsWith('choice_plan_finished'))
            .length;
        final claims = const [
          ('sesi_fokus', 'Sesi Fokus +50 XP'),
          ('choice_plan', 'Choice Plan +60 XP'),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: Neu.well(r: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 18, color: Star.star),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Progres Latihan Hari Ini',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Star.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Star.star.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Star.star,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _countdown(),
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Star.star,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$checked gerakan tuntas hari ini. Semua centang & kuota XP direset otomatis setiap pukul 00.00.',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11.5,
                  height: 1.4,
                  color: Star.mut,
                ),
              ),
              const SizedBox(height: 10),
              // Status klaim XP hari ini (chip hijau = sudah diklaim).
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (src, label) in claims)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: st.isClaimed(src)
                            ? Star.star.withValues(alpha: 0.16)
                            : Star.sunken,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            st.isClaimed(src)
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 12,
                            color: st.isClaimed(src) ? Star.star : Star.mut,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 2,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: st.isClaimed(src) ? Star.star : Star.mut,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.auto_delete_rounded, size: 16),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Hapus progres centang?'),
                        content: const Text(
                          'Semua centang latihan hari ini akan dihapus. '
                          'XP yang sudah didapat dan bonus yang sudah '
                          'diklaim tidak dikembalikan serta tidak bisa '
                          'diklaim ulang sampai reset otomatis pukul 00.00.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              AppState.I.resetWorkout();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Centang latihan hari ini dihapus. Kuota XP menunggu reset pukul 00.00.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Star.error,
                                  ),
                                );
                            },
                            child: const Text(
                              'Ya, Hapus Progres',
                              style: TextStyle(color: Star.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  label: const Text(
                    'Hapus Progres Centang',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
