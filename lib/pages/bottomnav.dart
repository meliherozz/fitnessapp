import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:fitnessapp/pages/home.dart';
import 'package:fitnessapp/pages/profile.dart';
import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentTabIndex = 0;

  // Home ve Profile sayfaları listesi
  final List<Widget> pages = const [
    Home(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        color: Colors.black,
        animationDuration: const Duration(milliseconds: 500),
        index: currentTabIndex,
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        items: const [
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.person_outlined, color: Colors.white),
        ],
      ),
      body: pages[currentTabIndex],
    );
  }
}
