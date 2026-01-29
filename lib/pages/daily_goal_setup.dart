// lib/pages/daily_goal_setup.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitnessapp/services/support_widget.dart';
import 'package:fitnessapp/pages/workouts.dart';

class DailyGoalSetupPage extends StatefulWidget {
  const DailyGoalSetupPage({super.key});

  @override
  State<DailyGoalSetupPage> createState() => _DailyGoalSetupPageState();
}

class _DailyGoalSetupPageState extends State<DailyGoalSetupPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  late String _todayId;

  /// Seçilen egzersizler için key = "categoryKey|name"
  final Set<String> _selectedKeys = <String>{};

  int _totalSelectedMinutes = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayId = "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    _loadExistingSelection();
  }

  /// Firestore'da bugüne ait daily_goal varsa onu yüklüyoruz.
  Future<void> _loadExistingSelection() async {
    if (_user == null) {
      setState(() {
        _isLoading = false;
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
      if (doc.exists) {
        final data = doc.data();
        final List<dynamic> exs =
            (data?['exercises'] as List<dynamic>?) ?? <dynamic>[];

        _selectedKeys.clear();

        for (final dynamic e in exs) {
          if (e is Map<String, dynamic>) {
            final String category = e['category'] as String? ?? '';
            final String name = e['name'] as String? ?? '';
            if (category.isEmpty || name.isEmpty) continue;
            _selectedKeys.add('$category|$name');
          }
        }

        _recalculateTotalMinutes();
      } else {
        _selectedKeys.clear();
        _totalSelectedMinutes = 0;
      }
    } catch (e) {
      debugPrint('LOAD DAILY GOAL ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Günlük hedef yüklenirken bir hata oluştu: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  WorkoutDefinition? _findWorkout(String categoryKey, String name) {
    final List<WorkoutDefinition>? defs = kWorkoutCatalog[categoryKey];
    if (defs == null) return null;
    for (final WorkoutDefinition def in defs) {
      if (def.name == name) {
        return def;
      }
    }
    return null;
  }

  void _recalculateTotalMinutes() {
    int total = 0;

    for (final String key in _selectedKeys) {
      final List<String> parts = key.split('|');
      if (parts.length != 2) continue;

      final String categoryKey = parts[0];
      final String name = parts[1];

      final WorkoutDefinition? def = _findWorkout(categoryKey, name);
      if (def != null) {
        total += def.minutes;
      }
    }

    setState(() {
      _totalSelectedMinutes = total;
    });
  }

  void _toggleSelection(String categoryKey, String name) {
    final String key = '$categoryKey|$name';
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
    _recalculateTotalMinutes();
  }

  Future<void> _saveSelection() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce giriş yapın.'),
        ),
      );
      return;
    }

    if (_selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Günlük hedef için en az bir egzersiz seçmelisin.'),
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> selectedExercises =
        <Map<String, dynamic>>[];
    int totalMinutes = 0;

    for (final String key in _selectedKeys) {
      final List<String> parts = key.split('|');
      if (parts.length != 2) continue;

      final String categoryKey = parts[0];
      final String name = parts[1];

      final WorkoutDefinition? def = _findWorkout(categoryKey, name);
      final int minutes = def?.minutes ?? 5;

      selectedExercises.add(<String, dynamic>{
        'category': categoryKey,
        'name': name,
        'minutes': minutes,
        'isDone': false,
      });

      totalMinutes += minutes;
    }

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('daily_goals')
          .doc(_todayId);

      await ref.set(
        <String, dynamic>{
          'exercises': selectedExercises,
          'targetMinutes': totalMinutes,
          'completedMinutes': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Günlük hedefin kaydedildi.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('SAVE DAILY GOAL ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Günlük hedef kaydedilirken bir hata oluştu: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Günlük Hedef',
            style: AppWidget.healineTextStyle(20),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Günlük Hedef',
          style: AppWidget.healineTextStyle(20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bilgi kartı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugün için yapmak istediğin egzersizleri seç.',
                      style: AppWidget.mediumTextStyle(16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toplam süre: $_totalSelectedMinutes dk',
                      style: AppWidget.healineTextStyle(18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bu süre hedefin olarak kaydedilecek.',
                      style: AppWidget.mediumTextStyle(13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kategoriler + hareketler
            Expanded(
              child: ListView(
                children: kWorkoutCategoryTitles.entries.map((entry) {
                  final String categoryKey = entry.key;
                  final String title = entry.value;
                  final List<WorkoutDefinition> defs =
                      kWorkoutCatalog[categoryKey] ??
                          <WorkoutDefinition>[];

                  if (defs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        title,
                        style: AppWidget.healineTextStyle(18),
                      ),
                      children: defs.map((WorkoutDefinition def) {
                        final String key =
                            '$categoryKey|${def.name}';
                        final bool selected =
                            _selectedKeys.contains(key);

                        return CheckboxListTile(
                          value: selected,
                          onChanged: (_) =>
                              _toggleSelection(categoryKey, def.name),
                          title: Text(
                            def.name,
                            style: AppWidget.mediumTextStyle(15),
                          ),
                          subtitle: Text(
                            '${def.minutes} dk',
                            style: AppWidget.mediumTextStyle(13),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _saveSelection,
              icon: const Icon(Icons.save),
              label: const Text('Seçimi Kaydet'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
