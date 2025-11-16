import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/create_post_page.dart';
import 'pages/messages_page.dart';
import 'pages/chat_page.dart';
import 'pages/notifications_page.dart';
import 'db/user.dart';
import 'db/post.dart';
import 'db/comment.dart';
import 'db/message.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class App extends StatelessWidget {
  const App({super.key});

  static Database? database;

  // Initialize DB and create tables
  static Future<void> initDb() async {
    if (database != null) return;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'app.db');
    database = await openDatabase(
      path,
      version: 2, // bump for migration that adds photo column
      onCreate: (db, version) async {
        // users table
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          displayName TEXT,
          email TEXT UNIQUE,
          password TEXT,
          profilePhoto TEXT
        )
      ''');

        // posts table with photo
        await db.execute('''
        CREATE TABLE posts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          description TEXT,
          createdAt TEXT,
          photo TEXT
        )
      ''');

        // comments table
        await db.execute('''
        CREATE TABLE comments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          postId INTEGER,
          userId INTEGER,
          content TEXT,
          createdAt TEXT
        )
      ''');

        // messages table
        await db.execute('''
        CREATE TABLE messages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fromUserId INTEGER,
          toUserId INTEGER,
          content TEXT,
          createdAt TEXT
        )
      ''');

        // notifications
        await db.execute('''
        CREATE TABLE notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          content TEXT,
          createdAt TEXT
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // add photo column for posts table if upgrading from v1
          try {
            await db.execute("ALTER TABLE posts ADD COLUMN photo TEXT");
          } catch (e) {
            // ignore if column already exists
          }
        }
      },
    );
  }

  // handy helper - get DB or throw
  static Database get db {
    if (database == null) {
      throw Exception('Database not initialized. Call App.initDb() first.');
    }
    return database!;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Social (SQLite)',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: SplashPage.routeName,
      routes: {
        SplashPage.routeName: (_) => const SplashPage(),
        LoginPage.routeName: (_) => const LoginPage(),
        RegisterPage.routeName: (_) => const RegisterPage(),
        HomePage.routeName: (_) => const HomePage(),
        ProfilePage.routeName: (_) => const ProfilePage(),
        CreatePostPage.routeName: (_) => const CreatePostPage(),
        MessagesPage.routeName: (_) => const MessagesPage(),
        NotificationsPage.routeName: (_) => const NotificationsPage(),
        // ChatPage is pushed with args
      },
      onGenerateRoute: (settings) {
        if (settings.name == ChatPage.routeName) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ChatPage(
              currentUserId: args['currentUserId'],
              otherUserId: args['otherUserId'],
            ),
          );
        }
        return null;
      },
    );
  }
}
