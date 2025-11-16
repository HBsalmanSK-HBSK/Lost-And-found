import 'package:flutter/material.dart';
import '../app.dart';
import '../db/user.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  static const routeName = '/messages';
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int? currentUserId;
  List<Map<String, dynamic>> users = [];

  Future<void> loadArgs() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    currentUserId = args != null ? args['userId'] as int? : null;
    final db = App.db;
    final rows = await db.query(
      'users',
      where: 'id != ?',
      whereArgs: [currentUserId ?? -1],
    );
    setState(() {
      users = rows;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadArgs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, idx) {
          final u = users[idx];
          return ListTile(
            title: Text(u['displayName'] ?? 'User'),
            subtitle: Text(u['email'] ?? ''),
            onTap: () {
              if (currentUserId == null) return;
              Navigator.of(context).pushNamed(
                ChatPage.routeName,
                arguments: {
                  'currentUserId': currentUserId,
                  'otherUserId': u['id'],
                },
              );
            },
          );
        },
      ),
    );
  }
}
