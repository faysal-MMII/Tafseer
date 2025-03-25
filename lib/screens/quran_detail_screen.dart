import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/text_styles.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../data/first_verse_data.dart';
import 'dart:math';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';

class QuranDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final List<dynamic> verses;
  final int? initialVerse; 

  const QuranDetailScreen({
    Key? key,
    required this.surahNumber,
    required this.surahName,
    required this.verses,
    this.initialVerse, 
  }) : super(key: key);

  @override
  _QuranDetailScreenState createState() => _QuranDetailScreenState();
}

class _QuranDetailScreenState extends State<QuranDetailScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  int? highlightedVerse;
  Timer? highlightTimer;

  @override
  void initState() {
    super.initState();

    // Handle the initial verse parameter
    if (widget.initialVerse != null) {
      // Use a slightly longer delay for mobile to ensure everything is loaded
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          jumpToVerse(widget.initialVerse!);
        }
      });
    }
  }

  @override
  void dispose() {
    highlightTimer?.cancel();
    super.dispose();
  }

  void showJumpToVerseDialog() {
    final TextEditingController controller = TextEditingController();
    final int maxVerse = widget.verses.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Jump to Verse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter verse number (1-$maxVerse):'),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Verse number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final int? verseNumber = int.tryParse(controller.text);
              if (verseNumber != null && verseNumber >= 1 && verseNumber <= maxVerse) {
                Navigator.pop(context);
                jumpToVerse(verseNumber);
              }
            },
            child: Text('Go'),
          ),
        ],
      ),
    );
  }

  void jumpToVerse(int verseNumber) {
    print('QuranDetailScreen: Jumping to verse $verseNumber');

    setState(() {
      highlightedVerse = verseNumber;
    });

    _scrollToVerse(verseNumber);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to verse $verseNumber')),
    );

    highlightTimer?.cancel();
    highlightTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          highlightedVerse = null;
        });
      }
    });
  }

  void _scrollToVerse(int verseNumber) {
    if (widget.verses.isEmpty) return;

    print('QuranDetailScreen: Scrolling to verse $verseNumber');

    // Debug: Print structure of the first few verses
    for (int i = 0; i < min(5, widget.verses.length); i++) {
      final verse = widget.verses[i] as Map<String, dynamic>;
      print('Verse at index $i: verse number ${verse['verse']}');
    }

    final showBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;
    int targetPosition = -1;

    for (int i = 0; i < widget.verses.length; i++) {
      final verse = widget.verses[i] as Map<String, dynamic>;
      print('Checking verse at index $i: ${verse['verse']} == $verseNumber?');
      if (verse['verse'] == verseNumber) {
        targetPosition = i;
        print('Found verse $verseNumber at index $i');
        break;
      }
    }

    if (targetPosition >= 0) {
      int scrollToIndex = targetPosition + (showBismillah ? 1 : 0);
      print('Scrolling to index $scrollToIndex (adjusted for bismillah: $showBismillah)');

      itemScrollController.scrollTo(
        index: scrollToIndex,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      print('Verse $verseNumber not found in surah ${widget.surahNumber}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final displayedVerses = widget.verses;
    final showBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Text(
          'Surah ${widget.surahNumber}: ${widget.surahName}', 
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.cyanAccent : Color(0xFF2D5F7C)),
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_numbered, color: isDark ? Colors.cyanAccent : Color(0xFF2D5F7C)),
            tooltip: 'Jump to Verse',
            onPressed: showJumpToVerseDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ScrollablePositionedList.builder(
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
              padding: EdgeInsets.all(16),
              itemCount: displayedVerses.length + (showBismillah ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0 && showBismillah) {
                  return buildBismillahCard(isDark, Colors.cyanAccent);
                }

                final verseIndex = showBismillah ? index - 1 : index;
                final verse = displayedVerses[verseIndex] as Map<String, dynamic>;
                final verseNumber = verse['verse'] as int;

                final bool isHighlighted = highlightedVerse == verseNumber;

                String? arabicText;
                if (verseNumber == 1 && widget.surahNumber != 1 && widget.surahNumber != 9) {
                  if (firstVerseWithoutBismillah.containsKey(widget.surahNumber)) {
                    arabicText = firstVerseWithoutBismillah[widget.surahNumber];
                  } else {
                    arabicText = firstVerseWithoutBismillah[0];
                  }
                } else {
                  arabicText = verse['arabic'] as String?;
                }

                return Card(
                  elevation: isDark ? 2 : 2,
                  margin: EdgeInsets.only(bottom: 16),
                  color: isHighlighted 
                    ? (isDark ? Color(0xFF3A3000) : Colors.amber[100]) 
                    : (isDark ? Color(0xFF1E1E1E) : Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isDark 
                      ? BorderSide(color: Colors.grey[800]!, width: 1) 
                      : BorderSide.none,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Verse $verseNumber',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                indent: 10,
                                color: isDark ? Colors.grey[700] : Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (arabicText != null && arabicText.isNotEmpty)
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              arabicText,
                              style: TextStyle(
                                fontFamily: 'Scheherazade',
                                fontSize: 24,
                                height: 1.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        if (arabicText != null && arabicText.isNotEmpty) SizedBox(height: 16),
                        Text(
                          verse['text'] ?? '',
                          style: TextStyle(
                            height: 1.5,
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black87,
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

  Card buildBismillahCard(bool isDark, Color accentColor) {
    return Card(
      elevation: isDark ? 3 : 2,
      margin: EdgeInsets.only(bottom: 16),
      color: isDark ? Color(0xFF252525) : Color(0xFFF8F8F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark 
          ? BorderSide(color: Colors.grey[700]!, width: 1) 
          : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
              style: TextStyle(
                fontFamily: 'Scheherazade',
                fontSize: 28,
                height: 1.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}