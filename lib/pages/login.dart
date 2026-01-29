import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fitnessapp/pages/signup.dart';
import 'package:fitnessapp/pages/bottomnav.dart';
import 'package:fitnessapp/services/support_widget.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNav(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Giriş başarısız. Lütfen tekrar deneyiniz.";
      if (e.code == 'user-not-found') {
        msg = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        msg = "Şifre hatalı.";
      } else if (e.code == 'invalid-email') {
        msg = "Geçersiz e-posta formatı.";
      } else if (e.code == 'user-disabled') {
        msg = "Bu hesap devre dışı bırakılmış.";
      }

      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Beklenmeyen bir hata oluştu: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen önce e-posta adresinizi girin."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Şifre sıfırlama bağlantısı e-posta adresinize gönderildi."),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Şifre sıfırlama işlemi başarısız oldu.";
      if (e.code == 'user-not-found') {
        msg = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      } else if (e.code == 'invalid-email') {
        msg = "Geçersiz e-posta formatı.";
      }

      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Beklenmeyen bir hata oluştu: $e";
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Üst turuncu arkaplan
          Container(
            width: size.width,
            height: size.height / 2.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFff5c3a), Color(0xFFe74b1a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Alt beyaz panel
          Container(
            margin: EdgeInsets.only(top: size.height / 3),
            height: size.height / 2,
            width: size.width,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
          ),

          // İçerik
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: size.width,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "Giriş Yap",
                              style: AppWidget.healineTextStyle(20),
                            ),
                            const SizedBox(height: 30),

                            // E-posta
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

                            const SizedBox(height: 30),

                            // Şifre
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

                            const SizedBox(height: 20),

                            // Şifremi unuttum
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _resetPassword,
                                child: Text(
                                  "Şifreni mi unuttun?",
                                  style: AppWidget.mediumTextStyle(20),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Hata mesajı
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),

                            // Giriş butonu
                            Material(
                              elevation: 5,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _isLoading ? null : _login,
                                child: Container(
                                  width: 200,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
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
                                            "GİRİŞ YAP",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Kayıt yönlendirme
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Signup(),
                        ),
                      );
                    },
                    child: Text(
                      "Hesabın yok mu? Kayıt ol",
                      style: AppWidget.mediumTextStyle(20),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
