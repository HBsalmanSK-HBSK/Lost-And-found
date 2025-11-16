import 'package:flutter/material.dart';
import '../app.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final db = App.db;
    final list = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [_emailCtrl.text.trim(), _passCtrl.text],
    );
    if (list.isEmpty) {
      setState(() {
        _error = 'Invalid credentials';
        _loading = false;
      });
      return;
    }
    final userId = list.first['id'] as int;
    Navigator.of(
      context,
    ).pushReplacementNamed(HomePage.routeName, arguments: {'userId': userId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RegisterPage.routeName),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
