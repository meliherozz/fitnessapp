// lib/services/badge_definitions.dart

class BadgeDefinition {
  final String id;
  final String title;
  final String description;

  /// Hangi sayıya bakacağız:
  /// "totalMinutes", "totalWorkouts", "dailyGoalsCompleted"
  final String type;

  /// Eşik değer (ör: 10 dk, 5 hedef vb.)
  final int threshold;

  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.threshold,
  });
}

/// Şimdilik 5 temel rozet:
///
/// - İlk antrenman
/// - 10 dk toplam süre
/// - 60 dk toplam süre
/// - 1 günlük hedef tamamlama
/// - 5 günlük hedef tamamlama
const List<BadgeDefinition> kBadgeDefinitions = [
  BadgeDefinition(
    id: 'first_workout',
    title: 'İlk Adım',
    description: 'İlk antrenmanını tamamladın.',
    type: 'totalWorkouts',
    threshold: 1,
  ),
  BadgeDefinition(
    id: 'minutes_10',
    title: 'Isınma Bitti',
    description: 'Toplamda 10 dakika egzersiz yaptın.',
    type: 'totalMinutes',
    threshold: 10,
  ),
  BadgeDefinition(
    id: 'minutes_60',
    title: 'Yeni Sporcu',
    description: 'Toplamda 60 dakika egzersiz yaptın.',
    type: 'totalMinutes',
    threshold: 60,
  ),
  BadgeDefinition(
    id: 'first_daily_goal',
    title: 'İlk Günlük Hedef',
    description: 'İlk günlük hedefini tamamen tamamladın.',
    type: 'dailyGoalsCompleted',
    threshold: 1,
  ),
  BadgeDefinition(
    id: 'daily_goal_5',
    title: 'Disiplinli Günler',
    description: '5 farklı günde günlük hedeflerini tamamladın.',
    type: 'dailyGoalsCompleted',
    threshold: 5,
  ),
];
