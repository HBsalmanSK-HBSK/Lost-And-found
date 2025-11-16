import 'package:flutter/material.dart';
import '../app.dart';
import '../db/message.dart';

class ChatPage extends StatefulWidget {
  static const routeName = '/chat';
  final int currentUserId;
  final int otherUserId;

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  List<MessageModel> messages = [];

  Future<void> fetchMessages() async {
    final db = App.db;
    final rows = await db.query(
      'messages',
      where:
          '(fromUserId = ? AND toUserId = ?) OR (fromUserId = ? AND toUserId = ?)',
      whereArgs: [
        widget.currentUserId,
        widget.otherUserId,
        widget.otherUserId,
        widget.currentUserId,
      ],
      orderBy: 'createdAt ASC',
    );
    setState(() {
      messages = rows.map((r) => MessageModel.fromMap(r)).toList();
    });
  }

  Future<void> sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final db = App.db;
    await db.insert('messages', {
      'fromUserId': widget.currentUserId,
      'toUserId': widget.otherUserId,
      'content': text,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _ctrl.clear();
    await fetchMessages();
  }

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat ${widget.otherUserId}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, idx) {
                final m = messages[idx];
                final mine = m.fromUserId == widget.currentUserId;
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mine ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.content),
                        const SizedBox(height: 6),
                        Text(m.createdAt, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl)),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
