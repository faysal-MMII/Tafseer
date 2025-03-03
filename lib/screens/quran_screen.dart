import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/text_styles.dart';
import 'dart:convert';
import 'quran_detail_screen.dart';

// List of all 114 Surahs
final List<Map<String, String>> surahNames = [
  {"number": "1", "name": "Al-Fatihah"},
  {"number": "2", "name": "Al-Baqarah"},
  {"number": "3", "name": "Ali 'Imran"},
  {"number": "4", "name": "An-Nisa"},
  {"number": "5", "name": "Al-Ma'idah"},
  {"number": "6", "name": "Al-An'am"},
  {"number": "7", "name": "Al-A'raf"},
  {"number": "8", "name": "Al-Anfal"},
  {"number": "9", "name": "At-Tawbah"},
  {"number": "10", "name": "Yunus"},
  {"number": "11", "name": "Hud"},
  {"number": "12", "name": "Yusuf"},
  {"number": "13", "name": "Ar-Ra'd"},
  {"number": "14", "name": "Ibrahim"},
  {"number": "15", "name": "Al-Hijr"},
  {"number": "16", "name": "An-Nahl"},
  {"number": "17", "name": "Al-Isra"},
  {"number": "18", "name": "Al-Kahf"},
  {"number": "19", "name": "Maryam"},
  {"number": "20", "name": "Ta-Ha"},
  {"number": "21", "name": "Al-Anbiya"},
  {"number": "22", "name": "Al-Hajj"},
  {"number": "23", "name": "Al-Mu'minun"},
  {"number": "24", "name": "An-Nur"},
  {"number": "25", "name": "Al-Furqan"},
  {"number": "26", "name": "Ash-Shu'ara"},
  {"number": "27", "name": "An-Naml"},
  {"number": "28", "name": "Al-Qasas"},
  {"number": "29", "name": "Al-Ankabut"},
  {"number": "30", "name": "Ar-Rum"},
  {"number": "31", "name": "Luqman"},
  {"number": "32", "name": "As-Sajda"},
  {"number": "33", "name": "Al-Ahzab"},
  {"number": "34", "name": "Saba"},
  {"number": "35", "name": "Fatir"},
  {"number": "36", "name": "Ya-Sin"},
  {"number": "37", "name": "As-Saffat"},
  {"number": "38", "name": "Sad"},
  {"number": "39", "name": "Az-Zumar"},
  {"number": "40", "name": "Ghafir"},
  {"number": "41", "name": "Fussilat"},
  {"number": "42", "name": "Ash-Shura"},
  {"number": "43", "name": "Az-Zukhruf"},
  {"number": "44", "name": "Ad-Dukhan"},
  {"number": "45", "name": "Al-Jathiya"},
  {"number": "46", "name": "Al-Ahqaf"},
  {"number": "47", "name": "Muhammad"},
  {"number": "48", "name": "Al-Fath"},
  {"number": "49", "name": "Al-Hujurat"},
  {"number": "50", "name": "Qaf"},
  {"number": "51", "name": "Adh-Dhariyat"},
  {"number": "52", "name": "At-Tur"},
  {"number": "53", "name": "An-Najm"},
  {"number": "54", "name": "Al-Qamar"},
  {"number": "55", "name": "Ar-Rahman"},
  {"number": "56", "name": "Al-Waqi'a"},
  {"number": "57", "name": "Al-Hadid"},
  {"number": "58", "name": "Al-Mujadila"},
  {"number": "59", "name": "Al-Hashr"},
  {"number": "60", "name": "Al-Mumtahana"},
  {"number": "61", "name": "As-Saff"},
  {"number": "62", "name": "Al-Jumu'a"},
  {"number": "63", "name": "Al-Munafiqun"},
  {"number": "64", "name": "At-Taghabun"},
  {"number": "65", "name": "At-Talaq"},
  {"number": "66", "name": "At-Tahrim"},
  {"number": "67", "name": "Al-Mulk"},
  {"number": "68", "name": "Al-Qalam"},
  {"number": "69", "name": "Al-Haaqqa"},
  {"number": "70", "name": "Al-Ma'arij"},
  {"number": "71", "name": "Nuh"},
  {"number": "72", "name": "Al-Jinn"},
  {"number": "73", "name": "Al-Muzzammil"},
  {"number": "74", "name": "Al-Muddathir"},
  {"number": "75", "name": "Al-Qiyama"},
  {"number": "76", "name": "Al-Insan"},
  {"number": "77", "name": "Al-Mursalat"},
  {"number": "78", "name": "An-Naba"},
  {"number": "79", "name": "An-Nazi'at"},
  {"number": "80", "name": "Abasa"},
  {"number": "81", "name": "At-Takwir"},
  {"number": "82", "name": "Al-Infitar"},
  {"number": "83", "name": "Al-Mutaffifin"},
  {"number": "84", "name": "Al-Inshiqaq"},
  {"number": "85", "name": "Al-Burooj"},
  {"number": "86", "name": "At-Takwir"},
  {"number": "87", "name": "Al-A'la"},
  {"number": "88", "name": "Al-Ghashiya"},
  {"number": "89", "name": "Al-Fajr"},
  {"number": "90", "name": "Al-Balad"},
  {"number": "91", "name": "Ash-Shams"},
  {"number": "92", "name": "Al-Lail"},
  {"number": "93", "name": "Ad-Duha"},
  {"number": "94", "name": "Al-Inshirah"},
  {"number": "95", "name": "At-Tin"},
  {"number": "96", "name": "Al-Alaq"},
  {"number": "97", "name": "Al-Qadr"},
  {"number": "98", "name": "Al-Bayyina"},
  {"number": "99", "name": "Az-Zalzala"},
  {"number": "100", "name": "Al-Adiyat"},
  {"number": "101", "name": "Al-Qari'a"},
  {"number": "102", "name": "At-Takathur"},
  {"number": "103", "name": "Al-Asr"},
  {"number": "104", "name": "Al-Humaza"},
  {"number": "105", "name": "Al-Fil"},
  {"number": "106", "name": "Quraish"},
  {"number": "107", "name": "Al-Ma'un"},
  {"number": "108", "name": "Al-Kawthar"},
  {"number": "109", "name": "Al-Kafirun"},
  {"number": "110", "name": "An-Nasr"},
  {"number": "111", "name": "Al-Masad"},
  {"number": "112", "name": "Al-Ikhlas"},
  {"number": "113", "name": "Al-Falaq"},
  {"number": "114", "name": "An-Nas"},
];

