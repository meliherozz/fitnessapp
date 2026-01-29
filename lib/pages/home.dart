import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitnessapp/services/support_widget.dart';
import 'package:flutter/material.dart';
import 'package:fitnessapp/pages/workout_variants_page.dart';
import 'package:fitnessapp/pages/daily_goal_setup.dart';
import 'package:fitnessapp/pages/daily_goal_run.dart';
import 'package:fitnessapp/pages/badges_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

enum ProgressMode { daily, weekly }

class HomeState extends State<Home> {
  User? _user;

  late final ScrollController _discoverScrollController;

  ProgressMode _progressMode = ProgressMode.daily;

  // Günlük hedef özet verisi
  bool _isDailyGoalLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _dailyGoalData;
  late final String _todayId;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _discoverScrollController = ScrollController();

    final now = DateTime.now();
    _todayId = "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    _loadUserAndDailyGoal();
  }

  @override
  void dispose() {
    _discoverScrollController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _workoutStream() {
    if (_user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('workouts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }


  

  // --------- Kullanıcı + Günlük hedef verilerini yükleme ---------

  Future<void> _loadUserAndDailyGoal() async {
    if (_user == null) {
      setState(() {
        _isDailyGoalLoading = false;
      });
      return;
    }

    setState(() {
      _isDailyGoalLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      _userData = userDoc.data();

      final dailyGoalRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('daily_goals')
          .doc(_todayId);

      final dailyDoc = await dailyGoalRef.get();

      if (dailyDoc.exists) {
        _dailyGoalData = dailyDoc.data();
      } else {
        _dailyGoalData = {
          'date': Timestamp.now(),
          'targetMinutes': 0,
          'completedMinutes': 0,
          'exercises': <Map<String, dynamic>>[],
        };
        await dailyGoalRef.set(_dailyGoalData!);
      }
    } catch (e) {
      debugPrint('LOAD USER/DAILY GOAL ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Günlük hedef verileri yüklenirken hata: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDailyGoalLoading = false;
        });
      }
    }
  }

  // BMI hesaplama
  double? _calculateBmi(num? heightCm, num? weightKg) {
    if (heightCm == null ||
        heightCm <= 0 ||
        weightKg == null ||
        weightKg <= 0) {
      return null;
    }
    final double hMeter = heightCm.toDouble() / 100.0;
    return weightKg.toDouble() / (hMeter * hMeter);
  }

  // BMI'ye göre önerilen günlük süre
  double _calculateRecommendedMinutes(num? heightCm, num? weightKg) {
    final bmi = _calculateBmi(heightCm, weightKg);
    if (bmi == null) {
      return 30;
    }

    if (bmi < 18.5) {
      return 20;
    } else if (bmi < 25) {
      return 30;
    } else if (bmi < 30) {
      return 40;
    } else if (bmi < 35) {
      return 45;
    } else {
      return 50;
    }
  }

  // --------- Günlük hedef kartı (Sadece ÖZET) ---------

  Widget _buildDailyGoalCard() {
    if (_isDailyGoalLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_userData == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Günlük hedef için önce profilinden boy ve kilo bilgilerini girebilirsin.",
            style: AppWidget.mediumTextStyle(16),
          ),
        ),
      );
    }

    final num? heightCm = _userData?['height_cm'];
    final num? weightKg = _userData?['weight_kg'];
    final bmi = _calculateBmi(heightCm, weightKg);
    final recommended = _calculateRecommendedMinutes(heightCm, weightKg);

    final int targetMinutes =
        (_dailyGoalData?['targetMinutes'] as num?)?.toInt() ?? 0;
    final int completedMinutes =
        (_dailyGoalData?['completedMinutes'] as num?)?.toInt() ?? 0;

    final List<dynamic> exercisesDynamic =
        _dailyGoalData?['exercises'] as List<dynamic>? ?? [];
    final int exerciseCount = exercisesDynamic.length;
    final int doneCount = exercisesDynamic
        .where((e) => (e as Map<String, dynamic>)['isDone'] == true)
        .length;

    final double progress =
        targetMinutes > 0 ? (completedMinutes / targetMinutes) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık + butonlar
            Row(
              children: [
                Text(
                  "Günlük Hedefim",
                  style: AppWidget.healineTextStyle(18),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DailyGoalSetupPage(),
                      ),
                    );
                    if (changed == true) {
                      _loadUserAndDailyGoal();
                    }
                  },
                  icon: const Icon(Icons.playlist_add_outlined),
                  label: const Text("Antrenmanları seç"),
                ),
              ],
            ),

            if (exerciseCount > 0)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DailyGoalRunPage(),
                      ),
                    ).then((_) {
                      _loadUserAndDailyGoal();
                    });
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text("Antrenmanı başlat"),
                ),
              ),

            const SizedBox(height: 8),
            Text(
              "Önerilen hedef (BMI'ye göre): ${recommended.toInt()} dk",
              style: AppWidget.mediumTextStyle(16),
            ),
            const SizedBox(height: 4),
            Text(
              targetMinutes > 0
                  ? "Bugünkü hedef: $targetMinutes dk"
                  : "Bugün için henüz hedef süre seçmedin.",
              style: AppWidget.mediumTextStyle(16),
            ),
            const SizedBox(height: 4),
            Text(
              "Tamamlanan süre: $completedMinutes dk",
              style: AppWidget.mediumTextStyle(16),
            ),
            const SizedBox(height: 4),
            Text(
              "Tamamlanan hareket: $doneCount / $exerciseCount",
              style: AppWidget.mediumTextStyle(14),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 4),
            Text(
              "%${(progress * 100).clamp(0, 999).toStringAsFixed(0)} hedefe ilerleme",
              style: AppWidget.mediumTextStyle(14),
            ),
            if (bmi != null) ...[
              const SizedBox(height: 8),
              Text(
                "BMI: ${bmi.toStringAsFixed(1)}",
                style: AppWidget.mediumTextStyle(14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ----------------- BUILD -----------------

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Giriş yapmış kullanıcı bulunamadı."),
        ),
      );
    }

    final String userName = _user?.displayName ?? "Kullanıcı";
    final stream = _workoutStream();

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 45.0, left: 20.0, right: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ÜST SELAMLAMA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Merhaba, $userName",
                          style: AppWidget.healineTextStyle(23.0)),
                      Text(
                        "Aktiviteni kontrol edelim",
                        style: AppWidget.healineTextStyle(18.0),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      "images/girl.jpg",
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),
              const SizedBox(height: 20.0),

              // ROZETLERİM BUTONU
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
  child: SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BadgesPage(),
          ),
        );
      },
      icon: const Icon(Icons.emoji_events),
      label: const Text(
        'Rozetlerim',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
),
const SizedBox(height: 20.0),

              // İSTATİSTİKLER + GRAFİKLER
              if (stream == null)
                const Center(child: Text("Lütfen giriş yapın."))
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    int finished = 0;
                    int todayCount = 0;
                    int totalMinutes = 0;

                    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

                    if (snapshot.hasData) {
                      docs = snapshot.data!.docs;
                      finished = docs.length;

                      final now = DateTime.now();

                      for (var doc in docs) {
                        final data = doc.data();

                        final duration = data['duration'];
                        if (duration is int) {
                          totalMinutes += duration;
                        } else if (duration is String) {
                          totalMinutes += int.tryParse(duration) ?? 0;
                        }

                        dynamic ts = data['completedAt'] ?? data['createdAt'];
                        if (ts is Timestamp) {
                          final dt = ts.toDate();
                          if (dt.year == now.year &&
                              dt.month == now.month &&
                              dt.day == now.day) {
                            todayCount++;
                          }
                        }
                      }
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final dailyStats = _computeDailyStats(docs);
                    final weeklyStats = _computeWeeklyStats(docs);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ÜST ÖZET KARTLAR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Material(
                              elevation: 6.0,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                width: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      " 💪 Tamamlanan",
                                      style: AppWidget
                                          .healineTextStyle(18.0),
                                    ),
                                    const SizedBox(height: 20.0),
                                    Text(
                                      "$finished",
                                      style: AppWidget
                                          .healineTextStyle(40.0),
                                    ),
                                    const SizedBox(height: 8.0),
                                    const Text(
                                      "Tamamlanan\nAntrenmanlar",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color.fromARGB(
                                            147, 0, 0, 0),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20.0),
                            Column(
                              children: [
                                Material(
                                  elevation: 6.0,
                                  borderRadius:
                                      BorderRadius.circular(20.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(20.0),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          " 🔄 Bugün",
                                          style: AppWidget
                                              .healineTextStyle(18.0),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "$todayCount",
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 10.0),
                                            const Text(
                                              "Antrenman",
                                              textAlign:
                                                  TextAlign.center,
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    147, 0, 0, 0),
                                                fontSize: 15.0,
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Material(
                                  elevation: 6.0,
                                  borderRadius:
                                      BorderRadius.circular(20.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(20.0),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          " ⏱️ Harcanan süre",
                                          style: AppWidget
                                              .healineTextStyle(18.0),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "$totalMinutes",
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 10.0),
                                            const Text(
                                              "Dakika (toplam)",
                                              textAlign:
                                                  TextAlign.center,
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    147, 0, 0, 0),
                                                fontSize: 15.0,
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 30.0),

                        // İLERLEME GRAFİĞİ
                        Text(
                          "İlerleme",
                          style: AppWidget.healineTextStyle(20.0),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text("Günlük"),
                              selected:
                                  _progressMode == ProgressMode.daily,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _progressMode =
                                        ProgressMode.daily;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text("Haftalık"),
                              selected:
                                  _progressMode == ProgressMode.weekly,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _progressMode =
                                        ProgressMode.weekly;
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (_progressMode == ProgressMode.daily)
                          _buildDailyChart(dailyStats)
                        else
                          _buildWeeklyChart(weeklyStats),

                        const SizedBox(height: 20),

                        // 🌟 Günlük hedef özet kartı
                        _buildDailyGoalCard(),

                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 30.0),

              // DISCOVER NEW WORKOUTS
              Text(
                "Yeni antrenmanlar keşfet",
                style: AppWidget.healineTextStyle(20.0),
              ),
              const SizedBox(height: 20.0),

              SizedBox(
                height: 200,
                child: Scrollbar(
                  controller: _discoverScrollController,
                  thumbVisibility: true,
                  child: ListView(
                    controller: _discoverScrollController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      // CARDIO
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutVariantsPage(
                                baseTitle: "Kardiyo",
                                categoryKey: "cardio",
                                imagePath: "images/fit1.png",
                              ),
                            ),
                          );
                        },
                        child: _discoverCard(
                          title: "Kardiyo",
                          subtitle1: "10 Egzersiz",
                          subtitle2: "3-10 Dakika",
                          color: const Color(0xfffcb74f),
                          imagePath: "images/fit1.png",
                        ),
                      ),
                      // ARM
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutVariantsPage(
                                baseTitle: "Kol",
                                categoryKey: "arm",
                                imagePath: "images/fit2.png",
                              ),
                            ),
                          );
                        },
                        child: _discoverCard(
                          title: "Kol",
                          subtitle1: "5 Egzersiz",
                          subtitle2: "3-7 Dakika",
                          color: const Color(0xff57949e),
                          imagePath: "images/fit2.png",
                        ),
                      ),
                      // STRETCHING
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutVariantsPage(
                                baseTitle: "Esneme",
                                categoryKey: "stretching",
                                imagePath: "images/fit3.png",
                              ),
                            ),
                          );
                        },
                        child: _discoverCard(
                          title: "Esneme",
                          subtitle1: "5 Egzersiz",
                          subtitle2: "3-7 Dakika",
                          color: const Color(0xfffcb74f),
                          imagePath: "images/fit3.png",
                        ),
                      ),
                      // CHEST
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutVariantsPage(
                                baseTitle: "Göğüs",
                                categoryKey: "chest",
                                imagePath: "images/gogus.png",
                              ),
                            ),
                          );
                        },
                        child: _discoverCard(
                          title: "Göğüs",
                          subtitle1: "4 Egzersiz",
                          subtitle2: "4-6 Dakika",
                          color: const Color(0xffe57373),
                          imagePath: "images/gogus.png",
                        ),
                      ),
                      // LEGS
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutVariantsPage(
                                baseTitle: "Bacak",
                                categoryKey: "legs",
                                imagePath: "images/leg.png",
                              ),
                            ),
                          );
                        },
                        child: _discoverCard(
                          title: "Bacak",
                          subtitle1: "4 Egzersiz",
                          subtitle2: "4-6 Dakika",
                          color: const Color(0xff81c784),
                          imagePath: "images/leg.png",
                        ),
                      ),
                      // BACK
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutVariantsPage(
                                baseTitle: "Sırt",
                                categoryKey: "back",
                                imagePath: "images/back.png",
                              ),
                            ),
                          );
                        },
                        child: _discoverCard(
                          title: "Sırt",
                          subtitle1: "4 Egzersiz",
                          subtitle2: "3-5 Dakika",
                          color: const Color(0xff64b5f6),
                          imagePath: "images/back.png",
                        ),
                      ),
                      // SHOULDERS
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutVariantsPage(
                                baseTitle: "Omuz",
                                categoryKey: "shoulders",
                                imagePath: "images/omuz.png",
                              ),
                            ),
                          );
                        },
                        child: _discoverCard(
                          title: "Omuz",
                          subtitle1: "4 Egzersiz",
                          subtitle2: "3-5 Dakika",
                          color: const Color(0xffba68c8),
                          imagePath: "images/omuz.png",
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20.0),

              // Öne çıkan antrenmanlar
              Text("Öne çıkan antrenmanlar",
                  style: AppWidget.healineTextStyle(20.0)),
              const SizedBox(height: 20.0),

              _topWorkoutCard(
                context,
                title: "Squat",
                sets: "2 set",
                reps: "10 Tekrar",
                time: "10:00",
                image: "images/squat.png",
              ),
              const SizedBox(height: 20.0),
              _topWorkoutCard(
                context,
                title: "Şınav",
                sets: "3 set",
                reps: "20 Tekrar",
                time: "20:00",
                image: "images/pushup.png",
              ),
              const SizedBox(height: 20.0),
              _topWorkoutCard(
                context,
                title: "Biceps Curl",
                sets: "1 set",
                reps: "10 Tekrar",
                time: "05:00",
                image: "images/curls.png",
              ),

              const SizedBox(height: 50.0),
            ],
          ),
        ),
      ),
    );
  }

  // --------- PROGRESS HESAPLAMA ---------

  List<_DayStat> _computeDailyStats(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final List<_DayStat> result = [];
    final Map<String, int> minutesByDay = {};

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final key = "${day.year}-${day.month}-${day.day}";
      minutesByDay[key] = 0;
    }

    for (var doc in docs) {
      final data = doc.data();
      dynamic ts = data['completedAt'] ?? data['createdAt'];
      if (ts is! Timestamp) continue;

      final dt = ts.toDate();
      final day = DateTime(dt.year, dt.month, dt.day);
      final key = "${day.year}-${day.month}-${day.day}";
      if (!minutesByDay.containsKey(key)) continue;

      final duration = data['duration'];
      int mins = 0;
      if (duration is int) {
        mins = duration;
      } else if (duration is String) {
        mins = int.tryParse(duration) ?? 0;
      }
      minutesByDay[key] = (minutesByDay[key] ?? 0) + mins;
    }

    minutesByDay.forEach((key, value) {
      final parts = key.split("-");
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      result.add(
        _DayStat(
          label: _weekdayShortName(d.weekday),
          minutes: value,
        ),
      );
    });

    return result;
  }

  List<_WeekStat> _computeWeeklyStats(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();

    DateTime startOfWeek(DateTime d) {
      return DateTime(d.year, d.month, d.day)
          .subtract(Duration(days: d.weekday - 1));
    }

    final currentWeekStart = startOfWeek(now);

    final List<DateTime> weekStarts = [
      currentWeekStart.subtract(const Duration(days: 21)),
      currentWeekStart.subtract(const Duration(days: 14)),
      currentWeekStart.subtract(const Duration(days: 7)),
      currentWeekStart,
    ];

    final List<_WeekStat> result = [];

    for (final ws in weekStarts) {
      final we = ws.add(const Duration(days: 6));
      int minutes = 0;

      for (var doc in docs) {
        final data = doc.data();
        dynamic ts = data['completedAt'] ?? data['createdAt'];
        if (ts is! Timestamp) continue;
        final dt = ts.toDate();

        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        if (dateOnly.isBefore(ws) || dateOnly.isAfter(we)) continue;

        final duration = data['duration'];
        int mins = 0;
        if (duration is int) {
          mins = duration;
        } else if (duration is String) {
          mins = int.tryParse(duration) ?? 0;
        }
        minutes += mins;
      }

      final String startLabelDay =
          ws.day.toString().padLeft(2, '0');
      final String startLabelMonth =
          ws.month.toString().padLeft(2, '0');
      final String endLabelDay =
          we.day.toString().padLeft(2, '0');
      final String endLabelMonth =
          we.month.toString().padLeft(2, '0');

      final label =
          "$startLabelDay.$startLabelMonth - $endLabelDay.$endLabelMonth";

      result.add(_WeekStat(label: label, minutes: minutes));
    }

    return result;
  }

  String _weekdayShortName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Pzt";
      case DateTime.tuesday:
        return "Sal";
      case DateTime.wednesday:
        return "Çar";
      case DateTime.thursday:
        return "Per";
      case DateTime.friday:
        return "Cum";
      case DateTime.saturday:
        return "Cmt";
      case DateTime.sunday:
        return "Paz";
      default:
        return "";
    }
  }

  // --------- GRAFİKLER ---------

  Widget _buildDailyChart(List<_DayStat> stats) {
    final total = stats.fold<int>(0, (sum, s) => sum + s.minutes);
    final maxVal =
        stats.fold<int>(0, (max, s) => s.minutes > max ? s.minutes : max);

    if (maxVal == 0) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfff4f6fb),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Son 7 günde kayıtlı egzersiz bulunmuyor.",
          textAlign: TextAlign.center,
        ),
      );
    }

    const double maxBarHeight = 120.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff4f6fb),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Son 7 gün toplam: $total dk",
            style: AppWidget.mediumTextStyle(14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: maxBarHeight + 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats.map((s) {
                final h = (s.minutes / maxVal) * maxBarHeight;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: h,
                      width: 16,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<_WeekStat> stats) {
    final total = stats.fold<int>(0, (sum, s) => sum + s.minutes);
    final maxVal =
        stats.fold<int>(0, (max, s) => s.minutes > max ? s.minutes : max);

    if (maxVal == 0) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfff4f6fb),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Son 4 haftada kayıtlı egzersiz bulunmuyor.",
          textAlign: TextAlign.center,
        ),
      );
    }

    const double maxBarHeight = 120.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff4f6fb),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Son 4 hafta toplam: $total dk",
            style: AppWidget.mediumTextStyle(14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: maxBarHeight + 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats.map((s) {
                final h = (s.minutes / maxVal) * maxBarHeight;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: h,
                      width: 18,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
                      child: Text(
                        s.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --------- DİĞER UI YARDIMCI WIDGET'LAR ---------

  Widget _discoverCard({
    required String title,
    required String subtitle1,
    required String subtitle2,
    required Color color,
    required String imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0, right: 16),
      child: Material(
        elevation: 3.0,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20.0, vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Image.asset(imagePath),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topWorkoutCard(
    BuildContext context, {
    required String title,
    required String sets,
    required String reps,
    required String time,
    required String image,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 10.0),
      child: Material(
        elevation: 2.0,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.only(
            left: 30.0,
            top: 10.0,
            bottom: 8.0,
          ),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppWidget.mediumTextStyle(22.0),
                  ),
                  const SizedBox(height: 5.0),
                  Row(
                    children: [
                      Text(
                        "$sets | ",
                        style: const TextStyle(
                          color: Color.fromARGB(110, 0, 0, 0),
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        reps,
                        style: const TextStyle(
                          color: Color.fromARGB(110, 0, 0, 0),
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5.0),
                  Container(
                    padding: const EdgeInsets.all(5),
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(115, 33, 149, 243),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alarm,
                          color: Colors.black,
                          size: 25.0,
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18.00,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20.0),
              Image.asset(
                image,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayStat {
  final String label;
  final int minutes;
  _DayStat({required this.label, required this.minutes});
}

class _WeekStat {
  final String label;
  final int minutes;
  _WeekStat({required this.label, required this.minutes});
}