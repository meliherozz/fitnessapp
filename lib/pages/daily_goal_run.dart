// lib/pages/daily_goal_run.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fitnessapp/pages/workout_timer_service.dart';
import 'package:fitnessapp/services/support_widget.dart';
import 'package:fitnessapp/services/badge_service.dart';

class DailyGoalRunPage extends StatefulWidget {
  const DailyGoalRunPage({super.key});

  @override
  State<DailyGoalRunPage> createState() => _DailyGoalRunPageState();
}

class _DailyGoalRunPageState extends State<DailyGoalRunPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  bool _hasGoal = false;

  late String _todayId;

  int _targetMinutes = 0;
  int _completedMinutes = 0;
  List<Map<String, dynamic>> _exercises = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayId = "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
    _loadDailyGoal();
  }

  Future<void> _loadDailyGoal() async {
    if (_user == null) {
      setState(() {
        _isLoading = false;
        _hasGoal = false;
      });
      return;
    }

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('daily_goals')
          .doc(_todayId);

      final doc = await ref.get();

      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _hasGoal = false;
        });
        return;
      }

      final data = doc.data() ?? <String, dynamic>{};

      final List<Map<String, dynamic>> exs = <Map<String, dynamic>>[];
      final rawList = data['exercises'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic item in rawList) {
        if (item is Map<String, dynamic>) {
          exs.add(Map<String, dynamic>.from(item));
        }
      }

      setState(() {
        _targetMinutes = data['targetMinutes'] as int? ?? 0;
        _completedMinutes = data['completedMinutes'] as int? ?? 0;
        _exercises = exs;
        _hasGoal = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD DAILY GOAL RUN ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Günlük antrenman yüklenemedi: $e')),
        );
      }
      setState(() {
        _isLoading = false;
        _hasGoal = false;
      });
    }
  }

  double get _progressPercent {
    if (_targetMinutes <= 0) return 0.0;
    final p = _completedMinutes / _targetMinutes;
    if (p < 0) return 0.0;
    if (p > 1) return 1.0;
    return p;
  }

  Future<void> _runExercise(int index) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapın.')),
      );
      return;
    }

    if (index < 0 || index >= _exercises.length) return;

    final ex = _exercises[index];
    final bool isDone = ex['isDone'] == true;

    // Zaten bitmişse tekrar başlatma
    if (isDone) return;

    final String name = ex['name']?.toString() ?? 'Egzersiz';
    final String category = ex['category']?.toString() ?? '';
    final int minutes =
        ex['minutes'] is int ? ex['minutes'] as int : int.tryParse('${ex['minutes']}') ?? 5;

    String imagePath = 'assets/images/avatar.png';
    if (category == 'cardio') imagePath = 'assets/images/cardio.png';
    if (category == 'arm') imagePath = 'assets/images/arm.png';
    if (category == 'legs') imagePath = 'assets/images/legs.png';
    if (category == 'chest') imagePath = 'assets/images/chest.png';
    if (category == 'back') imagePath = 'assets/images/back.png';
    if (category == 'shoulders') imagePath = 'assets/images/shoulder.png';
    if (category == 'stretching') imagePath = 'assets/images/stretch.png';

    final bool? finished = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutTimerPage(
          title: name,
          description: '',
          minutes: minutes,
          imagePath: imagePath,
        ),
      ),
    );

    if (finished == true) {
      await _markExerciseCompleted(index, minutes);
    }
  }

  Future<void> _markExerciseCompleted(int index, int minutes) async {
    if (index < 0 || index >= _exercises.length) return;
    if (_user == null) return;

    final bool wasCompletedBefore =
        _completedMinutes >= _targetMinutes && _targetMinutes > 0;

    // Lokal state güncelle
    setState(() {
      _exercises[index]['isDone'] = true;
      _completedMinutes += minutes;
    });

    final bool isCompletedNow =
        _completedMinutes >= _targetMinutes && _targetMinutes > 0;

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('daily_goals')
          .doc(_todayId);

      await ref.update({
        'exercises': _exercises,
        'completedMinutes': _completedMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Günlük hedef ilk kez %100 tamamlandıysa sayaç + rozet
      if (!wasCompletedBefore && isCompletedNow) {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid);

        await userRef.set({
          'dailyGoalsCompleted': FieldValue.increment(1),
        }, SetOptions(merge: true));

        final newBadges =
            await checkAndUnlockBadges(uid: _user!.uid);

        if (mounted && newBadges.isNotEmpty) {
          final names = newBadges.map((b) => b.title).join(", ");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "🎖 Günlük hedef tamamlandı! Yeni rozet(ler): $names",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('MARK EXERCISE COMPLETED ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Egzersiz durumu güncellenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Günlük Antrenmanım',
            style: AppWidget.healineTextStyle(20),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasGoal) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Günlük Antrenmanım',
            style: AppWidget.healineTextStyle(20),
          ),
        ),
        body: Center(
          child: Text(
            'Bugün için hedef tanımlamadın.\nÖnce günlük hedef oluştur.',
            style: AppWidget.mediumTextStyle(16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final int doneCount =
        _exercises.where((e) => e['isDone'] == true).length;
    final int totalCount = _exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Günlük Antrenmanım',
          style: AppWidget.healineTextStyle(20),
        ),
      ),
      body: Column(
        children: [
          // Üst özet alanı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toplam hedef süre: $_targetMinutes dk',
                  style: AppWidget.mediumTextStyle(16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tamamlanan süre: $_completedMinutes dk',
                  style: AppWidget.mediumTextStyle(16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tamamlanan hareket: $doneCount / $totalCount',
                  style: AppWidget.mediumTextStyle(16),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progressPercent,
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text(
                  '%${(_progressPercent * 100).toStringAsFixed(0)} tamamlandı',
                  style: AppWidget.mediumTextStyle(14),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Egzersiz listesi
          Expanded(
            child: ListView.builder(
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final ex = _exercises[index];
                final String name = ex['name']?.toString() ?? '';
                final String category =
                    ex['category']?.toString() ?? '';
                final int minutes =
                    ex['minutes'] is int ? ex['minutes'] as int : 0;
                final bool isDone = ex['isDone'] == true;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    onTap: () => _runExercise(index),
                    title: Text(
                      name,
                      style: AppWidget.healineTextStyle(16),
                    ),
                    subtitle: Text(
                      '$category • $minutes dk',
                      style: AppWidget.mediumTextStyle(13),
                    ),
                    trailing: Icon(
                      isDone ? Icons.check_circle : Icons.play_arrow,
                      color: isDone ? Colors.green : Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
