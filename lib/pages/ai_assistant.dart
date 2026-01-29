import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitnessapp/services/ai_service.dart';
import 'package:fitnessapp/services/support_widget.dart';

class AIAssistant extends StatefulWidget {
  const AIAssistant({super.key});

  @override
  State<AIAssistant> createState() => _AIAssistantState();
}

class _AIAssistantState extends State<AIAssistant> {
  final AIService _aiService = AIService();
  final User? _user = FirebaseAuth.instance.currentUser;
  
  bool _isLoading = false;
  String? _advice;
  String? _errorMessage;

  Map<String, dynamic>? _userData;
  double? _bmi;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          
          final heightCm = _userData?['height_cm'];
          final weightKg = _userData?['weight_kg'];
          
          if (heightCm != null && weightKg != null && heightCm > 0 && weightKg > 0) {
            final hMeter = heightCm.toDouble() / 100.0;
            _bmi = weightKg.toDouble() / (hMeter * hMeter);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Kullanıcı bilgileri yüklenemedi: $e';
      });
    }
  }

  Future<void> _getPersonalizedAdvice() async {
    if (_userData == null || _bmi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce profil sayfanızdan boy ve kilo bilgilerinizi girin.'),
        ),
      );
      return;
    }

    final heightCm = _userData!['height_cm']?.toDouble() ?? 0;
    final weightKg = _userData!['weight_kg']?.toDouble() ?? 0;
    final goalWeightKg = _userData!['goal_weight_kg']?.toDouble() ?? weightKg;

    if (heightCm <= 0 || weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli boy ve kilo bilgileri gerekli.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _advice = null;
      _errorMessage = null;
    });

    try {
      final result = await _aiService.getPersonalizedAdvice(
        heightCm: heightCm,
        weightKg: weightKg,
        goalWeightKg: goalWeightKg,
        bmi: _bmi!,
      );

      setState(() {
        _advice = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getWorkoutPlan() async {
    if (_userData == null || _bmi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce profil sayfanızdan boy ve kilo bilgilerinizi girin.'),
        ),
      );
      return;
    }

    final heightCm = _userData!['height_cm']?.toDouble() ?? 0;
    final weightKg = _userData!['weight_kg']?.toDouble() ?? 0;
    final goalWeightKg = _userData!['goal_weight_kg']?.toDouble() ?? weightKg;

    setState(() {
      _isLoading = true;
      _advice = null;
      _errorMessage = null;
    });

    try {
      final result = await _aiService.getWeeklyWorkoutPlan(
        heightCm: heightCm,
        weightKg: weightKg,
        goalWeightKg: goalWeightKg,
        bmi: _bmi!,
      );

      setState(() {
        _advice = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getNutritionAdvice() async {
    if (_userData == null || _bmi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce profil sayfanızdan boy ve kilo bilgilerinizi girin.'),
        ),
      );
      return;
    }

    final heightCm = _userData!['height_cm']?.toDouble() ?? 0;
    final weightKg = _userData!['weight_kg']?.toDouble() ?? 0;
    final goalWeightKg = _userData!['goal_weight_kg']?.toDouble() ?? weightKg;

    setState(() {
      _isLoading = true;
      _advice = null;
      _errorMessage = null;
    });

    try {
      final result = await _aiService.getNutritionAdvice(
        heightCm: heightCm,
        weightKg: weightKg,
        goalWeightKg: goalWeightKg,
        bmi: _bmi!,
      );

      setState(() {
        _advice = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Fitness Asistanı'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kullanıcı bilgileri özeti
            if (_userData != null && _bmi != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Senin Bilgilerin',
                        style: AppWidget.healineTextStyle(18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Boy: ${_userData!['height_cm']} cm',
                        style: AppWidget.mediumTextStyle(16),
                      ),
                      Text(
                        'Kilo: ${_userData!['weight_kg']} kg',
                        style: AppWidget.mediumTextStyle(16),
                      ),
                      Text(
                        'Hedef: ${_userData!['goal_weight_kg'] ?? "Belirtilmemiş"} kg',
                        style: AppWidget.mediumTextStyle(16),
                      ),
                      Text(
                        'BMI: ${_bmi!.toStringAsFixed(1)}',
                        style: AppWidget.mediumTextStyle(16),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // AI Tavsiye Butonları
            Text(
              'Ne Öğrenmek İstersin?',
              style: AppWidget.healineTextStyle(18),
            ),
            const SizedBox(height: 12),

            _buildAIButton(
              icon: Icons.auto_awesome,
              title: 'Kişiselleştirilmiş Tavsiye',
              subtitle: 'Sana özel fitness ve beslenme önerileri al',
              onPressed: _getPersonalizedAdvice,
            ),

            const SizedBox(height: 12),

            _buildAIButton(
              icon: Icons.fitness_center,
              title: 'Haftalık Egzersiz Programı',
              subtitle: '7 günlük kişiselleştirilmiş antrenman planı',
              onPressed: _getWorkoutPlan,
            ),

            const SizedBox(height: 12),

            _buildAIButton(
              icon: Icons.restaurant,
              title: 'Beslenme Önerileri',
              subtitle: 'Sağlıklı beslenme ve kalori rehberi',
              onPressed: _getNutritionAdvice,
            ),

            const SizedBox(height: 24),

            // Cevap alanı
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),

            if (_advice != null)
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'AI Önerisi',
                            style: AppWidget.healineTextStyle(18),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        _advice!,
                        style: AppWidget.mediumTextStyle(15),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}