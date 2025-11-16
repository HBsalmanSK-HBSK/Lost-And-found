import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../app.dart';

class CreatePostPage extends StatefulWidget {
  static const routeName = '/create_post';
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _descCtrl = TextEditingController();
  int? userId;
  bool _saving = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> loadArgs() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    userId = args != null ? args['userId'] as int? : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadArgs());
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  Future<String> _saveImageLocally(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final newPath = p.join(dir.path, fileName);
    final newFile = await file.copy(newPath);
    return newFile.path;
  }

  Future<void> _save() async {
    if (userId == null) return;
    setState(() => _saving = true);

    String? savedPath;
    if (_imageFile != null) {
      savedPath = await _saveImageLocally(_imageFile!);
    }

    final db = App.db;
    await db.insert('posts', {
      'userId': userId,
      'description': _descCtrl.text,
      'createdAt': DateTime.now().toIso8601String(),
      'photo': savedPath,
    });

    // optional notification
    await db.insert('notifications', {
      'userId': userId,
      'content': 'You created a post',
      'createdAt': DateTime.now().toIso8601String(),
    });

    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _imageFile == null
                    ? const Center(child: Text('Tap to pick image'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Write something...'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
