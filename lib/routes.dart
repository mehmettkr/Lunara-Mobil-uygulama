import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_dream_screen.dart';
import 'screens/dream_detail_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/stats_screen.dart'; // import

class AppRoutes {
  static const gate = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const newDream = '/new-dream';
  static const dreamDetail = '/dream_detail';
  static const friends = '/friends';
  static const stats = '/stats'; // İstatistik rotası

  static final map = <String, WidgetBuilder>{
    gate: (_) => const _Gate(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),
    newDream: (_) => const NewDreamScreen(),
    dreamDetail: (_) => const DreamDetailScreen(),
    friends: (_) => const FriendsScreen(),
    stats: (_) => const StatsScreen(),
  };
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == null) {
          return const LoginScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
