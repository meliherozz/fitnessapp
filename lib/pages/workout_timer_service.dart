// lib/pages/workout_timer_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitnessapp/services/support_widget.dart';
import 'package:fitnessapp/services/badge_service.dart'; // ✅ YENİ

class WorkoutTimerPage extends StatefulWidget {
  final String title;
  final String description;
  final int minutes;
  final String imagePath;

  const WorkoutTimerPage({
    super.key,
    required this.title,
    required this.description,
    required this.minutes,
    required this.imagePath,
  });

  @override
  State<WorkoutTimerPage> createState() => _WorkoutTimerPageState();
}

class _WorkoutTimerPageState extends State<WorkoutTimerPage> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;

  bool _hasStarted = false;   // kullanıcı başlattı mı?
  bool _isRunning = false;    // timer şu an çalışıyor mu?
  bool _isCompleted = false;  // süre bitti mi?
  bool _isSaving = false;     // Firestore kaydı sırasında

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.minutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  void _startTimer() {
    if (_isRunning || _isCompleted) return;

    setState(() {
      _hasStarted = true;
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
          _isCompleted = true;
        });
        await _onTimerCompleted();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _stopTimerWithoutSaving() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _onTimerCompleted() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giriş yapılmamış.")),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection("users").doc(user.uid);

      // 1) Antrenman kaydı
      await userRef.collection("workouts").add({
        "type": widget.title,
        "duration": widget.minutes,
        "description": widget.description,
        "imagePath": widget.imagePath,
        "createdAt": FieldValue.serverTimestamp(),
        "completedAt": FieldValue.serverTimestamp(),
      });

      // 2) Kullanıcı sayaçlarını artır
      await userRef.set({
        "totalMinutes": FieldValue.increment(widget.minutes),
        "totalWorkouts": FieldValue.increment(1),
      }, SetOptions(merge: true));

      // 3) Rozet kontrolü
      final newBadges = await checkAndUnlockBadges(uid: user.uid);

      if (!mounted) return;

      // 4) Bilgi mesajları
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.title} tamamlandı!")),
      );

      if (newBadges.isNotEmpty) {
        final badgeNames = newBadges.map((b) => b.title).join(", ");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎖 Yeni rozet(ler) kazandın: $badgeNames")),
        );
      }

      // ✅ Bu sayfa "egzersiz başarıyla bitti" sonucuyla kapanır.
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt sırasında hata oluştu.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmExit() async {
    // Eğer hiç başlamamışsa direk çık
    if (!_hasStarted || _isCompleted) {
      return true;
    }

    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Egzersizden çıkılsın mı?"),
        content: const Text(
            "Zamanlayıcıyı durdurursan bu egzersiz tamamlanmış sayılmayacak."),
        actions: [
          TextButton(
            child: const Text("Vazgeç"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text("Çık"),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      _stopTimerWithoutSaving();
      return true;
    }

    return false;
  }

  String _formatTime(int total) {
    final m = total ~/ 60;
    final s = total % 60;
    return "${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}";
  }

  double get _progress {
    if (_totalSeconds <= 0) return 0.0;
    return 1 - (_remainingSeconds / _totalSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final ok = await _confirmExit();
              if (ok) {
                // Yarıda çıkarsa false ile dönüyoruz
                Navigator.pop(context, false);
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Üst görsel
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  widget.imagePath,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // Açıklama
              Text(
                widget.description,
                style: AppWidget.mediumTextStyle(16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Sayaç
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 180,
                        width: 180,
                        child: CircularProgressIndicator(
                          value: _progress.clamp(0.0, 1.0),
                          strokeWidth: 12,
                        ),
                      ),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: AppWidget.healineTextStyle(32),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Alt buton
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isSaving
                    ? const Center(child: Text("Kaydediliyor..."))
                    : (!_hasStarted || !_isRunning) && !_isCompleted
                        ? ElevatedButton(
                            onPressed: _startTimer,
                            child: const Text(
                              "BAŞLAT",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : !_isCompleted
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  final ok = await _confirmExit();
                                  if (ok) {
                                    Navigator.pop(context, false);
                                  }
                                },
                                child: const Text(
                                  "EGZERSİZİ DURDUR",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const Text("Kaydediliyor..."),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
