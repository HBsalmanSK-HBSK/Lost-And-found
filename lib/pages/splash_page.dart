import 'package:flutter/material.dart';
import '../app.dart';
import 'login_page.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  static const routeName = '/';
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Future<void> checkAuth() async {
    final db = App.db;
    final users = await db.query('users', limit: 1);
    await Future.delayed(const Duration(milliseconds: 800));
    if (users.isNotEmpty) {
      // If users exist, navigate to home (simple auto-login to first user)
      Navigator.of(context).pushReplacementNamed(
        HomePage.routeName,
        arguments: {'userId': users.first['id']},
      );
    } else {
      Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
    }
  }

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Minimal Social',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
