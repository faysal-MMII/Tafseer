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

  // MATCHING HOME SCREEN COLORS
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);

  @override
  void initState() {
    super.initState();

    if (widget.initialVerse != null) {
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
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Jump to Verse',
          style: TextStyle(color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter verse number (1-$maxVerse):',
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: softAccent),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Verse number',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
      SnackBar(
        content: Text('Navigating to verse $verseNumber'),
        backgroundColor: primaryBlue,
      ),
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
    final displayedVerses = widget.verses;
    final showBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Surah ${widget.surahNumber}: ${widget.surahName}', 
          style: TextStyle(color: Colors.black87),
        ),
        iconTheme: IconThemeData(color: primaryBlue),
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_numbered, color: primaryBlue),
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
                  return buildBismillahCard();
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

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHighlighted 
                      ? Colors.amber[100] 
                      : cardColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
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
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Verse $verseNumber',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              indent: 10,
                              color: Colors.grey[300],
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
                              color: Colors.black87,
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
                          color: Colors.black87,
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

  Widget buildBismillahCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Bismillah',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
          SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
              style: TextStyle(
                fontFamily: 'Scheherazade',
                fontSize: 28,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'In the name of Allah, the Most Gracious, the Most Merciful',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}