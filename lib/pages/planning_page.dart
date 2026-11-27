// Planning Page: Meja Bar Dapur Keramik Interaktif & Pola Makan Terpadu
// Self Volta - Advanced Athletic Edition (Instagram Seamless Panorama, Live Timer, Zero-Overlap Typography)

import 'dart:async';

import 'package:flutter/material.dart';

import 'workout_reminder_sheet.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class PlanningPage extends StatefulWidget {
  final ValueChanged<String>? onGo;
  const PlanningPage({super.key, this.onGo});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  // Controller untuk geser slide meja dapur panjang
  late final PageController _kitchenPageController;
  int _activeKitchenSlide = 0;
  int _activePlanningTab =
      0; // 0: Menu Hari Ini, 1: Dapur 48:9, 2: Belanja Pasar

  // State objek aktif per-slide (FIXED POSITION, TIDAK MENUMPUK)
  String _selectedCookingItem = 'panci';
  String _selectedPrepItem = 'magic_com';
  String _selectedPantryItem = 'kulkas';

  // Live Real-Time Cooking Timer
  Timer? _timer;
  int _timerSeconds = 0;
  int _timerTotalSeconds = 480;
  bool _isTimerRunning = false;
  bool _showCookingTimer = false;
  String _timerTitle = 'Panci Listrik • Rebus Kuah & Telur';

  // Scroll Controller untuk navigasi instan ke Daftar Belanja
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _grocerySectionKey = GlobalKey();

  // Indeks hari aktif yang sedang dilihat (0 = Senin s/d 6 = Minggu)
  late int _selectedDayIndex;

  // Override paket aktif jika user memilih paket tertentu dari katalog
  String? _customActivePola;

  final List<({String dayName, String defaultPola, String highlight})>
  _weekDays = [
    (
      dayName: 'Senin',
      defaultPola: 'A',
      highlight: 'Tinggi Protein Telur & Tempe',
    ),
    (
      dayName: 'Selasa',
      defaultPola: 'B',
      highlight: 'Tahu Rebus & Serat Sayur',
    ),
    (dayName: 'Rabu', defaultPola: 'C', highlight: 'Tempe & Sup Labu Segar'),
    (
      dayName: 'Kamis',
      defaultPola: 'D',
      highlight: 'Dada Ayam Bening Ekstra Protein',
    ),
    (dayName: 'Jumat', defaultPola: 'E', highlight: 'Ikan Lele & Sayur Kelor'),
    (dayName: 'Sabtu', defaultPola: 'F', highlight: 'Ikan Nila & Bening Oyong'),
    (
      dayName: 'Minggu',
      defaultPola: 'G',
      highlight: 'Telur Kukus & Sup Kentang',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _kitchenPageController = PageController();
    final now = DateTime.now();
    _selectedDayIndex = (now.weekday - 1).clamp(0, 6);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _kitchenPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // TIMER CONTROLLER METHODS
  // --------------------------------------------------------------------------
  void _startTimer(int minutes, {required String title}) {
    _timer?.cancel();
    iosTapBuzz();
    setState(() {
      _showCookingTimer = true;
      _timerTitle = title;
      _timerSeconds = minutes * 60;
      _timerTotalSeconds = minutes * 60;
      _isTimerRunning = true;
    });
    _runTicker();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _runTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        t.cancel();
        setState(() => _isTimerRunning = false);
        iosTapBuzz();
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Star.star, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Masakan Matang!',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Waktu memasak $_timerTitle telah selesai. Segera matikan kompor atau panci listrik dan hidangkan selagi hangat untuk menjaga nutrisi.',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(backgroundColor: Star.star),
                  child: const Text('Siap, Matikan'),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resumeTimer() {
    if (_timerSeconds > 0) {
      setState(() => _isTimerRunning = true);
      _runTicker();
    }
  }

  void _adjustTimer(int deltaSeconds) {
    setState(() {
      _timerSeconds = (_timerSeconds + deltaSeconds).clamp(10, 3600);
      if (_timerSeconds > _timerTotalSeconds) {
        _timerTotalSeconds = _timerSeconds;
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 0;
      _isTimerRunning = false;
    });
  }

  void _scrollToGroceries() {
    iosTapBuzz();
    setState(() {
      _activePlanningTab =
          2; // Pindah seketika ("SET!") ke Tab 2: Belanja Pasar
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  void _showCookingGuideModal(BuildContext context, Pola activePola) {
    iosTapBuzz();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Star.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Star.sunken,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Star.star.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Star.star,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Panduan Masak 15 Menit',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Star.mut,
                          ),
                        ),
                        Text(
                          '${activePola.k}: ${activePola.t}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Star.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: Neu.raised(r: 16, d: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered_rounded,
                          size: 16,
                          color: Star.star,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Langkah Eksekusi Memasak:',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Star.star,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RecipeSteps(activePola.cara, label: null),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startTimer(10, title: 'Memasak: ${activePola.t}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Timer 10 menit untuk ${activePola.t} telah aktif di atas!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text(
                    'Pasang Timer Masak 10 Menit Sekarang',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Star.star,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  void _showPlanningTutorial(BuildContext context) {
    showInteractiveSpotlightTutorial(
      context,
      tutorialTitle: 'Panduan Planning Dapur',
      steps: const [
        TutorialStepItem(
          title: '3 Stasiun Dapur Anti-Overwhelmed',
          category: 'Navigasi Dapur Ergonomis',
          featureTag: 'Sistem Geser 3 Panel',
          description: 'Dapur dibagi menjadi 3 stasiun bersih: Menu Hari Ini untuk racikan jadwal makan, Dapur Panoramik untuk visualisasi meja kompor 48:9, dan Belanja Pasar untuk daftar bahan kost.',
          tip: 'Geser layar ke kiri atau kanan, atau ketuk tombol stasiun di bagian atas untuk berpindah seketika.',
          icon: Icons.kitchen_rounded,
          accentColor: Star.star,
        ),
        TutorialStepItem(
          title: 'Timer Masak Universal Lintas Halaman',
          category: 'Asisten Memasak Presisi',
          featureTag: 'Floating Cooking Timer',
          description: 'Nyalakan timer saat merebus telur, menanak nasi, atau marinasi ayam. Timer tetap berjalan dan terlihat di stasiun mana pun kamu berada tanpa perlu bolak-balik.',
          tip: 'Alarm audio akan berbunyi otomatis saat waktu masak selesai agar masakan kost tidak gosong.',
          icon: Icons.timer_rounded,
          accentColor: Star.star,
        ),
        TutorialStepItem(
          title: 'Kalkulator Gizi & Target 80g Protein',
          category: 'Nutrisi Kalistenik',
          featureTag: 'Target Makro Atlet',
          description: 'Aplikasi memonitor asupan protein dan kalori dari menu sarapan, makan siang, makan malam, dan booster telur rebus/madu harian.',
          tip: 'Pastikan indikator protein mendekati target harian untuk mempercepat sintesis protein otot pasca latihan.',
          icon: Icons.fitness_center_rounded,
          accentColor: Star.star,
        ),
        TutorialStepItem(
          title: 'Input Menu Kustom Kost Sendiri',
          category: 'Kreativitas Masakan',
          featureTag: 'Kalkulasi Gizi Aman',
          description: 'Punya resep favorit kost sendiri? Ketuk tombol + Tambah Menu Sendiri. Bahan belanja otomatis masuk ke tab Belanja Pasar dengan proteksi nilai kalori aman.',
          tip: 'Pisahkan nama bahan dengan tanda koma agar otomatis terbagi menjadi daftar checklist belanja.',
          icon: Icons.add_circle_outline_rounded,
          accentColor: Star.success,
        ),
      ],
    );
  }

  Pola _getPolaForDay(int dayIdx) {
    if (dayIdx == _selectedDayIndex && _customActivePola != null) {
      return POLA[_customActivePola] ?? POLA['A']!;
    }
    final key = _weekDays[dayIdx].defaultPola;
    return POLA[key] ?? POLA['A']!;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final st = AppState.I;
        final now = DateTime.now();
        final currentDayNumber = now.day;

        final activePola = _getPolaForDay(_selectedDayIndex);
        final dayInfo = _weekDays[_selectedDayIndex];
        final isToday = (now.weekday - 1) == _selectedDayIndex;

        // Target nutrisi
        final dailyProteinTarget = (st.weightKg * 1.8).round();
        final baseCalorieTarget =
            ((10 * st.weightKg) + (6.25 * st.heightCm) - (5 * 25) + 5) * 1.35;
        final dailyCalorieTarget = baseCalorieTarget.round();

        // Status makan hari ini
        final bool breakfastEaten = st.eaten['e$currentDayNumber-1'] ?? false;
        final bool lunchEaten = st.eaten['e$currentDayNumber-2'] ?? false;
        final bool dinnerEaten = st.eaten['e$currentDayNumber-3'] ?? false;
        final bool boosterEaten =
            st.bought['booster_$currentDayNumber'] ?? false;

        final int mealsDone =
            (breakfastEaten ? 1 : 0) +
            (lunchEaten ? 1 : 0) +
            (dinnerEaten ? 1 : 0) +
            (boosterEaten ? 1 : 0);

        final double mealProgress = mealsDone / 4.0;
        final int currentCalEstimated = (mealProgress * dailyCalorieTarget)
            .round();
        final int currentProteinEstimated = (mealProgress * dailyProteinTarget)
            .round();

        final bool sayuranSudahDimasak = lunchEaten || dinnerEaten;

        return Scaffold(
          backgroundColor: Star.bg,
          body: Column(
            children: [
              // Top Bar Judul & Panduan Tutorial
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.soup_kitchen_rounded,
                            color: Star.star,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Planning Makan Kost',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Star.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TutorialPillButton(
                      onTap: () => _showPlanningTutorial(context),
                      label: 'Panduan',
                      color: Star.star,
                    ),
                  ],
                ),
              ),
              // --------------------------------------------------------------
              // 3-TAB SEGMENTED BAR: BEBAS SCROLLING FATIGUE (ANTI-OVERWHELMED)
              // --------------------------------------------------------------
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: Neu.raised(r: 16, d: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: _segmentedTabBtn(
                        index: 0,
                        icon: Icons.restaurant_menu_rounded,
                        label: 'Menu Hari Ini',
                        badge: 'Jadwal & Racik',
                        isActive: _activePlanningTab == 0,
                        accentColor: Star.star,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _segmentedTabBtn(
                        index: 1,
                        icon: Icons.soup_kitchen_rounded,
                        label: 'Dapur 48:9',
                        badge: 'Meja & Panduan',
                        isActive: _activePlanningTab == 1,
                        accentColor: Star.star,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _segmentedTabBtn(
                        index: 2,
                        icon: Icons.shopping_basket_rounded,
                        label: 'Belanja Pasar',
                        badge: '7 Paket Hemat',
                        isActive: _activePlanningTab == 2,
                        accentColor: Star.star,
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================================
              // UNIVERSAL LIVE COOKING TIMER (PINNED MENEMPEL DI ATAS SEMUA TAB)
              // ==========================================================
              if (_showCookingTimer)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _buildTopCookingTimerBar(activePola),
                ),

              // --------------------------------------------------------------
              // KONTEN TAB SPESIFIK (RINGKAS, CEPAT, EFEKTIF TANPA CAPEK SCROLL)
              // --------------------------------------------------------------
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  children: [
                    // === TAB 0: MENU HARI INI (FOKUS HARIAN, CEPAT & RINGKAS) ===
                    if (_activePlanningTab == 0) ...[
                      // Quick Timer Masak Cepat Hari Ini
                      _buildQuickTimerBar(
                        activePola,
                        title: 'Timer Masak Cepat Hari Ini',
                        accentColor: Star.star,
                      ),
                      const SizedBox(height: 12),

                      // Pengingat latihan (jadwal diatur user, sama dengan
                      // menu di halaman Latihan).
                      _buildWorkoutReminderStrip(),
                      const SizedBox(height: 12),

                      // Strip 7 Hari Mingguan
                      _build7DaysSelector(),
                      const SizedBox(height: 14),

                      // Checklist Jadwal 4 Waktu Makan Hari Ini + Menu Kustom
                      _buildTodayMealChecklist(
                        st: st,
                        dayNumber: currentDayNumber,
                        mealsDone: mealsDone,
                        mealProgress: mealProgress,
                        dailyCal: dailyCalorieTarget,
                        currCal: currentCalEstimated,
                        dailyProt: dailyProteinTarget,
                        currProt: currentProteinEstimated,
                        breakfastDone: breakfastEaten,
                        lunchDone: lunchEaten,
                        dinnerDone: dinnerEaten,
                        boosterDone: boosterEaten,
                        activePola: activePola,
                      ),
                      const SizedBox(height: 16),

                      // Detail Resep Ringkas 15 Menit
                      _buildRecipeDetailCard(activePola, dayInfo, isToday),
                    ],

                    // === TAB 1: MEJA DAPUR 48:9 & LIVE COOKING TIMER ===
                    if (_activePlanningTab == 1) ...[
                      // Meja Dapur 48:9 Panoramic Carousel & Workspace Inspector
                      _buildPanoramicCeramicKitchen(
                        st: st,
                        activePola: activePola,
                        sayuranSudahDimasak: sayuranSudahDimasak,
                        currentDayNumber: currentDayNumber,
                      ),
                    ],

                    // === TAB 2: DAFTAR BELANJA PASAR & 7 PAKET RESEP HEMAT ===
                    if (_activePlanningTab == 2) ...[
                      // Quick Timer Belanja & Masak Pasar
                      _buildQuickTimerBar(
                        activePola,
                        title: 'Timer Persiapan Belanja & Masak',
                        accentColor: Star.star,
                      ),
                      const SizedBox(height: 12),

                      // Daftar Belanja Pasar Mingguan
                      _buildGroceryChecklistSection(st),
                      const SizedBox(height: 18),

                      // Katalog 7 Paket Resep Hemat (A - G)
                      _build7PaketCatalogue(activePola.k),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // 0. LIVE TOP COOKING TIMER BAR
  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  // QUICK TIMER BAR LAUNCHER (TAMPIL DI TAB 0 & TAB 2 TANPA HARUS KE DAPUR)
  // --------------------------------------------------------------------------
  Widget _buildQuickTimerBar(
    Pola activePola, {
    required String title,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: Neu.well(r: 16),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: accentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const Text(
                  'Pasang timer langsung di halaman ini',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    color: Star.mut,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _quickTimerChip(5, '5m', activePola),
          const SizedBox(width: 4),
          _quickTimerChip(10, '10m', activePola),
          const SizedBox(width: 4),
          _quickTimerChip(15, '15m', activePola),
        ],
      ),
    );
  }

  Widget _buildTopCookingTimerBar(Pola activePola) {
    final bool isRunning = _isTimerRunning;
    final int sec = _timerSeconds;
    final String timeStr =
        '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
    final double progress = _timerTotalSeconds > 0
        ? (1.0 - (sec / _timerTotalSeconds)).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isRunning ? Star.deepSpace : Star.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Star.surface.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRunning
                          ? Icons.local_fire_department_rounded
                          : Icons.timer_outlined,
                      color: isRunning ? Star.star : Star.onAccent70,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRunning ? 'TIMER MEMASAK AKTIF' : 'TIMER MASAK DAPUR',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Star.onAccent,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showCookingGuideModal(context, activePola),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Star.surface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: Star.onAccent,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Panduan',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Star.onAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      iosTapBuzz();
                      setState(() => _showCookingTimer = false);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Star.surface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Star.onAccent,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Display: Timer Digit & Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Star.onAccent,
                  letterSpacing: 1.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Star.onAccent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isRunning
                          ? 'Sedang berjalan • Jangan tinggalkan kompor'
                          : sec > 0
                          ? 'Timer dijeda • Ketuk Lanjut untuk meneruskan'
                          : 'Pilih durasi cepat atau atur menit di bawah',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9.5,
                        color: Star.onAccent.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (sec > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Star.surface.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Star.star),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Baris Kontrol
          if (sec > 0) ...[
            Row(
              children: [
                _timerBtn(
                  label: '-1 Mnt',
                  icon: Icons.replay_rounded,
                  onTap: () {
                    iosTapBuzz();
                    _adjustTimer(-60);
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      iosTapBuzz();
                      if (isRunning) {
                        _pauseTimer();
                      } else {
                        _resumeTimer();
                      }
                    },
                    icon: Icon(
                      isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isRunning ? 'Jeda Timer' : 'Lanjut Timer',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isRunning ? Star.star : Star.success,
                      foregroundColor: Star.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _timerBtn(
                  label: '+1 Mnt',
                  icon: Icons.forward_rounded,
                  onTap: () {
                    iosTapBuzz();
                    _adjustTimer(60);
                  },
                ),
                const SizedBox(width: 6),
                _timerBtn(
                  label: 'Stop',
                  icon: Icons.stop_rounded,
                  color: Star.error,
                  onTap: () {
                    iosTapBuzz();
                    _stopTimer();
                  },
                ),
              ],
            ),
          ] else ...[
            // Quick preset durasi saat timer idle
            Row(
              children: [
                _quickTimerPreset(5, '5 Mnt (Sup)'),
                const SizedBox(width: 6),
                _quickTimerPreset(8, '8 Mnt (Telur)'),
                const SizedBox(width: 6),
                _quickTimerPreset(15, '15 Mnt (Kukus)'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _timerBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: (color ?? Star.surface).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color ?? Star.onAccent),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color ?? Star.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTimerPreset(int minutes, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {
          iosTapBuzz();
          _startTimer(minutes, title: 'Timer Masak $label');
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: Star.surface.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Star.line.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Star.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 1. MEJA BAR DAPUR KERAMIK (SEAMLESS PANORAMIC CAROUSEL - TERHUBUNG 0px GAP)
  // --------------------------------------------------------------------------
  Widget _buildPanoramicCeramicKitchen({
    required AppState st,
    required Pola activePola,
    required bool sayuranSudahDimasak,
    required int currentDayNumber,
  }) {
    final categories = ['1. Area Masak', '2. Meja Prep', '3. Kulkas & Stok'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Baris Judul & Status Slide
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.kitchen_rounded, color: Star.star, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Meja Bar Dapur Keramik',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Star.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Star.star.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Slide ${_activeKitchenSlide + 1}/3',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Star.star,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tab Kategori Atas (1 Baris Bersih - Menghubungkan 3 Bagian Meja)
        Row(
          children: categories.asMap().entries.map((entry) {
            final idx = entry.key;
            final title = entry.value;
            final isSel = _activeKitchenSlide == idx;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: InkWell(
                  onTap: () {
                    iosTapBuzz();
                    setState(() {
                      _activeKitchenSlide = idx;
                      if (idx == 0 &&
                          ![
                            'panci',
                            'wajan',
                            'kompor',
                          ].contains(_selectedCookingItem)) {
                        _selectedCookingItem = 'panci';
                      } else if (idx == 1 &&
                          ![
                            'magic_com',
                            'telenan',
                            'piring',
                          ].contains(_selectedPrepItem)) {
                        _selectedPrepItem = 'magic_com';
                      } else if (idx == 2 &&
                          ![
                            'kulkas',
                            'telur',
                            'bumbu',
                          ].contains(_selectedPantryItem)) {
                        _selectedPantryItem = 'kulkas';
                      }
                    });
                    _kitchenPageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? Star.star : Star.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? Star.star : Star.sunken,
                      ),
                      boxShadow: [
                        if (isSel)
                          BoxShadow(
                            color: Star.star.withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Star.onAccent : Star.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // --------------------------------------------------------------------
        // 16:9 CINEMATIC CAROUSEL (3 STASIUN DIJEJER RAPI TANPA SISA)
        // --------------------------------------------------------------------
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Paper.hair, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // PageView 3 Panel Meja Keramik yang Terhubung Mulus Tanpa Gap
                  PageView(
                    controller: _kitchenPageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (idx) {
                      iosTapBuzz();
                      setState(() {
                        _activeKitchenSlide = idx;
                        if (idx == 0 &&
                            ![
                              'panci',
                              'wajan',
                              'kompor',
                            ].contains(_selectedCookingItem)) {
                          _selectedCookingItem = 'panci';
                        } else if (idx == 1 &&
                            ![
                              'magic_com',
                              'telenan',
                              'piring',
                            ].contains(_selectedPrepItem)) {
                          _selectedPrepItem = 'magic_com';
                        } else if (idx == 2 &&
                            ![
                              'kulkas',
                              'telur',
                              'bumbu',
                            ].contains(_selectedPantryItem)) {
                          _selectedPantryItem = 'kulkas';
                        }
                      });
                    },
                    children: [
                      _buildSlide1Surface(),
                      _buildSlide2Surface(),
                      _buildSlide3Surface(st, sayuranSudahDimasak),
                    ],
                  ),

                  // Top Floating Badge & Dot Indicators
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Star.surface.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app_rounded,
                                size: 12,
                                color: Paper.amberInk,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _activeKitchenSlide == 0
                                    ? 'Stasiun 1: Area Kompor'
                                    : _activeKitchenSlide == 1
                                    ? 'Stasiun 2: Meja Prep'
                                    : 'Stasiun 3: Keranjang Sayur & Buah Kost',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Star.onAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _carouselDot(
                                _activeKitchenSlide == 0,
                                onTap: () {
                                  iosTapBuzz();
                                  _kitchenPageController.animateToPage(
                                    0,
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutCubic,
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              _carouselDot(
                                _activeKitchenSlide == 1,
                                onTap: () {
                                  iosTapBuzz();
                                  _kitchenPageController.animateToPage(
                                    1,
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutCubic,
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              _carouselDot(
                                _activeKitchenSlide == 2,
                                onTap: () {
                                  iosTapBuzz();
                                  _kitchenPageController.animateToPage(
                                    2,
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutCubic,
                                  );
                                },
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
          ),
        ),
        const SizedBox(height: 12),

        // --------------------------------------------------------------------
        // TOMBOL PINTASAN INTERAKTIF 1 BARIS (SESUAI SLIDE AKTIF)
        // --------------------------------------------------------------------
        _buildActiveStationPills(),
        const SizedBox(height: 12),

        // --------------------------------------------------------------------
        // WORKSPACE INSPECTOR DOCK (BERSIH, TANPA KARTU BERTUMPUK)
        // --------------------------------------------------------------------
        _buildActiveStationDock(activePola, st, sayuranSudahDimasak),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 1 SURFACE: AREA KOMPOR & MEMASAK (HOTSPOT LANGSUNG PADA FOTO)
  // --------------------------------------------------------------------------
  Widget _buildSlide1Surface() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/kitchen_cooking.jpg',
          cacheWidth: 960,
          fit: BoxFit.cover,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.40),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 22,
          child: _buildSurfaceHotspot(
            icon: Icons.outdoor_grill_rounded,
            label: 'Kompor Wajan',
            isSelected: _selectedCookingItem == 'wajan',
            accentColor: Star.star,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedCookingItem = 'wajan');
            },
          ),
        ),
        Positioned(
          left: 130,
          bottom: 12,
          child: _buildSurfaceHotspot(
            icon: Icons.tune_rounded,
            label: 'Daya Suhu',
            isSelected: _selectedCookingItem == 'kompor',
            accentColor: Star.star,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedCookingItem = 'kompor');
            },
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: _buildSurfaceHotspot(
            icon: Icons.soup_kitchen_rounded,
            label: 'Panci Listrik',
            isSelected: _selectedCookingItem == 'panci',
            accentColor: Star.star,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedCookingItem = 'panci');
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 2 SURFACE: MEJA PERSIAPAN & NASI (HOTSPOT LANGSUNG PADA FOTO)
  // --------------------------------------------------------------------------
  Widget _buildSlide2Surface() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/kitchen_prep.jpg',
          cacheWidth: 960,
          fit: BoxFit.cover,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.40),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: _buildSurfaceHotspot(
            icon: Icons.rice_bowl_rounded,
            label: 'Magic Com',
            isSelected: _selectedPrepItem == 'magic_com',
            accentColor: Star.star,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedPrepItem = 'magic_com');
            },
          ),
        ),
        Positioned(
          left: 130,
          bottom: 22,
          child: _buildSurfaceHotspot(
            icon: Icons.content_cut_rounded,
            label: 'Telenan Kayu',
            isSelected: _selectedPrepItem == 'telenan',
            accentColor: Star.star,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedPrepItem = 'telenan');
            },
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: _buildSurfaceHotspot(
            icon: Icons.dinner_dining_rounded,
            label: 'Piring Saji',
            isSelected: _selectedPrepItem == 'piring',
            accentColor: Star.star,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedPrepItem = 'piring');
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 3 SURFACE: KULKAS MINI & STOK (HOTSPOT LANGSUNG PADA FOTO)
  // --------------------------------------------------------------------------
  Widget _buildSlide3Surface(AppState st, bool sayuranSudahDimasak) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/kitchen_fruit_basket.jpg',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Image.asset(
            'assets/images/kitchen_fridge.jpg',
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Image.asset(
              'assets/images/kitchen_panoramic_full.jpg',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                color: Star.star,
                child: const Center(
                  child: Icon(
                    Icons.shopping_basket_rounded,
                    size: 48,
                    color: Star.onAccent54,
                  ),
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: _buildSurfaceHotspot(
            icon: Icons.shopping_basket_rounded,
            label: 'Keranjang Sayur & Buah',
            isSelected: _selectedPantryItem == 'kulkas',
            accentColor: Star.star,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedPantryItem = 'kulkas');
            },
          ),
        ),
        Positioned(
          left: 130,
          bottom: 22,
          child: _buildSurfaceHotspot(
            icon: Icons.egg_rounded,
            label: 'Rak Telur',
            isSelected: _selectedPantryItem == 'telur',
            accentColor: Star.star,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedPantryItem = 'telur');
            },
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: _buildSurfaceHotspot(
            icon: Icons.shelves,
            label: 'Rak Bumbu',
            isSelected: _selectedPantryItem == 'bumbu',
            accentColor: Star.success,
            onTap: () {
              iosTapBuzz();
              setState(() => _selectedPantryItem = 'bumbu');
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET HOTSPOT INTERAKTIF LANGSUNG PADA PERMUKAAN MEJA
  // --------------------------------------------------------------------------
  Widget _buildSurfaceHotspot({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor
              : Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Star.surface
                : Star.surface.withValues(alpha: 0.45),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Star.onAccent, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Star.onAccent,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Paper.amberInk,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TOMBOL PINTASAN STASIUN AKTIF (1 BARIS BERSIH)
  // --------------------------------------------------------------------------
  Widget _buildActiveStationPills() {
    if (_activeKitchenSlide == 0) {
      return Row(
        children: [
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.soup_kitchen_rounded,
              label: 'Panci Listrik',
              isSelected: _selectedCookingItem == 'panci',
              accentColor: Star.star,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedCookingItem = 'panci');
              },
            ),
          ),
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.outdoor_grill_rounded,
              label: 'Kompor Wajan',
              isSelected: _selectedCookingItem == 'wajan',
              accentColor: Star.star,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedCookingItem = 'wajan');
              },
            ),
          ),
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.tune_rounded,
              label: 'Daya Suhu',
              isSelected: _selectedCookingItem == 'kompor',
              accentColor: Star.star,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedCookingItem = 'kompor');
              },
            ),
          ),
        ],
      );
    } else if (_activeKitchenSlide == 1) {
      return Row(
        children: [
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.rice_bowl_rounded,
              label: 'Magic Com',
              isSelected: _selectedPrepItem == 'magic_com',
              accentColor: Star.star,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedPrepItem = 'magic_com');
              },
            ),
          ),
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.content_cut_rounded,
              label: 'Telenan Kayu',
              isSelected: _selectedPrepItem == 'telenan',
              accentColor: Star.star,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedPrepItem = 'telenan');
              },
            ),
          ),
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.dinner_dining_rounded,
              label: 'Piring Saji',
              isSelected: _selectedPrepItem == 'piring',
              accentColor: Star.star,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedPrepItem = 'piring');
              },
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.shopping_basket_rounded,
              label: 'Keranjang Sayur & Buah',
              isSelected: _selectedPantryItem == 'kulkas',
              accentColor: Star.star,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedPantryItem = 'kulkas');
              },
            ),
          ),
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.egg_rounded,
              label: 'Rak Telur',
              isSelected: _selectedPantryItem == 'telur',
              accentColor: Star.star,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedPantryItem = 'telur');
              },
            ),
          ),
          Expanded(
            child: _KitchenPillBtn(
              icon: Icons.shelves,
              label: 'Rak Bumbu',
              isSelected: _selectedPantryItem == 'bumbu',
              accentColor: Star.success,
              onTap: () {
                iosTapBuzz();
                setState(() => _selectedPantryItem = 'bumbu');
              },
            ),
          ),
        ],
      );
    }
  }

  // --------------------------------------------------------------------------
  // WORKSPACE ROUTER DOCK
  // --------------------------------------------------------------------------
  Widget _buildActiveStationDock(
    Pola activePola,
    AppState st,
    bool sayuranSudahDimasak,
  ) {
    if (_activeKitchenSlide == 0) {
      return _buildCookingInspectorDock(activePola);
    } else if (_activeKitchenSlide == 1) {
      return _buildPrepInspectorDock();
    } else {
      return _buildPantryInspectorDock(sayuranSudahDimasak, activePola, st);
    }
  }

  // --------------------------------------------------------------------------
  // DOCK AREA KOMPOR & MASAK
  // --------------------------------------------------------------------------
  Widget _buildCookingInspectorDock(Pola activePola) {
    if (_selectedCookingItem == 'panci') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.soup_kitchen_rounded,
                  size: 16,
                  color: Star.star,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Panci Listrik 1.5L — Rebus Kuah & Telur',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
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
                    '1.5 Liter',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const FactList([
              'Rebus sayur berkuah bening, sup labu siam, telur ceplok air.',
              'Tanpa minyak — cukup air mendidih.',
              'Hemat hingga 15 menit dibanding kompor.',
            ], label: 'Cocok untuk'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _startTimer(8, title: 'Panci Listrik — Rebus Kuah & Telur');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Timer panci listrik 8 menit telah aktif di bar atas!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.timer_outlined, size: 16),
                label: const Text(
                  'Mulai Timer Rebus Kilat (8 Menit)',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Star.star,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_selectedCookingItem == 'wajan') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.outdoor_grill_rounded,
                  size: 16,
                  color: Star.star,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Kompor Wajan — Tumis Sehat Rendah Minyak',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
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
                    'Anti-Lengket',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const RecipeSteps(
              'Pakai api sedang dan 1 sdt minyak kelapa atau zaitun — percikan air saja cukup untuk water sauté. Tumis buncis, wortel, dan tahu dengan cepat. Angkat saat masih renyah agar antioksidan terjaga.',
              label: 'Cara pakai',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _startTimer(5, title: 'Kompor Wajan — Tumis Cepat 5 Menit');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Timer wajan tumis 5 menit telah aktif di bar atas!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.timer_outlined, size: 16),
                label: const Text(
                  'Mulai Timer Tumis Cepat (5 Menit)',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Star.star,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 16, color: Star.star),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Pengatur Daya Suhu — Hemat Listrik Kost (200–600W)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
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
                    'Kost Safe',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const FactList([
              '200W — rebus santai, jaga sup tetap hangat.',
              '400W — tumis sayur dengan api sedang.',
              '600W — didihkan air cepat di pagi hari.',
              'Cek batas MCB kamar sebelum memakai daya tertinggi.',
            ], label: 'Mode daya'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      iosTapBuzz();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mode 200W (Api Kecil/Slow Cook) diaktifkan!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Star.star,
                      side: const BorderSide(color: Star.star),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                    child: const Text(
                      '200W (Kecil)',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      iosTapBuzz();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mode 400W (Api Sedang/Tumis) diaktifkan!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Star.star,
                      side: const BorderSide(color: Star.star),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                    child: const Text(
                      '400W (Sedang)',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      iosTapBuzz();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mode 600W (Api Penuh/Boil) diaktifkan!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Star.star,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                    child: const Text(
                      '600W (Penuh)',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
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

  // --------------------------------------------------------------------------
  // DOCK AREA PREP & NASI
  // --------------------------------------------------------------------------
  Widget _buildPrepInspectorDock() {
    if (_selectedPrepItem == 'magic_com') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rice_bowl_rounded, size: 16, color: Star.star),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Magic Com — Lifehack Kukus 2-in-1 Nasi & Lauk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const RecipeSteps(
              'Taruh wadah kukusan plastik di atas beras saat menanak nasi. Masukkan telur utuh dan potongan tempe. Saat tombol jeglek ke Warm, nasi pulen dan lauk matang bersamaan tanpa kompor tambahan.',
              label: 'Cara pakai',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _startTimer(15, title: 'Magic Com — Kukus Nasi & Lauk');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Timer kukus magic com 15 menit telah aktif di bar atas!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.timer_outlined, size: 16),
                label: const Text(
                  'Mulai Timer Kukus Nasi & Lauk (15 Menit)',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Star.star,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_selectedPrepItem == 'telenan') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.content_cut_rounded, size: 16, color: Star.star),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Telenan Kayu & Pisau — Potong Cepat Anti-Licin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            RecipeSteps(
              'Alasi kain lap basah di bawah telenan kayu agar tidak licin di keramik. Potong dadu tempe 2 cm agar matang merata saat dikukus. Iris tipis bawang supaya aromanya keluar saat ditumis.',
              label: 'Cara pakai',
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dinner_dining_rounded, size: 16, color: Star.star),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Piring Saji — Komposisi Nutrisi Seimbang',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            FactList([
              '1 centong nasi pulen — sekitar 150g karbohidrat.',
              '2 butir telur atau ½ papan tempe — protein pembentuk otot.',
              '1 mangkuk kuah sayur bening — mikronutrisi harian.',
            ], label: 'Komposisi piring'),
          ],
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // DOCK AREA KULKAS MINI & STOK
  // --------------------------------------------------------------------------
  Widget _buildPantryInspectorDock(
    bool sayuranSudahDimasak,
    Pola activePola,
    AppState st,
  ) {
    if (_selectedPantryItem == 'kulkas') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.kitchen_rounded, size: 16, color: Star.star),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Isi Kulkas Mini — Stok Sayur Segar 4 Macam',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Star.star.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sayuranSudahDimasak ? 'Dimasak Hari Ini ✓' : 'Stok Dingin',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Daftar 4 Sayuran Segar (Interaktif Checklist)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: Neu.raised(r: 12, d: 3),
              child: Column(
                children: [
                  _vegInventoryTile('Wortel Segar (2 buah)', 'gro_wortel', st),
                  const Divider(height: 6, thickness: 0.5),
                  _vegInventoryTile(
                    'Brokoli Hijau (1 bonggol)',
                    'gro_brokoli',
                    st,
                  ),
                  const Divider(height: 6, thickness: 0.5),
                  _vegInventoryTile(
                    'Labu Siam Bening (1 buah)',
                    'gro_labu',
                    st,
                  ),
                  const Divider(height: 6, thickness: 0.5),
                  _vegInventoryTile('Bayam / Sawi (1 ikat)', 'gro_bayam', st),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      iosTapBuzz();
                      st.toggleBought('gro_sayur');
                      _scrollToGroceries();
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(
                                Icons.shopping_basket_rounded,
                                color: Star.star,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sayuran ditambahkan ke Belanja!',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 1400),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                    label: const Text(
                      'Tambah Sayur ke Belanja',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Star.star.withValues(alpha: 0.15),
                      foregroundColor: Star.star,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: _scrollToGroceries,
                  icon: const Icon(Icons.list_alt_rounded, size: 14),
                  label: const Text(
                    'Buka Belanja',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Star.star,
                    side: const BorderSide(color: Star.star),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_selectedPantryItem == 'telur') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.egg_rounded, size: 16, color: Star.star),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Rak Telur 1 Papan (30 Butir)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const FactList([
              '3 butir per hari — sekitar 18g protein.',
              '1 papan Rp55.000 — cukup untuk 10 hari program.',
              'Simpan di wadah berventilasi, suhu ruang — tahan 2 minggu.',
              'Jangan dicuci sebelum dimasak — lapisan pelindung cangkang tetap utuh.',
            ], label: 'Patokan harian'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  iosTapBuzz();
                  st.toggleBought('gro_telur');
                  _scrollToGroceries();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.egg_rounded, color: Star.star, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '1 Papan Telur (30 Butir) ditambahkan ke Belanja!',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 1400),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                label: const Text(
                  'Tambah 1 Papan Telur ke Daftar Belanja',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Star.star.withValues(alpha: 0.15),
                  foregroundColor: Star.star,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: Neu.well(r: 18),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shelves, size: 16, color: Star.success),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Rak Bumbu Dasar Hemat (Rp0 per Hari)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Star.success,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            FactList([
              'Garam beriodium.',
              'Bawang merah & bawang putih cincang.',
              'Lada bubuk.',
              'Kecap manis secukupnya — gurih tanpa MSG berlebihan.',
            ], label: 'Isi rak'),
          ],
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // WIDGET INVENTARIS SAYURAN KULKAS (1-TAP CHECKBOX)
  // --------------------------------------------------------------------------
  Widget _vegInventoryTile(String name, String key, AppState st) {
    final bool isBought = st.bought[key] ?? false;
    final bool isCooked = isBought;

    return InkWell(
      onTap: () {
        iosTapBuzz();
        st.toggleBought(key);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
        child: Row(
          children: [
            Icon(
              isCooked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isCooked ? Star.star : Star.mut,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isCooked ? Star.mut : Star.ink,
                  decoration: isCooked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isCooked
                    ? Star.star.withValues(alpha: 0.12)
                    : Star.sunken,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCooked ? 'Terpakai ✓' : 'Tersedia',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: isCooked ? Star.star : Star.mut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carouselDot(bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isActive ? 16 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: isActive ? Paper.amberInk : Star.onAccent54,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. TIMELINE JADWAL MAKAN HARI INI (CHECKLIST 1-TAP)
  // --------------------------------------------------------------------------
  Widget _buildTodayMealChecklist({
    required AppState st,
    required int dayNumber,
    required int mealsDone,
    required double mealProgress,
    required int dailyCal,
    required int currCal,
    required int dailyProt,
    required int currProt,
    required bool breakfastDone,
    required bool lunchDone,
    required bool dinnerDone,
    required bool boosterDone,
    required Pola activePola,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Neu.raised(r: 16, d: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.checklist_rounded, size: 18, color: Star.star),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Target Makan Hari Ini',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Star.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$mealsDone / 4 Selesai',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Star.star,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Checklist Waktu Makan
          _mealChecklistTile(
            timeLabel: 'Sarapan (07:00)',
            menuTitle: 'Telur Rebus 2 Butir + Nasi',
            macro: '±650 kkal • 22g Protein',
            isDone: breakfastDone,
            onTap: () {
              iosTapBuzz();
              st.toggleEat('e$dayNumber-1');
              if (!breakfastDone) {
                st.addXp(10);
              } else {
                st.removeXp(10);
              }
            },
          ),
          const SizedBox(height: 6),
          _mealChecklistTile(
            timeLabel: 'Makan Siang (12:30)',
            menuTitle: activePola.t.split('|').last.trim(),
            macro: '±750 kkal • 28g Protein',
            isDone: lunchDone,
            onTap: () {
              iosTapBuzz();
              st.toggleEat('e$dayNumber-2');
              if (!lunchDone) {
                st.addXp(10);
              } else {
                st.removeXp(10);
              }
            },
          ),
          const SizedBox(height: 6),
          _mealChecklistTile(
            timeLabel: 'Booster Sore (16:30)',
            menuTitle: 'Telur 1 + Pisang / Susu (Pasca-Latihan)',
            macro: '±220 kkal • 12g Protein',
            isDone: boosterDone,
            onTap: () {
              iosTapBuzz();
              st.toggleBought('booster_$dayNumber');
              if (!boosterDone) {
                st.addXp(10);
              } else {
                st.removeXp(10);
              }
            },
          ),
          const SizedBox(height: 6),
          _mealChecklistTile(
            timeLabel: 'Makan Malam (19:00)',
            menuTitle: 'Porsi Malam • Lauk Sehat + Sup Hangat',
            macro: '±680 kkal • 24g Protein',
            isDone: dinnerDone,
            onTap: () {
              iosTapBuzz();
              st.toggleEat('e$dayNumber-3');
              if (!dinnerDone) {
                st.addXp(10);
              } else {
                st.removeXp(10);
              }
            },
          ),
          // Custom Meals yang diracik sendiri oleh pengguna
          if (st.customMeals.any(
            (m) => m.dayIndex == _selectedDayIndex || m.dayIndex == -1,
          )) ...[
            const SizedBox(height: 8),
            ...st.customMeals
                .where(
                  (m) => m.dayIndex == _selectedDayIndex || m.dayIndex == -1,
                )
                .map((cm) {
                  final bool isCooked =
                      st.bought['custom_meal_${cm.id}'] ?? false;
                  return _customMealTile(cm, isCooked, st);
                }),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => _showCreateCustomMealModal(context, st),
              icon: const Icon(Icons.soup_kitchen_rounded, size: 16),
              label: const Text(
                '+ Buat Menu Sendiri (Racik Resep)',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Star.star.withValues(alpha: 0.12),
                foregroundColor: Star.star,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealChecklistTile({
    required String timeLabel,
    required String menuTitle,
    required String macro,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDone ? Star.star.withValues(alpha: 0.08) : Star.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? Star.star.withValues(alpha: 0.3) : Star.sunken,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? Star.star : Star.mut,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$timeLabel • $menuTitle',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDone
                          ? Star.ink.withValues(alpha: 0.7)
                          : Star.ink,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    macro,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      color: Star.star,
                      fontWeight: FontWeight.w600,
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

  // --------------------------------------------------------------------------
  // 3. STRIP 7 HARI MINGGUAN (GANTI HARI & MENU)
  // --------------------------------------------------------------------------
  // Strip pengingat latihan: jadwal (hari & jam) diatur sendiri oleh user.
  // Diletakkan di Planning juga supaya bisa diubah saat menyusun menu.
  Widget _buildWorkoutReminderStrip() {
    final st = AppState.I;
    final on = st.workoutReminderOn;
    final sub = on
        ? '${st.workoutReminderDaysLabel} · ${st.workoutReminderTimeLabel}'
        : 'Nonaktif — ketuk untuk mengatur';
    return InkWell(
      onTap: () async {
        await showWorkoutReminderSheet(context);
        if (mounted) setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: Neu.raised(r: 12, d: 3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Star.star.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                on
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                size: 16,
                color: Star.star,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengingat latihan',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Star.ink,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: Star.mut,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Star.faint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _build7DaysSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: Star.star),
              SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Makan & Target Nutrisi Kost',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Star.ink,
                      ),
                    ),
                    Text(
                      'Pilih hari untuk target kalori & panduan masak harian',
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
        const SizedBox(height: 10),
        SizedBox(
          height: 68 + (MediaQuery.textScalerOf(context).scale(1) - 1) * 24,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _weekDays.length,
            itemBuilder: (context, idx) {
              final item = _weekDays[idx];
              final isSelected = idx == _selectedDayIndex;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    iosTapBuzz();
                    setState(() {
                      _selectedDayIndex = idx;
                      _customActivePola = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 76,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Star.star : Star.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Star.star : Star.sunken,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Star.star.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.dayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Star.onAccent : Star.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Star.onAccent.withValues(alpha: 0.14)
                                : Star.sunken,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Pkt ${item.defaultPola}',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Star.onAccent : Star.mut,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 4. DETAIL RESEP HARI INI
  // --------------------------------------------------------------------------
  Widget _quickTimerChip(int minutes, String label, Pola activePola) {
    return InkWell(
      onTap: () {
        iosTapBuzz();
        _startTimer(minutes, title: 'Memasak: ${activePola.t}');
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Timer $minutes menit aktif! Tampil di bagian atas semua tab.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Star.star,
            duration: const Duration(milliseconds: 1400),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Star.star,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Star.onAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeDetailCard(
    Pola activePola,
    ({String dayName, String defaultPola, String highlight}) dayInfo,
    bool isToday,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Neu.raised(r: 16, d: 5),
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
                        color: Star.star.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.soup_kitchen_rounded,
                        color: Star.star,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resep ${dayInfo.dayName} (${activePola.k})',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Star.ink,
                            ),
                          ),
                          Text(
                            'Estimasi Biaya: Rp ${activePola.b ~/ 1000}rb/hari',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              color: Star.mut,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Star.star.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Hari Ini',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Ilustrasi foto menu paket aktif
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Star.sunken,
              child: Image.asset(
                'assets/images/paket_${activePola.k.toLowerCase()}.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: Star.mut,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            activePola.t,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Star.ink,
            ),
          ),
          const SizedBox(height: 6),
          RecipeSteps(activePola.cara),
          const SizedBox(height: 12),
          // Quick Presets Timer Masak Langsung di Tab Menu Hari Ini
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: Neu.well(r: 12),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 15, color: Star.star),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Mulai Timer Masak:',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Star.star,
                    ),
                  ),
                ),
                _quickTimerChip(5, '5m', activePola),
                const SizedBox(width: 4),
                _quickTimerChip(10, '10m', activePola),
                const SizedBox(width: 4),
                _quickTimerChip(15, '15m', activePola),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCookingGuideModal(context, activePola),
                  icon: const Icon(Icons.menu_book_rounded, size: 15),
                  label: const Text(
                    'Panduan Detail & Langkah',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Star.star,
                    side: const BorderSide(color: Star.star),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 5. KATALOG 7 PAKET RESEP HEMAT (A - G)
  // --------------------------------------------------------------------------
  Widget _build7PaketCatalogue(String currentActiveKey) {
    final activePola = _getPolaForDay(_selectedDayIndex);
    final dayInfo = _weekDays[_selectedDayIndex];

    final mealSessions = [
      (
        session: 'Sarapan Pagi (07.00 WIB)',
        title: 'Nasi Hangat + 2 Butir Telur Rebus + Tempe Kukus',
        macro: '450 kkal • 22g Protein',
        cost: 'Rp 4.000',
        timerMinutes: 10,
        timerTitle: 'Sarapan: Telur & Tempe Kukus',
        icon: Icons.wb_twilight_rounded,
        iconColor: Star.star,
        bahan: '2 butir telur ayam, 1 papan kecil tempe (potong dadu), 1 centong beras pulen.',
        langkah: 'Trik Magic Com 2-in-1: Cuci beras dan beri air di panci magic com. Taruh wadah kukusan di atas beras, letakkan telur dan tempe. Nasi matang dan lauk siap santap bersamaan dalam 10 menit tanpa kompor tambahan.',
      ),
      (
        session: 'Makan Siang (12.30 WIB)',
        title: '${activePola.t.split('|').last.trim()} + Sayur Bening Segar',
        macro: '680 kkal • 26g Protein',
        cost: 'Rp 7.000',
        timerMinutes: 12,
        timerTitle: 'Makan Siang: ${activePola.k}',
        icon: Icons.wb_sunny_rounded,
        iconColor: Star.star,
        bahan:
            'Sayuran keranjang kost (labu siam/wortel/bayam), lauk harian ${activePola.k}, bawang merah & garam.',
        langkah: activePola.cara.isNotEmpty ? activePola.cara : 'Didihkan 400ml air di panci listrik, masukkan irisan bumbu dasar dan garam. Masukkan sayuran segar selama 5-7 menit agar vitamin terjaga dan sayur tetap renyah.',
      ),
      (
        session: 'Booster Sore (16.30 WIB)',
        title: 'Susu Dancow Cokelat Hangat + 1 Telur Rebus / Pisang',
        macro: '340 kkal • 16g Protein',
        cost: 'Rp 4.500',
        timerMinutes: 5,
        timerTitle: 'Booster Sore: Susu & Nutrisi Otot',
        icon: Icons.bolt_rounded,
        iconColor: Star.star,
        bahan: '1 sachet susu Dancow bubuk, 1 butir telur ayam rebus / pisang ambon.',
        langkah: 'Seduh susu bubuk dengan air panas hangat. Konsumsi 30-45 menit sebelum atau sesudah kalistenik untuk memicu pemulihan glikogen dan mempercepat pembentukan massa otot bebas lemak.',
      ),
      (
        session: 'Makan Malam (19.00 WIB)',
        title: 'Nasi Porsi Sedang + Kuah Kaldu Bening & Lauk Sehat',
        macro: '620 kkal • 24g Protein',
        cost: 'Rp 5.500',
        timerMinutes: 10,
        timerTitle: 'Makan Malam: Kuah Hangat & Lauk',
        icon: Icons.nights_stay_rounded,
        iconColor: Star.star,
        bahan: 'Nasi hangat, kuah sup bening sisa siang/baru, tahu/telur rebus pelengkap.',
        langkah: 'Panaskan kuah sup di panci listrik selama 5 menit. Santap selagi hangat untuk memberikan rasa kenyang yang nyaman dan tidur nyenyak tanpa begah.',
      ),
    ];

    final paketKeys = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Star.star.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: Star.star,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal Pilihan Menu Harian Kost',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Star.ink,
                    ),
                  ),
                  Text(
                    'Porsi makan terencana 4 sesi hari ${dayInfo.dayName} dengan langkah masak & timer instan',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      color: Star.mut,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Meal Session Cards
        ...mealSessions.map((session) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: Neu.raised(r: 18, d: 5),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(session.icon, size: 16, color: session.iconColor),
                        const SizedBox(width: 6),
                        Text(
                          session.session,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: session.iconColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Star.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Star.lineSoft),
                      ),
                      child: Text(
                        session.cost,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Star.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Meal Title
                Text(
                  session.title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Star.ink,
                  ),
                ),
                const SizedBox(height: 2),

                // Macro
                Text(
                  session.macro,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Star.star,
                  ),
                ),
                const SizedBox(height: 8),

                // Langkah masak sebagai daftar bernomor, bukan paragraf.
                RecipeSteps(session.langkah),
                const SizedBox(height: 10),

                // Action Button: Pasang Timer Masak
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      _startTimer(
                        session.timerMinutes,
                        title: session.timerTitle,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Timer ${session.timerMinutes} menit untuk ${session.session} telah aktif di atas!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer_outlined, size: 15),
                    label: Text(
                      'Pasang Timer Masak (${session.timerMinutes} Mnt)',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Star.star,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),

        // Quick Catalog Bar: Ganti Pola Paket Resep A - G
        Container(
          padding: const EdgeInsets.all(14),
          decoration: Neu.raised(r: 18, d: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16, color: Star.star),
                  SizedBox(width: 6),
                  Text(
                    'Ganti Paket Menu Hari Ini (A – G)',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Star.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih variasi paket makanan murah untuk mengganti lauk utama siang & malam:',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11.5,
                  color: Star.mut,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: paketKeys.map((k) {
                    final p = POLA[k]!;
                    final isSel = currentActiveKey == k;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          iosTapBuzz();
                          setState(() => _customActivePola = k);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 170,
                          padding: const EdgeInsets.all(10),
                          decoration: isSel
                              ? BoxDecoration(
                                  color: Star.star,
                                  borderRadius: BorderRadius.circular(14),
                                )
                              : Neu.raised(r: 14, d: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 76,
                                  width: double.infinity,
                                  color: isSel
                                      ? Colors.white.withValues(alpha: 0.16)
                                      : Star.sunken,
                                  child: Image.asset(
                                    'assets/images/paket_${k.toLowerCase()}.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Center(
                                      child: Icon(
                                        Icons.restaurant_rounded,
                                        color: isSel
                                            ? Star.onAccent
                                            : Star.mut,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Paket $k (Rp ${p.b ~/ 1000}rb)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Star.onAccent : Star.star,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.t.split('|').last.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  color: isSel ? Star.onAccent70 : Star.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroceryChecklistSection(AppState st) {
    final groceryItems = [
      (
        key: 'gro_telur',
        name: 'Telur Ayam 1 Papan (30 Butir)',
        note: '±Rp55.000 • Protein Utama',
      ),
      (
        key: 'gro_tempe',
        name: 'Tempe 2 Papan Sedang',
        note: '±Rp10.000 • Protein Nabati',
      ),
      (
        key: 'gro_tahu',
        name: 'Tahu Putih 1 Bungkus',
        note: '±Rp6.000 • Serat & Kalsium',
      ),
      (
        key: 'gro_wortel',
        name: 'Wortel Segar 2 Buah',
        note: '±Rp4.000 • Vitamin A & Mikronutrisi',
      ),
      (
        key: 'gro_sayur',
        name: 'Sayur Sop / Bayam / Labu Siam',
        note: '±Rp10.000 • Sayur Segar Pasar',
      ),
      (
        key: 'gro_beras',
        name: 'Beras Pulen 2.5 kg',
        note: '±Rp36.000 • Karbohidrat 2 Minggu',
      ),
      (
        key: 'gro_bumbu',
        name: 'Bumbu Dapur (Bawang Merah/Putih & Garam)',
        note: '±Rp10.000 • Stok Bumbu Dasar',
      ),
    ];

    final int boughtCount = groceryItems
        .where((i) => st.bought[i.key] ?? false)
        .length;

    return Container(
      key: _grocerySectionKey,
      padding: const EdgeInsets.all(16),
      decoration: Neu.raised(r: 16, d: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Star.star,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Belanja Pasar Mingguan',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Star.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Star.star.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$boughtCount / ${groceryItems.length} Terbeli',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Star.star,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Centang barang yang sudah Anda beli di pasar. Seluruh data belanjaan otomatis tersimpan di memori aplikasi.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11.5,
              color: Star.mut,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          ...groceryItems.map((item) {
            final isChecked = st.bought[item.key] ?? false;
            return InkWell(
              onTap: () {
                iosTapBuzz();
                st.toggleBought(item.key);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                child: Row(
                  children: [
                    Icon(
                      isChecked
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: isChecked ? Star.star : Star.mut,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isChecked ? Star.mut : Star.ink,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            item.note,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 9.5,
                              color: Star.star,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET KARTU MENU KUSTOM (BUAT MENU SENDIRI)
  // --------------------------------------------------------------------------
  Widget _customMealTile(CustomMeal cm, bool isDone, AppState st) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDone ? Star.star.withValues(alpha: 0.08) : Star.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? Star.star.withValues(alpha: 0.3)
              : Star.star.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              iosTapBuzz();
              st.toggleBought('custom_meal_${cm.id}');
              if (!isDone) {
                st.addXp(15);
                triumphBuzz();
              } else {
                st.removeXp(15);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? Star.star : Star.star,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: Star.star.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '★ ${cm.mealTime}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Star.star,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cm.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDone ? Star.mut : Star.ink,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '• ${cm.kalori} kkal • ${cm.protein}g Protein • ${cm.karbo}g Karbo${cm.bahan.isNotEmpty ? ' • ${cm.bahan.length} Bahan' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Star.star,
                  ),
                ),
                if (cm.langkah.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cm.langkah,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10.5,
                      color: Star.mut,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Star.error,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Hapus Menu',
            onPressed: () {
              iosTapBuzz();
              st.deleteCustomMeal(cm.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _segmentedTabBtn({
    required int index,
    required IconData icon,
    required String label,
    required String badge,
    required bool isActive,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: () {
        iosTapBuzz();
        setState(() => _activePlanningTab = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? Star.onAccent : Star.mut),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? Star.onAccent : Star.ink,
              ),
            ),
            Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Star.onAccent.withValues(alpha: 0.85)
                    : Star.mut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MODAL BOTTOM SHEET: BUAT MENU SENDIRI (RACIK RESEP EFEKTIF)
  // --------------------------------------------------------------------------
  void _showCreateCustomMealModal(BuildContext context, AppState st) {
    iosTapBuzz();
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController(text: '${st.mealTargetCalories}');
    final proCtrl = TextEditingController(text: '${st.mealTargetProtein}');
    final carbCtrl = TextEditingController(text: '${st.mealTargetCarbs}');
    final bahanCtrl = TextEditingController();
    final langkahCtrl = TextEditingController();
    String selectedMealTime = 'Makan Siang';
    int targetDay = _selectedDayIndex;
    bool autoAddToGroceries = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void applyPreset(
              String name,
              String cals,
              String pros,
              String carbs,
              String bahans,
              String steps,
            ) {
              iosTapBuzz();
              setModalState(() {
                nameCtrl.text = name;
                calCtrl.text = cals;
                proCtrl.text = pros;
                carbCtrl.text = carbs;
                bahanCtrl.text = bahans;
                langkahCtrl.text = steps;
              });
            }

            final int proVal = int.tryParse(proCtrl.text.trim()) ?? 0;
            final int calVal = int.tryParse(calCtrl.text.trim()) ?? 0;
            final int carbVal = int.tryParse(carbCtrl.text.trim()) ?? 0;
            final int targetPro = st.mealTargetProtein;
            final int targetCal = st.mealTargetCalories;
            final int targetCarb = st.mealTargetCarbs;
            final int proPct = targetPro > 0
                ? ((proVal / targetPro) * 100).round()
                : 0;
            final int calPct = targetCal > 0
                ? ((calVal / targetCal) * 100).round()
                : 0;
            final int carbPct = targetCarb > 0
                ? ((carbVal / targetCarb) * 100).round()
                : 0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Star.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            color: Star.star,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Buat Menu Sendiri (Racik Resep Kost)',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Star.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Rancang menu favorit Anda dengan kalkulasi nutrisi presisi. Sesuaikan asupan agar tidak kurang dan pas dengan target profil!',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: Star.mut,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ACUAN 1X MAKAN DARI PROFIL (CARD TERPUSAT)
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: Neu.well(r: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.track_changes_rounded,
                                  size: 15,
                                  color: Star.star,
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Acuan 1x Porsi Makan Anda (Dari Profil):',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Star.star,
                                    ),
                                  ),
                                ),
                                Text(
                                  st.fitnessGoal == 'muscle_gain'
                                      ? 'Bulking'
                                      : (st.fitnessGoal == 'fat_loss'
                                            ? 'Cutting'
                                            : 'Fit'),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Star.star,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  '$targetPro g Protein',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Star.ink,
                                  ),
                                ),
                                Text(
                                  '$targetCal kkal',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Star.ink,
                                  ),
                                ),
                                Text(
                                  '$targetCarb g Karbo',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Star.ink,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Preset Cepat 1-Tap
                      const Text(
                        'Template Resep Cepat Kost:',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Star.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              label: const Text(
                                'Omelet Bayam Tahu',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              backgroundColor: Star.star.withValues(alpha: 0.1),
                              onPressed: () => applyPreset(
                                'Omelet Bayam Tahu',
                                '380',
                                '22',
                                '15',
                                '2 Telur Ayam, 1 Ikat Bayam, 1 Kotak Tahu',
                                'Kocok telur bersama cincangan bayam & tahu hancur. Masak di wajan anti lengket.',
                              ),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text(
                                'Tumis Kangkung Tempe',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              backgroundColor: Star.star.withValues(alpha: 0.1),
                              onPressed: () => applyPreset(
                                'Tumis Kangkung Tempe',
                                '420',
                                '20',
                                '48',
                                '1 Ikat Kangkung, 1 Papan Tempe, Bawang Putih, Cabe',
                                'Potong tempe dadu, tumis bumbu di panci listrik lalu masukkan kangkung.',
                              ),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text(
                                'Sop Ayam Sayur Magic Com',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              backgroundColor: Star.star.withValues(alpha: 0.1),
                              onPressed: () => applyPreset(
                                'Sop Ayam Sayur Magic Com',
                                '490',
                                '35',
                                '42',
                                '150g Dada Ayam, 1 Wortel, Kol, Bawang Daun',
                                'Rebus dada ayam & sayuran langsung di panci magic com mode cook 20 menit.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Input Nama Menu
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Menu Makanan',
                          labelStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                          ),
                          hintText: 'Contoh: Telur Dadar Jamur Tiram',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Waktu Makan ChoiceChips
                      const Text(
                        'Pilih Sesi Makan:',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Star.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children:
                            [
                              'Sarapan',
                              'Makan Siang',
                              'Makan Malam',
                              'Snack Booster',
                            ].map((time) {
                              final isSel = selectedMealTime == time;
                              return ChoiceChip(
                                label: Text(
                                  time,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 10,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: Star.star,
                                labelStyle: TextStyle(
                                  color: isSel ? Star.onAccent : Star.ink,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(
                                      () => selectedMealTime = time,
                                    );
                                  }
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // 3 Kolom Input Asupan: Kalori, Protein, Karbohidrat (LIVE UPDATE)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: calCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setModalState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Kalori (kkal)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: proCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setModalState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Protein (gram)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: carbCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setModalState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Karbo (gram)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ============================================================
                      // DYNAMIC LIVE NOTICE EVALUATOR (SESUAI PERMINTAAN USER!)
                      // ============================================================
                      if (proVal <= 0)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: MarginNote(
                            'Isi jumlah protein, kalori, dan karbohidrat di atas '
                            'untuk melihat perbandingan dengan target gizi '
                            'porsi makanmu.',
                            label: 'Catatan',
                          ),
                        )
                      else if (proVal < (targetPro * 0.75))
                        // NOTICE: PROTEIN TERNYATA KURANG!
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: Neu.well(r: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Star.star,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 12,
                                          color: Star.onAccent,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'PERLU TAMBAHAN PROTEIN',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Star.onAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$proPct% dari target porsi',
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Star.star,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Kurang ${targetPro - proVal}g protein dari target porsi.',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Paper.amberInk,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Menu ini menyumbang ${proVal}g dari ${targetPro}g acuan sekali makan.',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Paper.amberInk,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Saran: 2 telur rebus (+12g) · tempe (+8g) · dada ayam (+20g).',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Paper.amberInk,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (proVal <= (targetPro * 1.25))
                        // NOTICE: UDAH CUKUP, AKU TAHU!
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: Neu.well(r: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Star.success,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 12,
                                          color: Star.onAccent,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'PROTEIN PAS & OPTIMAL',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Star.onAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$proPct% dari target porsi',
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Star.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Protein sudah memenuhi target porsi.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Paper.mintDeep,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${proVal}g dari ${targetPro}g acuan — cukup untuk mendukung pembentukan otot.',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Paper.mintDeep,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // NOTICE: SUPER HIGH PROTEIN!
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: Neu.well(r: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Star.star,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.bolt_rounded,
                                          size: 12,
                                          color: Star.onAccent,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'SUPER HIGH PROTEIN',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Star.onAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$proPct% dari target',
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Star.star,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Protein sangat tinggi: ${proVal}g per porsi.',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Star.star,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$proPct% dari acuan sekali makan. Cocok setelah latihan intensif untuk pemulihan otot.',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Star.star,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Bar Ringkasan 3 Metrik Makro (Mini Status)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: Neu.raised(r: 10, d: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'Kal: $calVal/$targetCal kkal ($calPct%)',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Star.ink,
                              ),
                            ),
                            Container(width: 1, height: 12, color: Star.sunken),
                            Text(
                              'Pro: $proVal/$targetPro g ($proPct%)',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Star.star,
                              ),
                            ),
                            Container(width: 1, height: 12, color: Star.sunken),
                            Text(
                              'Karbo: $carbVal/$targetCarb g ($carbPct%)',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Star.star,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Bahan Belanja (Koma dipisah)
                      TextField(
                        controller: bahanCtrl,
                        decoration: InputDecoration(
                          labelText: 'Bahan-Bahan (Pisahkan dengan koma)',
                          hintText: 'Misal: 2 Telur, 1 Ikat Kangkung, Tempe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Langkah / Cara Masak
                      TextField(
                        controller: langkahCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Cara Masak / Catatan Ringkas',
                          hintText: 'Misal: Tumis di wajan 5 menit dengan 1 sdt minyak',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Switch Otomatis Masukkan ke Belanja
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Otomatis masukkan bahan ke Daftar Belanja',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Star.ink,
                          ),
                        ),
                        value: autoAddToGroceries,
                        activeTrackColor: Star.star,
                        onChanged: (val) =>
                            setModalState(() => autoAddToGroceries = val),
                      ),
                      const SizedBox(height: 12),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Masukkan nama menu terlebih dahulu!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            iosTapBuzz();
                            final cals =
                                (int.tryParse(calCtrl.text) ?? targetCal).clamp(
                                  10,
                                  5000,
                                );
                            final pros =
                                (int.tryParse(proCtrl.text) ?? targetPro).clamp(
                                  0,
                                  300,
                                );
                            final carbs =
                                (int.tryParse(carbCtrl.text) ?? targetCarb)
                                    .clamp(0, 500);
                            final cleanName = name.length > 50
                                ? name.substring(0, 50)
                                : name;
                            final bahanList = bahanCtrl.text
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .map(
                                  (s) => s.length > 40 ? s.substring(0, 40) : s,
                                )
                                .toList();
                            final cleanLangkah = langkahCtrl.text.trim();

                            final newMeal = CustomMeal(
                              id: 'cm_${DateTime.now().millisecondsSinceEpoch}',
                              name: cleanName,
                              mealTime: selectedMealTime,
                              dayIndex: targetDay,
                              kalori: cals,
                              protein: pros,
                              karbo: carbs,
                              bahan: bahanList,
                              langkah: cleanLangkah.length > 250
                                  ? cleanLangkah.substring(0, 250)
                                  : cleanLangkah,
                            );

                            st.addCustomMeal(newMeal);

                            if (autoAddToGroceries && bahanList.isNotEmpty) {
                              for (final b in bahanList) {
                                final k =
                                    'gro_custom_${b.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
                                st.toggleBought(k);
                              }
                            }

                            Navigator.pop(ctx);
                            triumphBuzz();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Menu "$cleanName" berhasil disimpan! ($pros g Protein, $cals kkal, $carbs g Karbo)',
                                ),
                                backgroundColor: Star.star,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Simpan Menu ke Jadwal',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Star.star,
                            foregroundColor: Star.onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _KitchenPillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _KitchenPillBtn({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Star.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Star.sunken,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Star.onAccent : accentColor,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Star.onAccent : Star.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
