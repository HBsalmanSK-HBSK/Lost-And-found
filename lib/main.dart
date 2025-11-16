import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await App.initDb(); // Initialize the database before launching the app
  runApp(const App());
}
