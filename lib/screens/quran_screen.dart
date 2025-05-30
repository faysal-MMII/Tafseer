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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = isDark ? Colors.cyanAccent : Color(0xFF2D5F7C);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          'Quran', 
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: _isLoading
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          )
        : _error != null
          ? Center(
              child: Text(
                _error!, 
                style: TextStyle(color: Colors.red),
              ),
            )
          : isSmallScreen
            ? Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: _buildSearchField(isDark, accentColor),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = _filteredSurahs[index];
                        return _buildSurahListTile(surah, isDark, accentColor);
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
                      border: Border(
                        right: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: _buildSearchField(isDark, accentColor),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _surahListController,
                            itemCount: _filteredSurahs.length,
                            itemBuilder: (context, index) {
                              final surah = _filteredSurahs[index];
                              return _buildSurahListTile(surah, isDark, accentColor);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selectedSurahVerses == null
                      ? Center(
                          child: Text(
                            'Select a surah',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey[700],
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
                            return _buildVerseItem(verse, isHighlighted, isDark, accentColor);
                          },
                        ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSearchField(bool isDark, Color accentColor) {
    return TextField(
      controller: _searchController,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: 'Search Surahs...',
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: accentColor,
        ),
        fillColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
      onChanged: _filterSurahs,
    );
  }

  Widget _buildSurahListTile(Map<String, dynamic> surah, bool isDark, Color accentColor) {
    final isSelected = _selectedSurahVerses == surah['verses'];
    
    return ListTile(
      selected: isSelected,
      title: Text(
        'Surah ${surah['chapter']}: ${surah['name']}',
        style: TextStyle(
          color: isSelected 
            ? accentColor 
            : (isDark ? Colors.white : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => _selectedSurahVerses = surah['verses']);
        
        // If on mobile, navigate to detail screen
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
      tileColor: isSelected 
        ? (isDark ? Color(0xFF252525) : Color(0xFFE0F2F1)) 
        : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildVerseItem(Map<String, dynamic> verse, bool isHighlighted, bool isDark, Color accentColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isHighlighted 
            ? (isDark ? Color(0xFF3A3000) : Colors.amber[100]) 
            : (isDark ? Color(0xFF1E1E1E) : Colors.white),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.4) 
                : Colors.black.withOpacity(0.05),
              blurRadius: isDark ? 8 : 5,
              offset: Offset(0, 2),
            ),
          ],
          border: isDark 
            ? Border.all(color: Colors.grey[800]!, width: 1) 
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Verse ${verse['verse']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              verse['text'],
              style: TextStyle(
                height: 1.5,
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
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
                  color: isDark ? Colors.white : Colors.black87,
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