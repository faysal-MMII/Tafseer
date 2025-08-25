import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/text_styles.dart';
import 'dart:convert';
import 'quran_detail_screen.dart';
import '../data/surah_data.dart';
import 'dart:math';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';

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
  final ScrollController _surahListController = ScrollController();
  List<dynamic>? _selectedSurahVerses;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> _filteredSurahs = [];
  int? _highlightedVerse;

  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);

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

          if (MediaQuery.of(context).size.width < 600) {
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              int surahIndex = _filteredSurahs.indexWhere((s) => s['chapter'] == widget.initialSurah);
              if (surahIndex >= 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_surahListController.hasClients) {
                    _surahListController.animateTo(
                      surahIndex * 56.0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              }

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
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            )
          : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
              )
            : isSmallScreen
              ? Column(
                  children: [
                    _buildHeader(
                      title: 'Quran',
                      subtitle: 'The Holy Quran',
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSearchField(),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredSurahs.length,
                        itemBuilder: (context, index) {
                          final surah = _filteredSurahs[index];
                          return _buildSurahListTile(surah);
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
                        color: cardColor.withOpacity(0.8),
                        border: Border(
                          right: BorderSide(color: softAccent.withOpacity(0.5), width: 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.0),
                            child: _buildSearchField(),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _surahListController,
                              itemCount: _filteredSurahs.length,
                              itemBuilder: (context, index) {
                                final surah = _filteredSurahs[index];
                                return _buildSurahListTile(surah);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: backgroundColor,
                        child: _selectedSurahVerses == null
                          ? Center(
                              child: Text(
                                'Select a surah',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          : ScrollablePositionedList.builder(
                              itemScrollController: itemScrollController,
                              itemPositionsListener: itemPositionsListener,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              itemCount: _selectedSurahVerses!.length,
                              itemBuilder: (context, index) {
                                final verse = _selectedSurahVerses![index] as Map<String, dynamic>;
                                final verseNumber = verse['verse'] as int;
                                final isHighlighted = _highlightedVerse == verseNumber;
                                return _buildVerseItem(verse, isHighlighted);
                              },
                            ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildHeader({required String title, required String subtitle}) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 25,
            color: primaryBlue.withOpacity(0.15),
            offset: Offset(0, 8),
          ),
          BoxShadow(
            blurRadius: 15,
            color: Colors.white.withOpacity(0.2),
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: primaryBlue,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: softAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: 'Search Surahs...',
          hintStyle: TextStyle(
            color: Colors.black54,
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(Icons.search, color: primaryBlue),
          fillColor: backgroundColor,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _filterSurahs,
      ),
    );
  }

  Widget _buildSurahListTile(Map<String, dynamic> surah) {
    final isSelected = _selectedSurahVerses == surah['verses'];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? cardColor.withOpacity(0.9) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected 
          ? Border.all(color: primaryBlue.withOpacity(0.5), width: 1)
          : null,
      ),
      child: ListTile(
        title: Text(
          'Surah ${surah['chapter']}: ${surah['name']}',
          style: TextStyle(
            color: isSelected ? primaryBlue : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Poppins',
          ),
        ),
        onTap: () {
          setState(() => _selectedSurahVerses = surah['verses']);
          
          if (MediaQuery.of(context).size.width < 600) {
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
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildVerseItem(Map<String, dynamic> verse, bool isHighlighted) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isHighlighted 
            ? Colors.amber[100] 
            : cardColor.withOpacity(0.8),
          border: Border.all(
            color: isHighlighted 
              ? Colors.amber 
              : cardColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Verse ${verse['verse']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              verse['text'],
              style: TextStyle(
                height: 1.5,
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                verse['arabic'],
                style: TextStyle(
                  fontFamily: 'Scheherazade',
                  fontSize: 20,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
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