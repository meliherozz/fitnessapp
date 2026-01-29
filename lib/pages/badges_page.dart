// lib/pages/badges_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:fitnessapp/services/support_widget.dart';
import 'package:fitnessapp/services/badge_definitions.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  Set<String> _unlockedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    if (_user == null) {
      setState(() {
        _isLoading = false;
        _unlockedIds = <String>{};
      });
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(_user!.uid);
      final snap = await userRef.collection('badges').get();

      final Set<String> ids = <String>{};
      for (final doc in snap.docs) {
        ids.add(doc.id);
      }

      setState(() {
        _unlockedIds = ids;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD BADGES ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rozetler yüklenirken hata oluştu: $e')),
        );
      }
      setState(() {
        _isLoading = false;
        _unlockedIds = <String>{};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Rozetlerim',
            style: AppWidget.healineTextStyle(20),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Rozetlerim',
            style: AppWidget.healineTextStyle(20),
          ),
        ),
        body: Center(
          child: Text(
            'Rozetlerini görmek için giriş yapmalısın.',
            style: AppWidget.mediumTextStyle(16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final int unlockedCount = kBadgeDefinitions
        .where((b) => _unlockedIds.contains(b.id))
        .length;
    final int totalCount = kBadgeDefinitions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rozetlerim ($unlockedCount/$totalCount)',
          style: AppWidget.healineTextStyle(20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: kBadgeDefinitions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final badge = kBadgeDefinitions[index];
            final bool unlocked = _unlockedIds.contains(badge.id);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      unlocked ? Icons.emoji_events : Icons.lock_outline,
                      size: 40,
                      color: unlocked ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.title,
                      style: AppWidget.healineTextStyle(14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      style: AppWidget.mediumTextStyle(11),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked ? 'Kazanıldı' : 'Kilitli',
                      style: AppWidget.mediumTextStyle(11),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
