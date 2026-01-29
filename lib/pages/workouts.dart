// lib/data/workouts.dart

/// Tek bir yerden tüm egzersizleri yöneteceğimiz model.
class WorkoutDefinition {
  final String id;
  final String categoryKey; // Örn: cardio, arm, stretching
  final String name;        // Kullanıcıya görünen isim
  final int minutes;        // Varsayılan süre (dakika)
  final String description; // Kısa açıklama

  const WorkoutDefinition({
    required this.id,
    required this.categoryKey,
    required this.name,
    required this.minutes,
    required this.description,
  });
}

/// Kategori başlıkları (Home sayfasındaki kartlarla uyumlu).
const Map<String, String> kWorkoutCategoryTitles = {
  'cardio': 'Kardiyo',
  'arm': 'Kol',
  'stretching': 'Esneme',
  'chest': 'Göğüs',
  'legs': 'Bacak',
  'back': 'Sırt',
  'shoulders': 'Omuz',
};

/// Tüm egzersiz katalogu.
/// Hem Discover (WorkoutVariantsPage)
/// hem de Günlük Hedef (DailyGoalSetupPage) buradan beslenecek.
const Map<String, List<WorkoutDefinition>> kWorkoutCatalog = {
  // -------------------- CARDIO --------------------
  'cardio': [
    WorkoutDefinition(
      id: 'cardio_easy_walk',
      categoryKey: 'cardio',
      name: 'Hafif Tempolu Yürüyüş',
      minutes: 3,
      description: 'Vücudu ısıtmak için hafif tempolu kısa yürüyüş.',
    ),
    WorkoutDefinition(
      id: 'cardio_normal_walk',
      categoryKey: 'cardio',
      name: 'Orta Tempolu Yürüyüş',
      minutes: 5,
      description: 'Nabzı hafifçe yükselten orta tempolu yürüyüş.',
    ),
    WorkoutDefinition(
      id: 'cardio_fast_walk',
      categoryKey: 'cardio',
      name: 'Hızlı Yürüyüş',
      minutes: 7,
      description: 'Daha yüksek tempolu, kondisyon artıran yürüyüş.',
    ),
    WorkoutDefinition(
      id: 'cardio_jumping_jacks',
      categoryKey: 'cardio',
      name: 'Jumping Jacks',
      minutes: 5,
      description: 'Tüm vücudu ısıtan temel kardiyo egzersizi.',
    ),
    WorkoutDefinition(
      id: 'cardio_high_knees',
      categoryKey: 'cardio',
      name: 'Yüksek Diz Koşusu',
      minutes: 3,
      description:
          'Yerinde koşu yaparken dizleri göğüse doğru kaldırarak uygulanır.',
    ),
    WorkoutDefinition(
      id: 'cardio_mountain_climber',
      categoryKey: 'cardio',
      name: 'Dağ Tırmanıcı (Mountain Climber)',
      minutes: 4,
      description:
          'Plank pozisyonunda bacakları sırayla göğse çekerek yapılan dinamik hareket.',
    ),
    WorkoutDefinition(
      id: 'cardio_burpee',
      categoryKey: 'cardio',
      name: 'Burpee',
      minutes: 4,
      description:
          'Squat, plank ve sıçramayı birleştiren yoğun kardiyo egzersizi.',
    ),
    WorkoutDefinition(
      id: 'cardio_stair_climb',
      categoryKey: 'cardio',
      name: 'Merdiven Çıkma',
      minutes: 7,
      description: 'Bacak kaslarını ve kondisyonu geliştiren çalışma.',
    ),
    WorkoutDefinition(
      id: 'cardio_jump_rope',
      categoryKey: 'cardio',
      name: 'İp Atlama',
      minutes: 5,
      description: 'Koordinasyon ve dayanıklılığı artıran kardiyo egzersizi.',
    ),
    WorkoutDefinition(
      id: 'cardio_interval_mix',
      categoryKey: 'cardio',
      name: 'Kısa Interval Kardiyo',
      minutes: 10,
      description:
          'Yüksek ve düşük tempo aralıklarını sırayla içeren karışık seri.',
    ),
  ],

  // -------------------- ARM --------------------
  'arm': [
    WorkoutDefinition(
      id: 'arm_pushup',
      categoryKey: 'arm',
      name: 'Şınav',
      minutes: 5,
      description: 'Göğüs, omuz ve triceps kaslarını çalıştırır.',
    ),
    WorkoutDefinition(
      id: 'arm_triceps_dips',
      categoryKey: 'arm',
      name: 'Triceps Dips',
      minutes: 5,
      description:
          'Sandalyeye dayanarak kol arkası (triceps) kaslarını hedefler.',
    ),
    WorkoutDefinition(
      id: 'arm_biceps_curl',
      categoryKey: 'arm',
      name: 'Biceps Curl',
      minutes: 5,
      description: 'Dambıl veya su şişesi ile ön kol kaslarını çalıştırır.',
    ),
    WorkoutDefinition(
      id: 'arm_plank_shoulder_tap',
      categoryKey: 'arm',
      name: 'Plank Omuz Dokunuşu',
      minutes: 3,
      description:
          'Plank pozisyonunda sırayla omuzlara dokunarak gövde stabilitesini artırır.',
    ),
    WorkoutDefinition(
      id: 'arm_diamond_pushup',
      categoryKey: 'arm',
      name: 'Dar (Diamond) Şınav',
      minutes: 4,
      description: 'Triceps ve iç göğüs bölgesini daha yoğun çalıştırır.',
    ),
  ],

  // -------------------- STRETCHING --------------------
  'stretching': [
    WorkoutDefinition(
      id: 'stretch_neck',
      categoryKey: 'stretching',
      name: 'Boyun Esnetme',
      minutes: 3,
      description: 'Öne, arkaya ve yana doğru kontrollü boyun esnetmeleri.',
    ),
    WorkoutDefinition(
      id: 'stretch_shoulder',
      categoryKey: 'stretching',
      name: 'Omuz Esnetme',
      minutes: 3,
      description:
          'Kolunu göğüs hizasında karşı tarafa çekerek omuz esnetme hareketi.',
    ),
    WorkoutDefinition(
      id: 'stretch_back_cat_cow',
      categoryKey: 'stretching',
      name: 'Cat-Cow (Sırt Mobilite)',
      minutes: 4,
      description: 'Bel ve sırt bölgesini rahatlatan mobilite hareketi.',
    ),
    WorkoutDefinition(
      id: 'stretch_hamstring',
      categoryKey: 'stretching',
      name: 'Hamstring Esnetme',
      minutes: 4,
      description: 'Bacak arka kaslarını nazikçe esneten hareket.',
    ),
    WorkoutDefinition(
      id: 'stretch_hip',
      categoryKey: 'stretching',
      name: 'Kalça Esnetme',
      minutes: 4,
      description: 'Kalça çevresindeki gerginliği azaltmak için uygulanır.',
    ),
  ],

  // -------------------- CHEST --------------------
  'chest': [
    WorkoutDefinition(
      id: 'chest_pushup',
      categoryKey: 'chest',
      name: 'Şınav (Chest Pushup)',
      minutes: 5,
      description: 'Vücut ağırlığıyla göğüs kaslarının temel egzersizi.',
    ),
    WorkoutDefinition(
      id: 'chest_incline_pushup',
      categoryKey: 'chest',
      name: 'Incline Pushup',
      minutes: 5,
      description:
          'Eller yükseltilmiş bir zeminde, daha hafif şınav varyasyonu.',
    ),
    WorkoutDefinition(
      id: 'chest_decline_pushup',
      categoryKey: 'chest',
      name: 'Decline Pushup',
      minutes: 4,
      description:
          'Ayaklar yüksekte, üst göğüs bölgesini vurgulayan şınav çeşidi.',
    ),
    WorkoutDefinition(
      id: 'chest_wide_pushup',
      categoryKey: 'chest',
      name: 'Geniş Açılı Şınav',
      minutes: 4,
      description: 'Kolları daha geniş açarak yapılan göğüs odaklı şınav.',
    ),
  ],

  // -------------------- LEGS --------------------
  'legs': [
    WorkoutDefinition(
      id: 'legs_squat',
      categoryKey: 'legs',
      name: 'Squat',
      minutes: 10,
      description: 'Tüm bacak ve kalça kaslarını çalıştıran temel hareket.',
    ),
    WorkoutDefinition(
      id: 'legs_lunge',
      categoryKey: 'legs',
      name: 'Lunge',
      minutes: 5,
      description:
          'Öne adım alarak yapılan, denge ve güç gerektiren bacak egzersizi.',
    ),
    WorkoutDefinition(
      id: 'legs_calf_raise',
      categoryKey: 'legs',
      name: 'Calf Raise',
      minutes: 5,
      description:
          'Ayak uçlarında yükselip alçalarak baldır kaslarını çalıştırır.',
    ),
    WorkoutDefinition(
      id: 'legs_wall_sit',
      categoryKey: 'legs',
      name: 'Wall Sit',
      minutes: 4,
      description:
          'Duvara yaslanıp oturma pozisyonunda bacak dayanıklılığı sağlar.',
    ),
  ],

  // -------------------- BACK --------------------
  'back': [
    WorkoutDefinition(
      id: 'back_superman',
      categoryKey: 'back',
      name: 'Superman',
      minutes: 5,
      description:
          'Yüzüstü uzanıp kolları ve bacakları kaldırarak sırt kaslarını çalıştırır.',
    ),
    WorkoutDefinition(
      id: 'back_bridge',
      categoryKey: 'back',
      name: 'Bridge',
      minutes: 5,
      description:
          'Sırtüstü yatarken kalçayı kaldırarak bel ve kalçayı güçlendirir.',
    ),
    WorkoutDefinition(
      id: 'back_reverse_snow_angel',
      categoryKey: 'back',
      name: 'Ters Kar Meleği',
      minutes: 4,
      description:
          'Yüzüstü pozisyonda kolları yarım daire şeklinde hareket ettirerek sırtı çalıştırır.',
    ),
    WorkoutDefinition(
      id: 'back_row_band',
      categoryKey: 'back',
      name: 'Elastik Bant Row',
      minutes: 4,
      description:
          'Direnç bandı ile kürek hareketi yaparak sırt kaslarını aktive eder.',
    ),
  ],

  // -------------------- SHOULDERS --------------------
  'shoulders': [
    WorkoutDefinition(
      id: 'shoulder_lateral_raise',
      categoryKey: 'shoulders',
      name: 'Lateral Raise',
      minutes: 4,
      description:
          'Kolları yana açarak yapılan, omuz yan başını çalıştıran hareket.',
    ),
    WorkoutDefinition(
      id: 'shoulder_front_raise',
      categoryKey: 'shoulders',
      name: 'Front Raise',
      minutes: 4,
      description:
          'Kolları öne kaldırarak omuz ön başını hedefleyen egzersiz.',
    ),
    WorkoutDefinition(
      id: 'shoulder_press',
      categoryKey: 'shoulders',
      name: 'Omuz Press',
      minutes: 5,
      description:
          'Ağırlığı baş üstüne kaldırarak tüm omuz kaslarını çalıştırır.',
    ),
    WorkoutDefinition(
      id: 'shoulder_reverse_fly',
      categoryKey: 'shoulders',
      name: 'Reverse Fly',
      minutes: 4,
      description:
          'Sırt ve arka omuz kaslarını aktive eden açma-kapama hareketi.',
    ),
  ],
};
