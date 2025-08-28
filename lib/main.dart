import 'package:flutter/material.dart';
import 'home_page.dart';
import 'book_pages/book_burn_page.dart';
import 'book_pages/book_rocksolid_page.dart';
import 'book_pages/book_trustme_page.dart';
import 'book_pages/book_draculi_page.dart';
import 'book_pages/book_loser_page.dart';
import 'book_pages/book_bones_page.dart';

void main() {
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
        '/': (context) => const HomePage(),
        '/burn': (context) => const BookBurnPage(),
        '/rocksolid': (context) => const BookRocksolidPage(),
        '/trustme': (context) => const BookTrustmePage(),
        '/draculi': (context) => const BookDraculiPage(),
        '/loser': (context) => const BookLoserPage(),
        '/bones': (context) => const BookBonesPage(),
      },
    );
  }
}
