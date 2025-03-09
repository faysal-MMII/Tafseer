import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/text_styles.dart';
import 'dart:convert';
import 'quran_detail_screen.dart';
import '../data/surah_data.dart';
import 'dart:math';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class QuranScreen extends StatefulWidget {
  final int? initialSurah;
  final int? initialVerse;

  QuranScreen({this.initialSurah, this.initialVerse});

  @override
  _QuranScreenState createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final ScrollController _surahListController = ScrollController(); // Added ScrollController
  List<dynamic>? _selectedSurahVerses;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> _filteredSurahs = [];
  int? _highlightedVerse;

  @override
  void initState() {
    super.initState();
    _loadQuranData().then((_) {
      if (widget.initialSurah != null) {
        final targetSurah = _surahs.firstWhere(
          (surah) => surah['chapter'] == widget.initialSurah,
          orElse: () => <String, dynamic>{'chapter': 0, 'name': '', 'verses': []},
        );

        if (targetSurah.isNotEmpty && targetSurah['chapter'] != 0) {
          setState(() {
            _selectedSurahVerses = targetSurah['verses'];
          });

          // For mobile devices
          if (MediaQuery.of(context).size.width < 600) {
            // Add a small delay to ensure the UI is ready
            Future.delayed(Duration(milliseconds: 100), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuranDetailScreen(
                    surahNumber: widget.initialSurah!,
                    surahName: targetSurah['name'],
                    verses: targetSurah['verses'],
                    initialVerse: widget.initialVerse,
                  ),
                ),
              );
            });
          } else {
            // For desktop/tablets
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Scroll to the selected surah in the sidebar
              int surahIndex = _filteredSurahs.indexWhere((s) => s['chapter'] == widget.initialSurah);
              if (surahIndex >= 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_surahListController.hasClients) {
                    _surahListController.animateTo(
                      surahIndex * 56.0, // Approximate height of a ListTile
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              }

              // Scroll to the specific verse
              if (widget.initialVerse != null) {
                _scrollToVerse(widget.initialVerse!);
              }
            });
          }
        }
      }
    });
  }

  Future<void> _loadQuranData() async {
    try {
      setState(() => _isLoading = true);
      final String translationJson = await rootBundle.loadString('assets/data/translation.json');
      final translationData = json.decode(translationJson);
      final String arabicJson = await rootBundle.loadString('assets/data/quran-arabic.json');
      final arabicData = json.decode(arabicJson);

      _surahs = List<Map<String, dynamic>>.from(
        translationData['quran']['chapters'].map((ch) {
          final arabicChapter = arabicData['quran']['chapters'].firstWhere(
            (arabCh) => arabCh['chapter'] == ch['chapter'],
            orElse: () => {'verses': []},
          );
          final surahInfo = surahNames.firstWhere(
            (s) => int.parse(s['number']!) == ch['chapter'],
            orElse: () => {"number": "${ch['chapter']}", "name": "Surah ${ch['chapter']}"},
          );
          final List<Map<String, dynamic>> mergedVerses = [];
          for (var verse in ch['verses']) {
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
          return number.contains(lowercaseQuery) || name.contains(lowercaseQuery);
        }).toList();
      }
    });
  }

  void _scrollToVerse(int verseNumber) {
    if (_selectedSurahVerses == null) return;

    int verseIndex = -1;
    for (int i = 0; i < _selectedSurahVerses!.length; i++) {
      final verse = _selectedSurahVerses![i] as Map<String, dynamic>;
      final currentVerseNumber = verse['verse'];
      if (currentVerseNumber == verseNumber) {
        verseIndex = i;
        break;
      }
    }

    if (verseIndex >= 0) {
      itemScrollController.scrollTo(
        index: verseIndex,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );

      setState(() {
        _highlightedVerse = verseNumber;
      });

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedVerse = null;
          });
        }
      });
    }
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
                                  controller: _surahListController, // Attach the controller here
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
                              : ScrollablePositionedList.builder(
                                  itemScrollController: itemScrollController,
                                  itemPositionsListener: itemPositionsListener,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  itemCount: _selectedSurahVerses!.length,
                                  itemBuilder: (context, index) {
                                    final verse = _selectedSurahVerses![index] as Map<String, dynamic>;
                                    final verseNumber = verse['verse'] as int;
                                    final isHighlighted = _highlightedVerse == verseNumber;
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: isHighlighted ? Colors.amber[100] : null,
                                        ),
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
    _surahListController.dispose(); 
    super.dispose();
  }
}