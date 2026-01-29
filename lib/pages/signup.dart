import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitnessapp/pages/bottomnav.dart';
import 'package:fitnessapp/pages/login.dart';
import 'package:fitnessapp/services/support_widget.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // displayName'i kaydet
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      if (!mounted) return;

      // Kayıt başarılı → BottomNav'a gönder
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Kayıt başarısız. Lütfen tekrar deneyiniz.";
      if (e.code == 'email-already-in-use') {
        msg = "Bu e-posta ile zaten bir hesap var.";
      } else if (e.code == 'weak-password') {
        msg = "Şifre çok zayıf. Daha güçlü bir şifre belirleyin.";
      } else if (e.code == 'invalid-email') {
        msg = "Geçersiz e-posta formatı.";
      }

      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Beklenmeyen bir hata oluştu.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Üstteki turuncu gradient arkaplan
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFff5c3a), Color(0xFFe74b1a)],
              ),
            ),
          ),

          // Alttaki beyaz panel
          Container(
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height / 3,
            ),
            height: MediaQuery.of(context).size.height / 2,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
          ),

          // Asıl içerik
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 50.0),
                  Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: 10.0,
                        bottom: 10.0,
                      ),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20.0),
                            Text(
                              "Kayıt Ol",
                              style: AppWidget.healineTextStyle(20),
                            ),
                            const SizedBox(height: 30.0),

                            // NAME
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: "İsim",
                                hintStyle: AppWidget.mediumTextStyle(20),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return "İsim boş olamaz";
                                }
                                if (value.trim().length < 2) {
                                  return "Lütfen geçerli bir isim girin";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20.0),

                            // EMAIL
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: "E-posta",
                                hintStyle: AppWidget.mediumTextStyle(20),
                                prefixIcon:
                                    const Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return "E-posta boş olamaz";
                                }
                                if (!value.contains("@")) {
                                  return "Geçerli bir e-posta giriniz";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20.0),

                            // PASSWORD
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: "Şifre",
                                hintStyle: AppWidget.mediumTextStyle(20),
                                prefixIcon:
                                    const Icon(Icons.password_outlined),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return "Şifre boş olamaz";
                                }
                                if (value.trim().length < 6) {
                                  return "Şifre en az 6 karakter olmalı";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20.0),

                            // Hata mesajı
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20.0),

                            // SIGNUP BUTONU
                            Material(
                              elevation: 5.0,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _isLoading ? null : _register,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffff5722),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "KAYIT OL",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40.0),

                  // Login'e geçiş
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogIn(),
                        ),
                      );
                    },
                    child: Text(
                      "Zaten hesabın var mı? Giriş yap",
                      style: AppWidget.mediumTextStyle(20),
                    ),
                  ),

                  const SizedBox(height: 30.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
