// lib/pages/workout_variants_page.dart

import 'package:flutter/material.dart';
import 'package:fitnessapp/services/support_widget.dart';
import 'package:fitnessapp/pages/workout_timer_service.dart';
import 'package:fitnessapp/pages/workouts.dart';

class WorkoutVariantsPage extends StatelessWidget {
  final String baseTitle;   // Örn: Kardiyo, Kol, Göğüs...
  final String categoryKey; // Örn: "cardio", "arm", "chest"
  final String imagePath;

  const WorkoutVariantsPage({
    super.key,
    required this.baseTitle,
    required this.categoryKey,
    required this.imagePath,
  });

  List<WorkoutDefinition> _getDefinitions() {
    // kategori bulunamazsa boş liste döner, hata vermez
    final List<WorkoutDefinition>? defs = kWorkoutCatalog[categoryKey];
    return defs ?? <WorkoutDefinition>[];
  }

  void _startVariant(BuildContext context, WorkoutDefinition def) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutTimerPage(
          title: "$baseTitle - ${def.name}",
          description: def.description,
          minutes: def.minutes,
          imagePath: imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variants = _getDefinitions();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          baseTitle,
          style: AppWidget.healineTextStyle(20),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst görsel + kısa açıklama
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "$baseTitle kategorisindeki kısa egzersizler arasından seçim yap.",
                  style: AppWidget.mediumTextStyle(16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Egzersiz listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final def = variants[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      def.name,
                      style: AppWidget.healineTextStyle(16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "${def.minutes} dk • ${def.description}",
                        style: AppWidget.mediumTextStyle(13),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => _startVariant(context, def),
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
