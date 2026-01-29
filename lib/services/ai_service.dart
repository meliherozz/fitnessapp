import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // API Key'inizi buraya yapıştırın (Google AI Studio'dan kopyalayın)
  static const String _apiKey = 'AIzaSyDJ7MlH2STPtXWERD5kcEH-8d3Sbtc5uv8';

  late final GenerativeModel _model;

  AIService() {
    // Gemini 1.5 Flash modelini kullan
    _model = GenerativeModel(model: 'gemini-2.0-flash-lite', apiKey: _apiKey);
  }

  // Kişiselleştirilmiş fitness tavsiyesi al
  Future<String> getPersonalizedAdvice({
    required double heightCm,
    required double weightKg,
    required double goalWeightKg,
    required double bmi,
  }) async {
    try {
      final prompt =
          '''
Sen bir fitness ve beslenme uzmanısın. Aşağıdaki bilgilere göre kullanıcıya kısa, öz ve motive edici tavsiyeler ver:

Kullanıcı Bilgileri:
- Boy: $heightCm cm
- Kilo: $weightKg kg
- Hedef Kilo: $goalWeightKg kg
- BMI: ${bmi.toStringAsFixed(1)}

Lütfen şunları yap:
1. BMI durumunu kısaca değerlendir (1-2 cümle)
2. Hedefe ulaşmak için 3 pratik öneri ver (egzersiz, beslenme, yaşam tarzı)
3. Motivasyon cümlesi ekle
4. Maksimum 200 kelime kullan
5. Samimi ve destekleyici bir dil kullan
6. Türkçe yaz

Yanıt formatı:
**Durum Değerlendirmesi:**
[BMI analizi]

**Önerilerim:**
1. [Egzersiz önerisi]
2. [Beslenme önerisi]
3. [Yaşam tarzı önerisi]

**Motivasyon:**
[Motive edici mesaj]
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Tavsiye alınamadı.';
    } catch (e) {
      return 'AI tavsiyesi alınırken hata oluştu: $e';
    }
  }

  // Haftalık egzersiz programı öner
  Future<String> getWeeklyWorkoutPlan({
    required double heightCm,
    required double weightKg,
    required double goalWeightKg,
    required double bmi,
  }) async {
    try {
      final isWeightLoss = goalWeightKg < weightKg;
      final goal = isWeightLoss ? 'kilo vermek' : 'kilo almak';

      final prompt =
          '''
Sen bir fitness antrenörüsün. Aşağıdaki bilgilere göre 7 günlük basit egzersiz programı hazırla:

Kullanıcı Bilgileri:
- Boy: $heightCm cm
- Kilo: $weightKg kg
- Hedef: $goalWeightKg kg ($goal)
- BMI: ${bmi.toStringAsFixed(1)}

Her gün için:
- Egzersiz türü (kardiyo, kuvvet, esneklik)
- Süre (dakika)
- Örnek hareketler (3-4 tane)

Format:
**Pazartesi:**
[Egzersiz bilgisi]

**Salı:**
[Egzersiz bilgisi]

... (7 güne tamamla)

Kısa ve uygulanabilir öneriler yap. Evde yapılabilir hareketler öner.
Türkçe yaz.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Program oluşturulamadı.';
    } catch (e) {
      return 'Egzersiz programı oluşturulurken hata: $e';
    }
  }

  // Beslenme önerileri al
  Future<String> getNutritionAdvice({
    required double heightCm,
    required double weightKg,
    required double goalWeightKg,
    required double bmi,
  }) async {
    try {
      final isWeightLoss = goalWeightKg < weightKg;
      final goal = isWeightLoss ? 'kilo verme' : 'kilo alma';

      final prompt =
          '''
Sen bir diyetisyensin. Aşağıdaki bilgilere göre beslenme önerileri ver:

Kullanıcı Bilgileri:
- Boy: $heightCm cm
- Kilo: $weightKg kg
- Hedef: $goalWeightKg kg ($goal)
- BMI: ${bmi.toStringAsFixed(1)}

Lütfen şunları ver:
1. Günlük tahmini kalori ihtiyacı
2. Makro oranları (protein, karbonhidrat, yağ)
3. Önerilen yiyecekler (5-6 tane)
4. Kaçınılması gereken yiyecekler (3-4 tane)
5. Su tüketimi önerisi

Kısa ve pratik öneriler yap.
Türkçe yaz.
Maksimum 250 kelime.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Beslenme önerileri alınamadı.';
    } catch (e) {
      return 'Beslenme önerileri alınırken hata: $e';
    }
  }

  // Genel soru-cevap (chatbot)
  Future<String> askQuestion(
    String question,
    Map<String, dynamic> userData,
  ) async {
    try {
      final heightCm = userData['height_cm'] ?? 0;
      final weightKg = userData['weight_kg'] ?? 0;
      final goalWeightKg = userData['goal_weight_kg'] ?? 0;

      final prompt =
          '''
Sen kişisel bir fitness asistanısın. Kullanıcının sorusuna cevap ver.

Kullanıcı Bilgileri:
- Boy: $heightCm cm
- Kilo: $weightKg kg
- Hedef Kilo: $goalWeightKg kg

Kullanıcı Sorusu: $question

Samimi, bilgilendirici ve motive edici bir dille cevap ver.
Türkçe yaz.
Maksimum 150 kelime.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Cevap alınamadı.';
    } catch (e) {
      return 'Soru cevaplanırken hata oluştu: $e';
    }
  }
}
