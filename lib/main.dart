import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'widgets/search_box.dart';
import 'widgets/quran_section.dart';
import 'widgets/hadith_section.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  // Set the database factory
  databaseFactory = databaseFactoryFfi;
  
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const TafseerApp());
}

class TafseerApp extends StatelessWidget {
  const TafseerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tafseer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Noto Serif',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  String? currentQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text(
                      'Tafseer',
                      style: TextStyle(
                        fontFamily: 'Noto Nastaliq Urdu',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SearchBox(
                      controller: _controller,
                      onSearch: (query) {
                        setState(() {
                          currentQuery = query;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (currentQuery != null) ...[
                ExpansionTile(
                  title: const Text(
                    'Quranic Evidence',
                    style: TextStyle(
                      fontFamily: 'Noto Nastaliq Urdu',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  initiallyExpanded: true,
                  children: [
                    QuranSection(query: currentQuery),
                  ],
                ),
                ExpansionTile(
                  title: const Text(
                    'Hadith Guidance',
                    style: TextStyle(
                      fontFamily: 'Noto Nastaliq Urdu',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  initiallyExpanded: true,
                  children: [
                    HadithSection(query: currentQuery),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}