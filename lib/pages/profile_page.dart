import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../app.dart';
import '../db/post.dart';
import '../db/comment.dart';
import '../db/user.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int? userId;
  Map<String, dynamic>? user;
  List<PostModel> posts = [];
  final _commentCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> loadData() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    userId = args != null ? args['userId'] as int? : null;
    if (userId == null) return;
    final db = App.db;
    final u = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (u.isNotEmpty) user = u.first;
    final rows = await db.query(
      'posts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    setState(() {
      posts = rows.map((r) => PostModel.fromMap(r)).toList();
    });
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

  Future<void> addComment(int postId) async {
    if (userId == null) return;
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    final db = App.db;
    await db.insert('comments', {
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _commentCtrl.clear();
    await loadData();
  }

  Future<String> _saveImageLocally(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final newPath = p.join(dir.path, filename);
    final newFile = await file.copy(newPath);
    return newFile.path;
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final savedPath = await _saveImageLocally(File(picked.path));
    final db = App.db;
    await db.update(
      'users',
      {'profilePhoto': savedPath},
      where: 'id = ?',
      whereArgs: [userId],
    );
    await loadData();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadData());
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user != null
        ? user!['displayName'] as String
        : 'Profile';
    final photoPath = user?['profilePhoto'] as String?;
    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: userId == null
          ? const Center(child: Text('No user'))
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            (photoPath != null && photoPath.isNotEmpty)
                            ? FileImage(File(photoPath))
                            : null,
                        child: (photoPath == null || photoPath.isEmpty)
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${user?['displayName'] ?? ''}'),
                          const SizedBox(height: 8),
                          Text('Email: ${user?['email'] ?? ''}'),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.photo_camera),
                        onPressed: _pickProfileImage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Posts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...posts.map(
                    (p) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 8),
                            FutureBuilder<List<CommentModel>>(
                              future: getCommentsForPost(p.id!),
                              builder: (context, snap) {
                                final comments = snap.data ?? [];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _commentCtrl,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a comment',
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => addComment(p.id!),
                                      child: const Text('Add Comment'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
