import 'dart:io';
import 'package:flutter/material.dart';
import '../app.dart';
import '../db/post.dart';
import '../db/comment.dart';
import '../db/user.dart';
import 'create_post_page.dart';
import 'profile_page.dart';
import 'messages_page.dart';
import 'notifications_page.dart';
import 'chat_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? currentUserId;
  List<PostModel> posts = [];
  Map<int, TextEditingController> _commentControllers = {};

  Future<void> loadArgs() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('userId')) {
      currentUserId = args['userId'] as int;
    } else {
      final db = App.db;
      final u = await db.query('users', limit: 1);
      if (u.isNotEmpty) currentUserId = u.first['id'] as int;
    }
    await fetchPosts();
  }

  Future<void> fetchPosts() async {
    final db = App.db;
    final rows = await db.query('posts', orderBy: 'createdAt DESC');
    setState(() {
      posts = rows.map((r) => PostModel.fromMap(r)).toList();
    });
  }

  Future<String> getUserName(int userId) async {
    final db = App.db;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return 'Unknown';
    return rows.first['displayName'] as String;
  }

  Future<List<CommentModel>> getCommentsForPost(int postId) async {
    final db = App.db;
    final rows = await db.query(
      'comments',
      where: 'postId = ?',
      whereArgs: [postId],
      orderBy: 'createdAt ASC',
    );
    return rows.map((r) => CommentModel.fromMap(r)).toList();
  }

  Future<void> _logout() async {
    Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadArgs());
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(NotificationsPage.routeName),
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed(
            CreatePostPage.routeName,
            arguments: {'userId': currentUserId},
          );
          fetchPosts();
        },
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Menu')),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(
                  ProfilePage.routeName,
                  arguments: {'userId': currentUserId},
                );
              },
            ),
            ListTile(
              title: const Text('Messages'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(
                  MessagesPage.routeName,
                  arguments: {'userId': currentUserId},
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchPosts,
        child: posts.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No posts yet')),
                ],
              )
            : ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, idx) {
                  final p = posts[idx];
                  _commentControllers.putIfAbsent(
                    p.id ?? idx,
                    () => TextEditingController(),
                  );
                  return FutureBuilder<String>(
                    future: getUserName(p.userId),
                    builder: (context, snap) {
                      final name = snap.data ?? '...';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(p.description),
                              const SizedBox(height: 6),
                              Text(
                                p.createdAt,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              if (p.photo != null && p.photo!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(p.photo!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              FutureBuilder<List<CommentModel>>(
                                future: getCommentsForPost(p.id!),
                                builder: (context, snap) {
                                  final comments = snap.data ?? [];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Comments',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (comments.isEmpty)
                                        const Text('No comments yet'),
                                      ...comments.map(
                                        (c) => Text(
                                          '- ${c.content} (by ${c.userId})',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _commentControllers[p.id ?? idx],
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment',
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (currentUserId == null) return;
                                      final content =
                                          _commentControllers[p.id ?? idx]!.text
                                              .trim();
                                      if (content.isEmpty) return;
                                      final db = App.db;
                                      await db.insert('comments', {
                                        'postId': p.id,
                                        'userId': currentUserId,
                                        'content': content,
                                        'createdAt': DateTime.now()
                                            .toIso8601String(),
                                      });
                                      _commentControllers[p.id ?? idx]!.clear();
                                      await fetchPosts();
                                    },
                                    child: const Text('Add Comment'),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.message),
                                    onPressed: () {
                                      if (currentUserId == null) return;
                                      Navigator.of(context).pushNamed(
                                        ChatPage.routeName,
                                        arguments: {
                                          'currentUserId': currentUserId,
                                          'otherUserId': p.userId,
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
