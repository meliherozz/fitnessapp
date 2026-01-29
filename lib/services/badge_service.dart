// lib/services/badge_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'badge_definitions.dart';

/// Kullanıcının sayaçlarına bakar, rozet şartlarını sağlayanları
/// users/{uid}/badges altına yazar ve yeni kazanılan rozetleri döner.
Future<List<BadgeDefinition>> checkAndUnlockBadges({
  required String uid,
}) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final userRef = db.collection('users').doc(uid);

  // --- 1) Kullanıcı sayaçlarını oku ---
  final userSnap = await userRef.get();
  final Map<String, dynamic> userData =
      userSnap.data() as Map<String, dynamic>? ?? <String, dynamic>{};

  int totalMinutes = 0;
  int totalWorkouts = 0;
  int dailyGoalsCompleted = 0;

  if (userData['totalMinutes'] is int) {
    totalMinutes = userData['totalMinutes'] as int;
  }
  if (userData['totalWorkouts'] is int) {
    totalWorkouts = userData['totalWorkouts'] as int;
  }
  if (userData['dailyGoalsCompleted'] is int) {
    dailyGoalsCompleted = userData['dailyGoalsCompleted'] as int;
  }

  // --- 2) Kullanıcının daha önce aldığı rozetleri oku ---
  final badgesSnap = await userRef.collection('badges').get();
  final Set<String> unlockedIds = <String>{};
  for (final doc in badgesSnap.docs) {
    unlockedIds.add(doc.id);
  }

  // --- 3) Tanımlı rozetlere bak, şartı sağlayan ama alınmamış olanları veritabanına yaz ---
  final List<BadgeDefinition> newlyUnlocked = <BadgeDefinition>[];

  for (final def in kBadgeDefinitions) {
    bool meets = false;

    switch (def.type) {
      case 'totalMinutes':
        meets = totalMinutes >= def.threshold;
        break;
      case 'totalWorkouts':
        meets = totalWorkouts >= def.threshold;
        break;
      case 'dailyGoalsCompleted':
        meets = dailyGoalsCompleted >= def.threshold;
        break;
    }

    if (meets && !unlockedIds.contains(def.id)) {
      // Yeni rozet
      await userRef.collection('badges').doc(def.id).set({
        'earnedAt': FieldValue.serverTimestamp(),
        'title': def.title,
        'description': def.description,
      });

      newlyUnlocked.add(def);
      unlockedIds.add(def.id);
    }
  }

  return newlyUnlocked;
}
