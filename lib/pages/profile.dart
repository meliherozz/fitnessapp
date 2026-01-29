import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fitnessapp/pages/login.dart';
import 'package:fitnessapp/services/support_widget.dart';
import 'package:fitnessapp/pages/ai_assistant.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final User? _user = FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _profileStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .snapshots();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LogIn()),
    );
  }

  // BMI hesapla
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

  // BMI seviyesini 1–5 arası belirle
  int _bmiLevel(double bmi) {
    if (bmi < 18.5) return 1; // zayıf
    if (bmi < 25) return 2; // normal
    if (bmi < 30) return 3; // fazla kilolu
    if (bmi < 35) return 4; // obez
    return 5; // ileri obez
  }

  // Her seviye için yorum metni
  String _bmiComment(int level) {
    switch (level) {
      case 1:
        return "Biraz kilo alman sağlığın için iyi olabilir.";
      case 2:
        return "Harika! İdeal kilo aralığındasın, böyle devam et.";
      case 3:
        return "Biraz dikkat! Düzenli hareket ve dengeli beslenme işine yarar.";
      case 4:
        return "Riskli bölgedesin. Programlı spor ve beslenme planı önemli.";
      case 5:
        return "Ciddi risk bölgesi. Profesyonel destek alman tavsiye edilir.";
      default:
        return "";
    }
  }

  // Renkli BMI barı
  Widget _bmiColorBar(double bmi) {
    int level = _bmiLevel(bmi);

    final List<Color> colors = [
      Colors.lightBlue, // 1: zayıf
      Colors.green, // 2: normal
      Colors.yellow.shade700, // 3: fazla kilolu
      Colors.orange, // 4: obez
      Colors.red, // 5: ileri obez
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: List.generate(5, (index) {
            int boxLevel = index + 1;
            bool active = boxLevel == level;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: active ? 18 : 14,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active
                      ? colors[index]
                      : colors[index].withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.black12,
                    width: active ? 2 : 1,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(_bmiComment(level), style: AppWidget.mediumTextStyle(16)),
      ],
    );
  }

  // Boy / kilo / hedef kilo düzenleme dialogu
  Future<void> _editBodyMetrics(Map<String, dynamic>? data) async {
    final TextEditingController heightController = TextEditingController(
      text: data?['height_cm']?.toString() ?? '',
    );
    final TextEditingController weightController = TextEditingController(
      text: data?['weight_kg']?.toString() ?? '',
    );
    final TextEditingController goalWeightController = TextEditingController(
      text: data?['goal_weight_kg']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vücut Bilgilerini Düzenle'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Boy (cm)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final v = double.tryParse(value);
                      if (v == null || v <= 0) {
                        return 'Geçerli bir boy giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kilo (kg)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final v = double.tryParse(value);
                      if (v == null || v <= 0) {
                        return 'Geçerli bir kilo giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: goalWeightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hedef Kilo (kg)',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final v = double.tryParse(value);
                      if (v == null || v <= 0) {
                        return 'Geçerli bir kilo giriniz';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final num? heightCm = heightController.text.trim().isEmpty
                    ? null
                    : double.tryParse(heightController.text.trim());
                final num? weightKg = weightController.text.trim().isEmpty
                    ? null
                    : double.tryParse(weightController.text.trim());
                final num? goalWeightKg =
                    goalWeightController.text.trim().isEmpty
                    ? null
                    : double.tryParse(goalWeightController.text.trim());

                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
                      .set({
                        'height_cm': heightCm,
                        'weight_kg': weightKg,
                        'goal_weight_kg': goalWeightKg,
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                  if (!mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vücut bilgileri kaydedilirken hata oluştu: $e',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vücut bilgilerin güncellendi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapmış bir kullanıcı bulunamadı.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim'), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          final String displayName =
              data?['displayName'] ?? _user!.displayName ?? 'Kullanıcı';
          final String email = data?['email'] ?? _user!.email ?? '';

          final num? heightCm = data?['height_cm'];
          final num? weightKg = data?['weight_kg'];
          final num? goalWeightKg = data?['goal_weight_kg'];

          final bmi = _calculateBmi(heightCm, weightKg);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Basit avatar (statik görsel)
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('images/girl.jpg'),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: AppWidget.healineTextStyle(20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppWidget.mediumTextStyle(18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Hesap bilgileri kartı
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hesap Bilgileri',
                          style: AppWidget.healineTextStyle(18),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ad Soyad: $displayName',
                                style: AppWidget.mediumTextStyle(16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'E-posta: $email',
                                style: AppWidget.mediumTextStyle(16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Vücut bilgileri kartı + BMI barı
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Vücut Bilgileri',
                              style: AppWidget.healineTextStyle(18),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _editBodyMetrics(data),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Düzenle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Boy: ${heightCm != null ? "${heightCm} cm" : "Henüz girilmedi"}',
                          style: AppWidget.mediumTextStyle(16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kilo: ${weightKg != null ? "${weightKg} kg" : "Henüz girilmedi"}',
                          style: AppWidget.mediumTextStyle(16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hedef Kilo: ${goalWeightKg != null ? "${goalWeightKg} kg" : "Henüz girilmedi"}',
                          style: AppWidget.mediumTextStyle(16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BMI: ${bmi != null ? bmi.toStringAsFixed(1) : "Hesaplanamıyor"}',
                          style: AppWidget.mediumTextStyle(16),
                        ),
                        if (bmi != null) _bmiColorBar(bmi),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // AI Asistan Kartı
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AIAssistant(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.purple.shade700,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Fitness Asistanı',
                                  style: AppWidget.healineTextStyle(18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kişiselleştirilmiş öneriler al',
                                  style: AppWidget.mediumTextStyle(14),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Çıkış butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış Yap'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