class QuranScreen extends StatefulWidget {
  @override
  _QuranScreenState createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic>? _selectedSurahVerses; // Changed from List<Map<String, dynamic>>?
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _loadQuranData();
  }

  Future<void> _loadQuranData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load English translation
      final String translationJson = await rootBundle.loadString('assets/data/translation.json');
      final translationData = json.decode(translationJson);
      
      // Load Arabic text
      final String arabicJson = await rootBundle.loadString('assets/data/quran-arabic.json');
      final arabicData = json.decode(arabicJson);
      
      // Merge the data
      _surahs = List<Map<String, dynamic>>.from(
        translationData['quran']['chapters'].map((ch) {
          // Find the corresponding Arabic chapter
          final arabicChapter = arabicData['quran']['chapters'].firstWhere(
            (arabCh) => arabCh['chapter'] == ch['chapter'],
            orElse: () => {'verses': []},
          );
          
          // Find the corresponding surah name
          final surahInfo = surahNames.firstWhere(
            (s) => int.parse(s['number']!) == ch['chapter'],
            orElse: () => {"number": "${ch['chapter']}", "name": "Surah ${ch['chapter']}"},
          );
          
          // Merge verses with both Arabic and English text
          final List<Map<String, dynamic>> mergedVerses = [];
          for (var verse in ch['verses']) {
            // Find corresponding Arabic verse
            final arabicVerse = arabicChapter['verses'].firstWhere(
              (arabVerse) => arabVerse['verse'] == verse['verse'],
              orElse: () => {'text': ''},
            );
            
            mergedVerses.add({
              'verse': verse['verse'],
              'text': verse['text'],
              'arabic': arabicVerse['text'],
            });
          }

          return {
            'chapter': ch['chapter'],
            'name': surahInfo['name'],
            'verses': mergedVerses,
          };
        })
      );
      
      _filteredSurahs = List.from(_surahs);
      
      if (_surahs.isNotEmpty) {
        _selectedSurahVerses = _surahs.first['verses'];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterSurahs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = _surahs;
      } else {
        String lowercaseQuery = query.toLowerCase();
        _filteredSurahs = _surahs.where((surah) {
          final number = surah['chapter'].toString();
          final name = surah['name'].toString().toLowerCase();
          return number.contains(lowercaseQuery) || 
                 name.contains(lowercaseQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quran', style: AppTextStyles.titleText),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
          : isSmallScreen
            // Mobile layout
            ? Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Surahs...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _filterSurahs,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = _filteredSurahs[index];
                        return ListTile(
                          selected: _selectedSurahVerses == surah['verses'],
                          title: Text(
                            'Surah ${surah['chapter']}: ${surah['name']}',
                            style: AppTextStyles.englishText,
                          ),
                          onTap: () {
                            setState(() => _selectedSurahVerses = surah['verses']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuranDetailScreen(
                                  surahNumber: surah['chapter'],
                                  surahName: surah['name'],
                                  verses: surah['verses'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              )
            // Desktop/tablet layout
            : Row(
                children: [
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search Surahs...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _filterSurahs,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredSurahs.length,
                            itemBuilder: (context, index) {
                              final surah = _filteredSurahs[index];
                              return ListTile(
                                selected: _selectedSurahVerses == surah['verses'],
                                title: Text(
                                  'Surah ${surah['chapter']}: ${surah['name']}',
                                  style: AppTextStyles.englishText,
                                ),
                                onTap: () => setState(() => _selectedSurahVerses = surah['verses']),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selectedSurahVerses == null 
                      ? Center(child: Text('Select a surah'))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          itemCount: _selectedSurahVerses!.length,
                          itemBuilder: (context, index) {
                            final verse = _selectedSurahVerses![index] as Map<String, dynamic>; // Cast here
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verse ${verse['verse']}',
                                    style: AppTextStyles.titleText.copyWith(
                                      fontSize: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    verse['text'],
                                    style: AppTextStyles.englishText.copyWith(
                                      height: 1.5,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    verse['arabic'],
                                    style: AppTextStyles.englishText.copyWith(
                                      height: 1.5,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}