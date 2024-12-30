import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin/screens/admin_screen.dart';
import 'login_screen.dart';
import 'user/screens/user_screen.dart';

Future<Widget> determineHomeScreen() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('admin')
        .where('email', isEqualTo: user.email)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      return const AdminScreen();
    } else {
      return const UserScreen();
    }
  } else {
    return const LoginScreen();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  double _opacity = 1.0;
  double _scale = 1.2;
  late Future<Widget> _homeScreenFuture;

  @override
  void initState() {
    super.initState();
    _homeScreenFuture = determineHomeScreen();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _opacity = 0.0;
        _scale = 0.0;
      });
    });
    Future.delayed(const Duration(seconds: 3), () async {
      final homeScreen = await _homeScreenFuture;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => homeScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 3),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(seconds: 3),
            curve: Curves.easeOut,
            child: Image.asset(
              'assets/system/splash/splash.png',
              width: 200,
              height: 200,
            ),
          ),
        ),
      ),
    );
  }
}
