import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class DreamFriendApp extends StatelessWidget {
  const DreamFriendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lunara',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: AppRoutes.gate,
      routes: AppRoutes.map,
    );
  }
}
