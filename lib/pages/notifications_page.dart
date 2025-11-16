import 'package:flutter/material.dart';
import '../app.dart';

class NotificationsPage extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int? userId;
  List<Map<String, dynamic>> notifs = [];

  Future<void> loadData() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    userId = args != null ? args['userId'] as int? : null;
    if (userId == null) {
      final db = App.db;
      final r = await db.query('notifications', orderBy: 'createdAt DESC');
      setState(() {
        notifs = r;
      });
      return;
    }
    final db = App.db;
    final rows = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    setState(() {
      notifs = rows;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView.builder(
          itemCount: notifs.length,
          itemBuilder: (context, idx) {
            final n = notifs[idx];
            return ListTile(
              title: Text(n['content'] ?? ''),
              subtitle: Text(n['createdAt'] ?? ''),
            );
          },
        ),
      ),
    );
  }
}
