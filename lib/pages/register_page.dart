import 'package:flutter/material.dart';
import '../app.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  static const routeName = '/register';
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() {
        _error = 'All fields required';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = App.db;
      final id = await db.insert('users', {
        'displayName': name,
        'email': email,
        'password': pass,
        'profilePhoto': null,
      });
      Navigator.of(
        context,
      ).pushReplacementNamed(HomePage.routeName, arguments: {'userId': id});
    } catch (e) {
      setState(() {
        _error = 'Registration failed (email maybe used)';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
