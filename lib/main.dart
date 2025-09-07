// lib/main.dart
import 'package:flutter/material.dart';
import 'paywall/access.dart'; // paywall/progress storage

import 'home_page.dart';
import 'book_pages/book_burn_page.dart';
import 'book_pages/book_rocksolid_page.dart';
import 'book_pages/book_trustme_page.dart';
import 'book_pages/book_draculi_page.dart';
import 'book_pages/book_loser_page.dart';
import 'book_pages/book_bones_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AccessManager.instance.init();          // load paywall + progress
  // AccessManager.instance.setDebugPassThrough(true); // optional while testing
  runApp(const NovelReaderApp());
}

class NovelReaderApp extends StatelessWidget {
  const NovelReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NovelReader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Montserrat',
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      routes: {
        '/': (_) => const HomePage(),
        '/burn': (_) => const BookBurnPage(),
        '/rocksolid': (_) => const BookRocksolidPage(),
        '/trustme': (_) => const BookTrustmePage(),
        '/draculi': (_) => const BookDraculiPage(),
        '/loser': (_) => const BookLoserPage(),
        '/bones': (_) => const BookBonesPage(),
      },
    );
  }
}
